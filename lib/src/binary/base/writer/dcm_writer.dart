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
library odw.sdk.convert.binary.base.writer;

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/element.dart';
import 'package:system/core.dart';
import 'package:tag/vr.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/writer/writer_interface.dart';
import 'package:dcm_convert/src/binary/base/writer/byte_writer.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

part 'package:dcm_convert/src/binary/base/writer/write_evr.dart';
part 'package:dcm_convert/src/binary/base/writer/write_ivr.dart';
part 'package:dcm_convert/src/binary/base/writer/write_fmi.dart';
part 'package:dcm_convert/src/binary/base/writer/write_common.dart';
part 'package:dcm_convert/src/binary/base/writer/write_utils.dart';
part 'package:dcm_convert/src/binary/base/writer/write_vf.dart';

// The write buffer
ByteWriter _wb;

// The RootDataset
RootDataset _rds;

// The current dataset.  This changes as Sequences are written.
Dataset _cds;

EncodingParameters _eParams;

TransferSyntax _ts;
bool _isEvr;

ParseInfo _pInfo;
int _elementCount = 0;
final bool _statisticsEnabled = true;
final bool _elementOffsetsEnabled = true;
ElementOffsets _inputOffsets;
ElementOffsets _outputOffsets;

//final List<String> _exceptions = <String>[];

/// A library for encoding [Dataset]s in the DICOM File Format.
///
/// Supports encoding all LITTLE ENDIAN [TransferSyntax]es.
/// Does not support BIG ENDIAN which is retired.
///
/// _Notes_:
///   1. In all cases DcmWriter writes the Value Fields as they
///   are in the data; thus, all Value Fields should have an even length.
///   2. All String manipulation should be handled in the attribute itself.
// There are four [Element]s that might have an Undefined Length value
// (0xFFFFFFFF), [SQ], [OB], [OW], [UN].
abstract class DcmWriter extends DcmWriterInterface {
  @override
  final RootDataset rds;

  /// The target output [path] for the encoded data. [file] has
  /// precedence over [path].
  final String path;

  // TODO: Remove file?
  /// The target output [file] for the encoded data. [file] has
  /// precedence over [path].
  final File file;

  /// The [TransferSyntax] for the encoded output. If null
  /// the output will have the same [TransferSyntax] as the Root
  /// [Dataset]. If the [TransferSyntax] of the Root [Dataset] is
  /// null then it defaults to [Explicit VR Little Endian].
  final TransferSyntax targetTS;

  final bool reUseBuffer;

  final EncodingParameters eParams;

  final bool elementOffsetsEnabled;
  @override
  final ElementOffsets inputOffsets;
  @override
  final ElementOffsets outputOffsets;

  @override
  final ByteWriter wb;

  /// Creates a new [DcmWriter], where [wIndex] = 0.
  DcmWriter(this.rds,
      {this.path,
      this.file,
      TransferSyntax outputTS,
      int length,
      this.reUseBuffer = true,
      this.eParams = EncodingParameters.kNoChange,
      this.elementOffsetsEnabled = false,
      this.inputOffsets})
      : targetTS = getOutputTS(rds, outputTS),
        outputOffsets = (elementOffsetsEnabled) ? new ElementOffsets() : null,
        wb = (reUseBuffer)
            ? _reuseByteListWriter(length)
            : new ByteWriter((length == null) ? defaultBufferLength : length) {
    _cds = rds;
    _eParams = eParams;
    _wb = wb;
    _rds = rds;
    _isEvr = rds.isEvr;
    _pInfo = new ParseInfo(rds);
    if (elementOffsetsEnabled) {
//	    _elementOffsetsEnabled = elementOffsetsEnabled;
	    _inputOffsets = inputOffsets;
	    _outputOffsets = outputOffsets;
    }
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

  @override
  Dataset get cds => _cds;

  /// Returns a [Uint8List] view of the [ByteData] buffer at the current time
  Uint8List get asUint8List => wb.uint8View(0, wb.wIndex);

  /// Return's the current position of the write index ([wIndex]).
  int get wIndex => wb.wIndex;

  /// The root Dataset being encoded.
  //  RootDataset get rds;

  TransferSyntax get ts => rds.transferSyntax;

  /// The current dataset.  This changes as Sequences and Items are encoded.
  //  Dataset cds;

  /// The current [length] in bytes of this [DcmWriter].
  int get lengthInBytes => wb.wIndex;

  /// The current [length] in bytes of this [DcmWriter].
  int get length => lengthInBytes;

  bool get removeUndefinedLengths => eParams.doConvertUndefinedLengths;

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${_cds.info}';

  /// Writes (encodes) only the FMI in the root [Dataset] in 'application/dicom'
  /// media type, writes it to a Uint8List, and returns the [Uint8List].
  @override
  Uint8List writeFmi() {
    _writeFmi(rds, eParams);
    final bytes = wb.close();
    _writeFile(bytes, file);
    return bytes;
  }

  void writeElement(Element e, {bool isEVR = true}) =>
      (isEVR) ? _writeEvrElement(e) : _writeIvrElement(e);

  /// Writes (encodes) the root [Dataset] in 'application/dicom' media type,
  /// writes it to a Uint8List, and returns the [Uint8List].
  @override
  Uint8List write() {
    //TODO: handle doSeparateBulkdata
    _rds = rds;
    _cds = rds;
    _elementCount = 0;

    _ts = (targetTS == null) ? rds.transferSyntax : targetTS;
    if (_ts == null) throw 'no TS';
    _writePrefix(rds, _eParams.doCleanPreamble);
    log.debug('*** Preamble written');

    // Set the Element reader based on the Transfer Syntax.
    _isEvr = rds.isEvr;
    if (_isEvr) {
      _writeEvrRootDataset(rds, eParams);
    } else {
      _writeIvrRootDataset(rds, eParams);
    }

    if (wb == null) throw 'Invalid bytes error: $wb';
    final bytes = wb.close();
    if (file != null) _writeFile(bytes, file);
    return bytes;
  }

  /// Writes a [Dataset] to the buffer.
  void writeDataset(Dataset ds, EncodingParameters eParams) {
    if (_isEvr) {
      rds.elements.forEach(_writeEvrElement);
    } else {
      rds.elements.forEach(_writeIvrElement);
    }
  }

  /// Testing interface
  void xWriteElement(Element e, {bool isEvr = true}) =>
      (isEvr) ? _writeEvrElement(e) : _writeIvrElement(e);

  /// The default [ByteData] buffer length, if none is provided.
  static const int defaultBufferLength = k1MB; //200 * k1MB;

  /// If [_reuse] is true the [ByteData] buffer is stored here.
  static ByteWriter _reuse;

  static ByteWriter _reuseByteListWriter([int size]) {
    size ??= defaultBufferLength;
    if (_reuse == null) return _reuse = new ByteWriter(size);

    if (size > _reuse.lengthInBytes) {
      _reuse = new ByteWriter(size + 1024);
      log.warn('**** DcmWriter creating new Reuse BD of Size: ${_reuse
				  .lengthInBytes}');
    }
    _reuse.reset;
    return _reuse;
  }
}
// **** Private methods

void _writeValueField(Element e) {
  final bytes = e.vfBytes;
  _wb.bytes(bytes);
  if (bytes.length.isOdd) {
	  log.warn('**** Odd length: ${bytes.length}');
    if (e.padChar.isNegative) return invalidVFLength(e.vfBytes.length, -1);
    _wb.uint8(e.padChar);
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
