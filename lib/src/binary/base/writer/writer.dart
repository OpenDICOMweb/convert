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
import 'package:dcm_convert/src/binary/base/writer/byte_list_writer.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/encoding_parameters.dart';

//TODO: rewrite all comments to reflect current state of code
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
ByteListWriter _blw;
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


  final bool reUseBLWriter;

  final EncodingParameters eParams;

  @override
  final ElementOffsets offsets = new ElementOffsets();

  @override
  final ByteListWriter blw;

  /// Return true if input is Explicit VR, false if Implicit VR.

  //TODO: these should be reported in an EncodeData structure (like ParseData)


  /// Creates a new [DcmWriter], where [wIndex] = 0.
  DcmWriter(Dataset rootDS,
      {this.path,
      this.file,
      TransferSyntax outputTS,
      int length = ByteListWriter.kDefaultLength,
      this.reUseBLWriter = true,
      this.eParams = EncodingParameters.kNoChange})
      : targetTS = getOutputTS(rootDS, outputTS),
        blw = (reUseBLWriter)
            ? _reuseByteListWriter(length)
            : new ByteListWriter((length == null) ? defaultBufferLength : length) {
    _currentDS = rootDS;
    _eParams = eParams;
    _blw = blw;
    _rootDS = rootDS;
    _path = path;
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
  Uint8List get asUint8List => blw.asUint8ListView;

  /// Return's the current position of the write index ([wIndex]).
  int get wIndex => blw.wIndex;

  /// The root Dataset being encoded.
  //  RootDataset get rootDS;

  TransferSyntax get ts => rootDS.transferSyntax;

  /// The current dataset.  This changes as Sequences and Items are encoded.
  //  Dataset currentDS;

  /// The current [length] in bytes of this [DcmWriter].
  int get lengthInBytes => blw.wIndex;

  /// The current [length] in bytes of this [DcmWriter].
  int get length => lengthInBytes;

  bool get removeUndefinedLengths => eParams.doConvertUndefinedLengths;

  String get info =>
      '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${_currentDS.info}';

  /// Writes (encodes) the root [Dataset] in 'application/dicom' media type,
  /// writes it to a Uint8List, and returns the [Uint8List].
  Uint8List writeRootDS() {
    //TODO: handle doSeparateBulkdata
    _currentDS = rootDS;
    _ts = (targetTS == null) ? rootDS.transferSyntax : targetTS;
    if (_ts == null) throw 'no TS';
    //TODO: figure out the correct way to writeFMI
    // _writeFMI();
    _writeExistingPrefix();

    // Set the Element reader based on the Transfer Syntax.
    _writeElement = (_isEVR) ? _writeEvr : _writeIvr;


    _isEVR = rootDS.isEVR;
    _writeDataset(rootDS);

    if (blw == null || blw.length < ByteListWriter.kMinByteListLength)
    	throw 'Invalid bytes error: $blw';
    _writeFile(blw.asUint8ListView, file);
    return blw.asUint8ListView;
  }

  void writeElement(Element e, {bool isEVR = true}) =>
		  (_isEVR) ? _writeEvr(e) : _writeIvr(e);

  //TODO: make this work for [async] == true and make that the default.
  /// Writes [bd] to [file] if it is not null; otherwise, writes to
  /// [path] if it is not null. If both are null nothing is written.
  void _writeFileSync(ByteData bd, File f) {
    if (f.existsSync()) {
      final bytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
      f.writeAsBytesSync(bytes);
    } else {
      return pathDoesNotExist(file.path);
    }
  }

  void _writePathSync(ByteData bd, String path) {
    path ??= '';
    if (path.isNotEmpty) _writeFileSync(bd, new File(path));
  }

  /// Writes a [Dataset] to the buffer.
  void writeDataset(Dataset ds) => _writeDataset(ds);

  /// Testing interface
  void xWriteElement(Element e) => _writeElement(e);


  // **** Private methods

  void _writeDataset(Dataset ds) {
    assert(ds != null);
    final previousDS = _currentDS;
    _currentDS = ds;

    _isEVR = true;
    for (var e in ds.elements) {
      //Urgent Jim: figure out how to move this outside loop.
      //  should fmi be a separate map in the rootDS?
      if (e.code > 0x30000) _isEVR = rootDS.isEVR;
      _writeElement(e);
    }
    _currentDS = previousDS;
  }

  void _writeValueField(Element e) {
  	final bytes = e.vfBytes;
  	_blw.uint8List(bytes);
  	if (bytes.length.isOdd) {
  		if (e.padChar.isNegative)
  			return invalidValueFieldLength(e);
  		_blw.writeUint8(e.padChar);
	  }
  }








  /// The default [ByteData] buffer length, if none is provided.
  static const int defaultBufferLength = 200 * k1MB;

  /// If [reUseBLWriter] is true the [ByteData] buffer is stored here.
  static ByteListWriter _reuse;

  static ByteListWriter _reuseByteListWriter([int size]) {
	  size ??= defaultBufferLength;
	  if (_reuse == null) return _reuse = new ByteListWriter(size);
	  if (size > _reuse.lengthInBytes) {
		  _reuse = new ByteListWriter(size + 1024);
		  log.warn('**** DcmWriter creating new Reuse BD of Size: ${_reuse
				  .lengthInBytes}');
	  }
	  return _reuse;
  }
}
