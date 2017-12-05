// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/element.dart';
import 'package:system/core.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/writer/base/write_buffer.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

/// A library for encoding [Dataset]s in the DICOM File Format.
///
/// Supports encoding all LITTLE ENDIAN [TransferSyntax]es.
/// Does not currently support BIG ENDIAN which is retired.
///
/// _Notes_:
///   1. In all cases [DcmWriterBase] writes the Value Fields as they
///   are in the data; thus, all Value Fields should have an even length.
///   2. All String manipulation should be handled in the attribute itself.
// Note: There are four [Element]s that might have an Undefined Length value
// (0xFFFFFFFF), [SQ], [OB], [OW], [UN].
abstract class DcmWriterBase {
  final WriteBuffer wb;
  final RootDataset rds;

  /// The target output [path] for the encoded data.
  final String path;
  final int minLength;
  ByteData fmiBD;

  /// The [TransferSyntax] for the encoded output. If null
  /// the output will have the same [TransferSyntax] as the Root
  /// [Dataset]. If the [TransferSyntax] of the Root [Dataset] is
  /// null then it defaults to [Explicit VR Little Endian].
  final TransferSyntax targetTS;
  final EncodingParameters eParams;
  final bool reUseBD;
  final ParseInfo pInfo;
  final bool elementOffsetsEnabled;
  final ElementOffsets inputOffsets;
  final ElementOffsets outputOffsets;

  Dataset cds;
  int elementCount;

  /// Creates a new [DcmWriterBase], where [wIndex] = 0.
  DcmWriterBase(this.rds,
      {this.path,
      EncodingParameters eParams,
      TransferSyntax outputTS,
      this.minLength,
      this.reUseBD,
      this.elementOffsetsEnabled = true,
      this.inputOffsets})
      : eParams = eParams ?? EncodingParameters.kNoChange,
        targetTS = getOutputTS(rds, outputTS),
        outputOffsets = (elementOffsetsEnabled) ? new ElementOffsets() : null,
        pInfo = new ParseInfo(rds),
        elementCount = -1,
        cds = rds,
        wb = (reUseBD)
            ? _reuseByteListWriter(minLength)
            : new WriteBuffer((minLength == null) ? defaultBufferLength : minLength);

  bool get isEvr => rds.isEvr;

  /// Returns a [Uint8List] view of the [ByteData] buffer at the current time
  Uint8List get asUint8List => wb.uint8View(0, wb.wIndex);

  /// Return's the current position of the write index ([wIndex]).
  int get wIndex => wb.wIndex;

  /// The root Dataset being encoded.
  //  RootDataset get rds;

  TransferSyntax get ts => rds.transferSyntax;

  /// The current dataset.  This changes as Sequences and Items are encoded.
  //  Dataset cds;

  /// The current [length] in bytes of this [DcmWriterBase].
  int get lengthInBytes => wb.wIndex;

  /// The current [length] in bytes of this [DcmWriterBase].
  int get length => lengthInBytes;

  bool get removeUndefinedLengths => eParams.doConvertUndefinedLengths;

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  bool get isFmiWritten => _isFmiWritten;
  // ignore: prefer_final_fields
  bool _isFmiWritten = false;
  set isFmiWritten(bool v) => _isFmiWritten ??= true;

  // **** Interface ****

  /// Writes (encodes) the root [Dataset] in 'application/dicom' media type,
  /// writes it to a Uint8List, and returns the [Uint8List].
  Uint8List writeRootDataset(RootDataset rds);

  void writeElement(Element e);

  // **** End Interface ****

  int itemCount;
  void writeItems(List<Item> items) {
    itemCount = 0;
    log.debug('${wb.wbb} Writing ${items.length} Items', 1);
    for (var item in items) {
      final parentDS = cds;
      cds = item;

      log.debug('${wb.wbb} Writing Item: $item', 1);
      ((item.hasULength && !eParams.doConvertUndefinedLengths))
          ? _writeUndefinedLengthDataset(item, itemCount)
          : _writeDefinedLengthDataset(item, itemCount);

      cds = parentDS;
      itemCount++;
      log.debug('${wb.wee} Wrote Item: $item', -1);
    }
    log.debug('${wb.wee} Wrote $itemCount Items', -1);
  }

  void _writeUndefinedLengthDataset(Item item, int number) {
    log.debug('${wb.wbb} Writing item #$itemCount', 1);
    wb..uint32(kItem32BitLE)..uint32(kUndefinedLength);
    for (var e in item.elements) {
      log.debug('${wb.wbb} $e');
      writeElement(e);
    }
    wb..uint32(kItemDelimitationItem32BitLE)..uint32(0);
    log.debug('${wb.wee} Wrote item #$itemCount', -1);
  }

