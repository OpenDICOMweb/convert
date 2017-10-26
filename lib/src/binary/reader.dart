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

import 'package:dcm_convert/src/binary/element_offsets.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/errors.dart';
import 'package:dcm_convert/src/reader_interface.dart';

part 'package:dcm_convert/src/binary/read_evr.dart';
part 'package:dcm_convert/src/binary/read_fmi.dart';
part 'package:dcm_convert/src/binary/reader_info.dart';
part 'package:dcm_convert/src/binary/read_ivr.dart';
part 'package:dcm_convert/src/binary/read_pixels.dart';
part 'package:dcm_convert/src/binary/read_root.dart';
part 'package:dcm_convert/src/binary/read_sequence.dart';
part 'package:dcm_convert/src/binary/read_utils.dart';

//TODO: redoc to reflect current state of code

String _path;
ByteData _rootBD;
bool _isEVR;
bool _wasShortFile;

RootDataset _rootDS;
Dataset _currentDS;
ElementList _elements;
var _bytesUnread = 0;

DecodingParameters _decode;
ElementOffsets _offsets;

/// The current read index.
var _rIndex = 0;

bool _hasRemaining(int n) => (_rIndex + n) <= _rootBD.lengthInBytes;
bool _isReadable() => _rIndex < _rootBD.lengthInBytes;

Function _readElement;

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
  final bool async;
  final bool fast;
  final bool fmiOnly;
  final bool _wasShortFile;

  /// If [true] the [ByteData] buffer ([rootBD] will be reused.
  final bool reUseBD;

  final DecodingParameters dParams;

  /// Creates a new [DcmReader]  where [_rIndex] = writeIndex = 0.
  DcmReader(this.rootBD,
      {this.path = '',
      this.async = true,
      this.fast: true,
      this.fmiOnly = false,
      this.reUseBD = true,
      this.dParams = DecodingParameters.kNoChange})
      : _wasShortFile = rootBD.lengthInBytes < shortFileThreshold {
    //  log.debug('ByteData length: ${rootBD.lengthInBytes}');
    if (_wasShortFile) {
      final s = 'Short file error: length(${rootBD.lengthInBytes}) $path';
      _warn('$s $_rrr');
      if (throwOnError) throw new ShortFileError('Length($rootBD.lengthInBytes) $path');
    }
    _rootBD = rootBD;
    _decode = dParams;
    if (elementOffsetsEnabled) _offsets = new ElementOffsets();
  }

  bool get isEVR => _isEVR;

  bool get isReadable => _isReadable();

  bool hasRemaining(int n) => _hasRemaining(n);

  Uint8List get buffer =>
      rootBD.buffer.asUint8List(rootBD.offsetInBytes, rootBD.lengthInBytes);

  Uint8List get rootBytes =>
      rootBD.buffer.asUint8List(rootBD.offsetInBytes, rootBD.lengthInBytes);

  String get info => '$runtimeType: rootDS: ${rootDS.info}, currentDS: ${currentDS.info}';

  RootDataset readRoot() =>
      _readRootDataset(path, dParams);

  bool dcmReadFMI({bool checkPreamble = true, bool allowMissingPrefix = false}) {
    _currentDS = rootDS;
    return _readFmi(path, dParams);
  }

  ParseInfo getParseInfo() => _getParseInfo();

  @override
  String toString() => '$runtimeType: rootDS: $rootDS, currentDS: $currentDS';
}
