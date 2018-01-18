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

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/byte_list/write_buffer.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';

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
abstract class DcmWriterBase<V> {
  WriteBuffer get wb;
  RootDataset get rds;
  int get minLength;
//  ByteData get fmiBD;
  EncodingParameters get eParams;
  bool get reUseBD;

  Dataset get cds;
  set cds(Dataset ds);

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

  void writeElement(Element e);

  // **** End Interface ****

  /// Writes (encodes) the root [Dataset] in 'application/dicom' media type,
  /// writes it to a Uint8List, and returns the [Uint8List].
  Uint8List writeRootDataset(RootDataset rds) {
    _writeDataset(rds);
    return wb.toUint8List(0, wb.wIndex);
  }

  void _writeDataset(Dataset ds) {
    // ignore: prefer_forEach
    for (var e in ds.elements) {
      writeElement(e);
    }
  }

  /// Write all [Item]s in [items].
  void writeItems(List<Item> items) {
    for (var item in items) {
      final parentDS = cds;
      cds = item;
      writeItem(item);
      cds = parentDS;
    }
  }

  /// Write one [Item].
  void writeItem(Item item) => ((item.hasULength && !eParams.doConvertUndefinedLengths))
      ? _writeUndefinedLengthItem(item)
      : _writeDefinedLengthItem(item);

  void writeDefinedLengthItem(Item item) => _writeDefinedLengthItem(item);
  void writeUndefinedLengthItem(Item item) => _writeUndefinedLengthItem(item);

  /// Writes a [Dataset] to the buffer.
  void _writeDefinedLengthItem(Item item) {
    wb..uint32(kItem32BitLE)..uint32(item.vfLength);
    _writeDataset(item);
  }

  void _writeUndefinedLengthItem(Item item) {
    wb..uint32(kItem32BitLE)..uint32(kUndefinedLength);
    _writeDataset(item);
    wb..uint32(kItemDelimitationItem32BitLE)..uint32(0);
  }

  void writeEncapsulatedPixelData(Element e) {
    assert(e.vfLengthField == kUndefinedLength);
    for (final fragment in e.fragments.fragments) {
      print('fragment(${fragment.lengthInBytes})');
      wb
        ..uint32(kItem32BitLE)
        ..uint32(fragment.lengthInBytes)
        ..write(fragment);
      // If odd length write padding byte
      if (fragment.length.isOdd) {
        log.warn('Odd length(${fragment.lengthInBytes}) fragment');
        wb.uint8(0);
      }
    }
    //  wb..uint32(kSequenceDelimitationItem32BitLE)..uint32(0);
    print('End of pixelData: ${wb.wIndex}');
  }

  // **** Logging Interface ****
  void logStartWrite(Element e, String name) {}

  void logEndWrite(int eStart, Element e, String name, {bool ok}) {}

  void logStartSQWrite(Element e, String name) {}

  void logEndSQWrite(int eStart, Element e, String name, {bool ok}) {}

  /// Returns the [outputTS] for the encoded output.
  static TransferSyntax getOutputTS(RootDataset rds, TransferSyntax outputTS) {
    if (outputTS == null) {
      return (rds.transferSyntax == null)
          ? system.defaultTransferSyntax
          : rds.transferSyntax;
    } else {
      return outputTS;
    }
  }
}

/// The default [ByteData] buffer length, if none is provided.
const int kDefaultWriteBufferLength = k1MB; //200 * k1MB;

/// A reusable  [WriteBuffer] is stored here.
WriteBuffer _reUseBuffer;

WriteBuffer getWriteBuffer({int length, bool reUseBD = false}) {
  length ??= kDefaultWriteBufferLength;
  if (_reUseBuffer == null) return _reUseBuffer = new WriteBuffer(length);

  if (length > _reUseBuffer.lengthInBytes) {
    _reUseBuffer = new WriteBuffer(length + 1024);
    log.warn('**** DcmWriterBase creating new Reuse BD of Size: ${_reUseBuffer
    .lengthInBytes}');
  }
  _reUseBuffer.reset;
  return _reUseBuffer;
}

/*
//TODO: make this work for [async] == true and make that the default.
/// Writes [bytes] to [file].
void writeFile(Uint8List bytes, File file) {
  if (file == null) throw new ArgumentError('$file is not a File');
  file.writeAsBytesSync(bytes.buffer.asUint8List());
//    log.debug('Wrote ${bytes.lengthInBytes} bytes to "${file.path}"');
}
*/

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