  /// Writes a [Dataset] to the buffer.
  void _writeDefinedLengthDataset(Dataset ds, int number) {
    wb..uint32(kItem32BitLE)..uint32(ds.vfLength);
    for (var e in ds.elements) {
      log.debug('${wb.wbb}  $e');
      writeElement(e);
    }
  }

//TODO: make this work for [async] == true and make that the default.
  /// Writes [bytes] to [file].
  void writeFile(Uint8List bytes, File file) {
    if (file == null) throw new ArgumentError('$file is not a File');
    file.writeAsBytesSync(bytes.buffer.asUint8List());
    log.debug('Wrote ${bytes.lengthInBytes} bytes to "${file.path}"');
  }

  void doEndOfElementStats(int start, int end, Element e) {
    pInfo.nElements++;
    pInfo
      ..lastElement = e
      ..endOfLastElement = end;
    if (e.isPrivate) pInfo.nPrivateElements++;
    if (e is SQ) {
      pInfo
        ..endOfLastSequence = end
        ..lastSequence = e;
    }

    if (e is! SQ && elementOffsetsEnabled) {
      outputOffsets.add(start, end, e);

      final iStart = inputOffsets.starts[elementCount];
      final iEnd = inputOffsets.ends[elementCount];
      final ie = inputOffsets.elements[elementCount];
      if (iStart != start || iEnd != end || ie != e) {
        log.debug('''
**** Unequal Offset at Element $elementCount
	** $iStart to $iEnd read $e
  ** $start to $end wrote $e''');
        throw 'badOffset';
      }
    }
  }

  void updatePInfoPixelData(Element e) {
    log
      ..debug('Pixel Data: ${e.info}')
      ..debug('vfLength: ${e.vfLength}')
      ..debug('vfLengthField: ${e.vfLengthField}')
      ..debug('fragments: ${e.fragments.info}');
    pInfo
      ..pixelDataVR = e.vr
      ..pixelDataStart = wb.wIndex
      ..pixelDataLength = e.vfLength
      ..pixelDataHadFragments = e.fragments != null
      ..pixelDataHadUndefinedLength = e.vfLengthField == kUndefinedLength;
  }

  void showOffsets() {
    log
      ..info(' input offset length: ${inputOffsets.length}')
      ..info('output offset length: ${outputOffsets.length}');
    for (var i = 0; i < inputOffsets.length; i++) {
      final iStart = inputOffsets.starts[i];
      final iEnd = inputOffsets.ends[i];
      final ioe = inputOffsets.elements[i];
      final oStart = outputOffsets.starts[i];
      final oEnd = outputOffsets.ends[i];
      final ooe = outputOffsets.elements[i];

      log
        ..info('iStart: $iStart iEnd: $iEnd e: $ioe')
        ..info('oStart: $oStart iEnd: $oEnd e: $ooe');
    }
  }

/*
  /// Testing interface
  void xWriteElement(Element e, {bool isEvr = true}) =>
      (isEvr) ? _writeEvrElement(e) : _writeIvrElement(e);
*/

  /// The default [ByteData] buffer length, if none is provided.
  static const int defaultBufferLength = k1MB; //200 * k1MB;

  /// If [_reuse] is true the [ByteData] buffer is stored here.
  static WriteBuffer _reuse;

  static WriteBuffer _reuseByteListWriter([int size]) {
    size ??= defaultBufferLength;
    if (_reuse == null) return _reuse = new WriteBuffer(size);

    if (size > _reuse.lengthInBytes) {
      _reuse = new WriteBuffer(size + 1024);
      log.warn('**** DcmWriterBase creating new Reuse BD of Size: ${_reuse
				  .lengthInBytes}');
    }
    _reuse.reset;
    return _reuse;
  }

  /// Returns the [targetTS] for the encoded output.
  static TransferSyntax getOutputTS(RootDataset rds, TransferSyntax outputTS) {
    if (outputTS == null) {
      return (rds.transferSyntax == null)
          ? system.defaultTransferSyntax
          : rds.transferSyntax;
    } else {
      return outputTS;
    }
  }

// **** Private methods

  void writeValueField(Element e) {
    final bytes = e.vfBytes;
    // print('bytes.length: ${bytes.lengthInBytes}');
    wb.bytes(bytes);
    if (bytes.length.isOdd) {
      log.warn('**** Odd length: ${bytes.length}');
      if (e.padChar.isNegative) return invalidVFLength(e.vfBytes.length, -1);
      wb.uint8(e.padChar);
    }
  }
}

/*
//TODO: make this work for [async] == true and make that the default.
/// Writes [bd] to [file] if it is not null or empty.
void _writeFileSync(ByteData bd, File file) {
	final bytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
	file.writeAsBytesSync(bytes);
}
*/

/*
void _writePathSync(ByteData bd, String path) {
  assert(path != null && path.isNotEmpty);
  if (path.isNotEmpty) _writeFileSync(bd, new File(path));
}
*/
