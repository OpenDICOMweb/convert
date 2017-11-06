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
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/binary/base/writer/writer_interface.dart';
import 'package:dcm_convert/src/binary/base/writer/byte_writer.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

part 'package:dcm_convert/src/binary/base/writer/write_evr.dart';
part 'package:dcm_convert/src/binary/base/writer/write_ivr.dart';
part 'package:dcm_convert/src/binary/base/writer/write_fmi.dart';
part 'package:dcm_convert/src/binary/base/writer/write_utils.dart';
part 'package:dcm_convert/src/binary/base/writer/write_vf.dart';

/*
String _path;
bool _isEVR;
bool _wasShortFile;

RootDataset _rootDS;
Dataset _currentDS;
ElementList _elements;
var _bytesUnread = 0;

/// The current read index.
var _rIndex = 0;
*/

/*
ByteData _bl;
RootDataset _rootDS;
Dataset _currentDS;

bool _isEVR;

*/
String _path;
ByteWriter _wb;
RootDataset _rootDS;

/// The current dataset.  This changes as Sequences are written.
Dataset _currentDS;
EncodingParameters _eParams;
bool _keepUndefinedLengths;

ElementOffsets _offsets;
Function _writeElement;

bool _isEVR;
TransferSyntax _ts;

int _nElements = 0;
int _nSequences = 0;
int _nPrivateElements = 0;
int _nPrivateSequences = 0;

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
  /// The target output [path] for the encoded data. [file] has
  /// precedence over [path].
  final String path;

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

  @override
  final ElementOffsets offsets = new ElementOffsets();

  @override
  final ByteWriter wb;

  /// Return true if input is Explicit VR, false if Implicit VR.

  //TODO: these should be reported in an EncodeData structure (like ParseData)

  /// Creates a new [DcmWriter], where [wIndex] = 0.
  DcmWriter(RootDataset rootDS,
      {this.path,
      this.file,
      TransferSyntax outputTS,
      int length = ByteWriter.kDefaultLength,
      this.reUseBuffer = true,
      this.eParams = EncodingParameters.kNoChange})
      : targetTS = getOutputTS(rootDS, outputTS),
        wb = (reUseBuffer)
            ? _reuseByteListWriter(length)
            : new ByteWriter((length == null) ? defaultBufferLength : length) {
    _currentDS = rootDS;
    _eParams = eParams;
    _wb = wb;
    _rootDS = rootDS;
    _path = path;
    _isEVR = rootDS.isEVR;
    //if (elementOffsetsEnabled) _offsets = new ElementOffsets();
    _offsets = new ElementOffsets();
    _keepUndefinedLengths = !_eParams.doConvertUndefinedLengths;
  }

  /// Returns the [targetTS] for the encoded output.
  static TransferSyntax getOutputTS(RootDataset rootDS, TransferSyntax outputTS) {
    if (outputTS == null) {
      return (rootDS.transferSyntax == null)
          ? system.defaultTransferSyntax
          : rootDS.transferSyntax;
    } else {
      return outputTS;
    }
  }

  @override
  Dataset get currentDS => _currentDS;

  /// Returns a [Uint8List] view of the [ByteData] buffer at the current time
  Uint8List get asUint8List => wb.uint8View(0, wb.wIndex);

  /// Return's the current position of the write index ([wIndex]).
  int get wIndex => wb.wIndex;

  /// The root Dataset being encoded.
  //  RootDataset get rootDS;

  TransferSyntax get ts => rootDS.transferSyntax;

  /// The current dataset.  This changes as Sequences and Items are encoded.
  //  Dataset currentDS;

  /// The current [length] in bytes of this [DcmWriter].
  int get lengthInBytes => wb.wIndex;

  /// The current [length] in bytes of this [DcmWriter].
  int get length => lengthInBytes;

  bool get removeUndefinedLengths => eParams.doConvertUndefinedLengths;

  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  /// Writes (encodes) only the FMI in the root [Dataset] in 'application/dicom'
  /// media type, writes it to a Uint8List, and returns the [Uint8List].
  Uint8List writeFmi(RootDataset rootDS, EncodingParameters eParams,
                     {bool cleanPreamble = true}) {
	  _writeFmi(rootDS, eParams, cleanPreamble);
	  final bytes = wb.close();
	  _writeFile(bytes, file);
	  return bytes;
  }

  /// Writes (encodes) the root [Dataset] in 'application/dicom' media type,
  /// writes it to a Uint8List, and returns the [Uint8List].
  Uint8List writeRootDS(RootDataset rootDS, {bool cleanPreamble = true}) {
    //TODO: handle doSeparateBulkdata
    _currentDS = rootDS;
    _ts = (targetTS == null) ? rootDS.transferSyntax : targetTS;
    if (_ts == null) throw 'no TS';
    _writeFmi(rootDS, eParams, cleanPreamble);

    // Set the Element reader based on the Transfer Syntax.
    _isEVR = rootDS.isEVR;
    _writeElement = (_isEVR) ? _writeEvr : _writeIvr;
    _writeDataset(rootDS);

    if (wb == null || wb.length < ByteWriter.kMinByteListLength)
      throw 'Invalid bytes error: $wb';
    final bytes = wb.close();
    _writeFile(bytes, file);
    return bytes;
  }

  void writeElement(Element e, {bool isEVR = true}) =>
      (_isEVR) ? _writeEvr(e) : _writeIvr(e);

  /// Writes a [Dataset] to the buffer.
  void writeDataset(Dataset ds) => _writeDataset(ds);

  /// Testing interface
  void xWriteElement(Element e) => _writeElement(e);

  /// The default [ByteData] buffer length, if none is provided.
  static const int defaultBufferLength = 200 * k1MB;

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
	  return _reuse;
  }
}
// **** Private methods

void _writeDataset(Dataset ds) {
  assert(ds != null);
  final previousDS = _currentDS;
  _currentDS = ds;

  _isEVR = true;
  for (var e in ds.elements) {
    //Urgent Jim: figure out how to move this outside loop.
    //  should fmi be a separate map in the rootDS?
    if (e.code > 0x30000) _isEVR = _rootDS.isEVR;
    _writeElement(e);
  }
  _currentDS = previousDS;
}

void _writeValueField(Element e) {
  final bytes = e.vfBytes;
  _wb.bytes(bytes);
  if (bytes.length.isOdd) {
    if (e.padChar.isNegative) return invalidVFLength(e.vfBytes.length, -1);
    _wb.uint8(e.padChar);
  }
}

//TODO: make this work for [async] == true and make that the default.
/// Writes [bd] to [file] if it is not null or empty.
void _writeFileSync(ByteData bd, File file) {
  final bytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
  file.writeAsBytesSync(bytes);
}

void _writePathSync(ByteData bd, String path) {
  assert(path != null && path.isNotEmpty);
  if (path.isNotEmpty) _writeFileSync(bd, new File(path));
}

