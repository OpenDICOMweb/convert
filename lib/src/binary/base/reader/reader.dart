// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
library odw.sdk.convert.binary;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';
import 'package:uid/uid.dart';

import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dcm_convert/src/binary/base/reader/reader_interface.dart';

part 'package:dcm_convert/src/binary/base/reader/read_evr.dart';
part 'package:dcm_convert/src/binary/base/reader/read_fmi.dart';
part 'package:dcm_convert/src/binary/base/reader/reader_info.dart';
part 'package:dcm_convert/src/binary/base/reader/read_ivr.dart';
part 'package:dcm_convert/src/binary/base/reader/read_pixels.dart';
part 'package:dcm_convert/src/binary/base/reader/read_root.dart';
part 'package:dcm_convert/src/binary/base/reader/read_sequence.dart';
part 'package:dcm_convert/src/binary/base/reader/read_utils.dart';

//TODO: redoc to reflect current state of code

typedef Element ElementMaker(EBytes eb, int vrIndex);
typedef PixelData PixelDataMaker(EBytes eb, int vrIndex,
    [TransferSyntax ts, VFFragments fragments]);
typedef SQ SequenceMaker(EBytes eb, Dataset _currentDS, List<Item> items);
typedef Item ItemMaker(Dataset _currentDS);

/// The current read index.
var _rIndex = 0;

bool _hasRemaining(int n) => (_rIndex + n) <= _rootBD.lengthInBytes;
bool _isReadable() => _rIndex < _rootBD.lengthInBytes;

Element readElement({bool isEVR = true}) =>
    (isEVR) ? _readEvrElement() : _readIvrElement();

Function _readElement;

ElementMaker elementMaker;
PixelDataMaker pixelDataMaker;
SequenceMaker sequenceMaker;
ItemMaker itemMaker;
ByteData _rootBD;
RootDataset _rootDS;
Dataset _currentDS;
String _path;
bool _isEVR;
bool _wasShortFile;
ElementList _elements;
DecodingParameters _dParams;
ElementOffsets _offsets;
var _bytesUnread = 0;

/// A [Converter] for [Uint8List]s containing a [Dataset] encoded in the
/// application/dicom media type.
///
/// _Notes_:
/// 1. Reads and returns the Value Fields as they are in the data.
///  For example DcmReader does not trim whitespace from strings.
///  This is so they can be written out byte for byte as they were
///  read. and a byte-wise comparator will find them to be equal.
/// 2. All String manipulation should be handled by the containing
///  [Element] itself.
/// 3. All VFReaders allow the Value Field to be empty.  In which case they
///   return the empty [List] [].
abstract class DcmReader extends DcmReaderInterface {
  /// The source of the [Uint8List] being read.
  final String path;

  /// The [ByteData] being read.
  @override
  final ByteData rootBD;
  @override
  final RootDataset rootDS;
  final bool async;
  final bool fast;
  final bool fmiOnly;
  final bool wasShortFile;

  /// If true the [ByteData] buffer ([rootBD] will be reused.
  final bool reUseBD;
  final DecodingParameters dParams;
  @override
  Dataset currentDS;

  /// Creates a new [DcmReader]  where [_rIndex] = writeIndex = 0.
  DcmReader(this.rootBD, this.rootDS,
      {this.path = '',
      this.async = true,
      this.fast: true,
      this.fmiOnly = false,
      this.reUseBD = true,
      this.dParams = DecodingParameters.kNoChange})
      : currentDS = rootDS,
			  wasShortFile = rootBD.lengthInBytes < shortFileThreshold {
    _wasShortFile = wasShortFile;
    //  log.debug('ByteData length: ${rootBD.lengthInBytes}');
    if (wasShortFile) {
      final s = 'Short file error: length(${rootBD.lengthInBytes}) $path';
      _warn('$s $_rrr');
      if (throwOnError) throw new ShortFileError('Length($rootBD.lengthInBytes) $path');
    }
    _dParams = dParams;
    _rootBD = rootBD;
    _rootDS = rootDS;
    _currentDS = rootDS;
    _path = path;
    _hadPrefix = null;
    if (elementOffsetsEnabled) _offsets = new ElementOffsets();
  }

  bool get isEVR => _isEVR;

  bool get isReadable => _isReadable();

  Uint8List get buffer =>
      rootBD.buffer.asUint8List(rootBD.offsetInBytes, rootBD.lengthInBytes);

  Uint8List get rootBytes =>
      rootBD.buffer.asUint8List(rootBD.offsetInBytes, rootBD.lengthInBytes);

  @override
  ElementOffsets get offsets => _offsets;

  String get info => '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${currentDS.info}';

  bool hasRemaining(int n) => _hasRemaining(n);

  RootDataset readRoot() => _readRootDataset(path, dParams);

  bool dcmReadFMI({bool checkPreamble = true, bool allowMissingPrefix = false}) {
    currentDS = rootDS;
    return _readFmi(path, dParams);
  }

  ParseInfo getParseInfo() => _getParseInfo();

  @override
  String toString() => '$runtimeType: rootDS: $rootDS, currentDS: $currentDS';
}

String failedTSErrorMsg(String path, Error x) => '''
Failed to read FMI: "$path"\nException: $x\n $_rrr
    File length: ${_rootBD.lengthInBytes}\n$ree readFMI catch: $x
''';

String failedFMIErrorMsg(String path, Object x) => '''
Failed to read FMI: "$path"\nException: $x\n'
	  File length: ${_rootBD.lengthInBytes}\n$ree readFMI catch: $x');
''';
