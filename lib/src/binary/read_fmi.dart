// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary;

//TODO: redoc to reflect current state of code

/// The DICOM Prefix 'DICM' as an integer.
const int kDcmPrefix = 0x44494349;

/// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
/// if any [Fmi] [Element]s were present; otherwise, returns null.
bool _readFmi(String path, DecodingParameters param) {
  final eStart = _rIndex;
  _isEVR = true;
  assert(_currentDS == _rootDS);
  //  log.debug('$rbb readFmi($currentDS)', -1);
  assert(_hadPrefix == null);
  try {
    _hadPrefix = _readPrefix(path, param.checkPreambleAllZeros);
    if (!_hadPrefix && !param.allowMissingPrefix) {
      _rootDS = null;
      return false;
    }
    //  log.debug1('$rmm readFMI: prefix($_hadPrefix) $rootDS');

    while (_isReadable()) {
      final code = _peekTagCode();
      if (code == 0) _zeroEncountered(code);
      if (code >= 0x00030000) break;
      _readEvrElement();
    }
    _hadFmi = true;

    if (!_hadFmi && !param.allowMissingFMI) return false;
    if (!system.isSupportedTransferSyntax(_tsUid.asString)) {
      _hadParsingErrors = true;
      _error('$ree Unsupported TS: $_tsUid @end');
      if (throwOnError) throw new InvalidTransferSyntax();
      return false;
    }

    //TODO: better error msg
    if (!_isReadable()) return false;
  } on InvalidTransferSyntax catch (x) {
    _hadParsingErrors = true;
    _warn(failedTSErrorMsg(path, x));
    _rIndex = 0;
    //  log.debug('$ree readFMI Invalid TS catch: $x', -1);
    return false;
  } catch (x) {
    _hadParsingErrors = true;
    _error(failedFMIErrorMsg(path, x));
    _rIndex = eStart;
    //  log.debug('$ree readFMI Catch: $x', -1);
    return false;
  }

  if (param.targetTS != null && _tsUid != param.targetTS) return false;

  _tsUid = _rootDS.transferSyntax;
  _isEVR = !_tsUid.isImplicitLittleEndian;
  return true;
}

/// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
/// Returns [true] if a valid Preamble and Prefix where read.
bool _readPrefix(String path, bool checkPreamble) {
  // try {
  final sb = new StringBuffer();
  if (_rIndex != 0) sb.writeln('Attempt to read DICOM Prefix at ByteData[$_rIndex]');
  if (_hadPrefix != null) sb.writeln('Attempt to re-read DICOM Preamble and Prefix.');
  if (_rootBD.lengthInBytes <= 132)
    sb.writeln('ByteData length(${_rootBD.lengthInBytes}) < 132');
  if (sb.isNotEmpty) {
    _error(sb.toString());
    return false;
  }
  if (checkPreamble) {
    _preambleWasZeros = true;
    _preamble = _rootBD.buffer.asUint8List(0, 128);
    for (var i = 0; i < 128; i++) if (_rootBD.getUint8(i) != 0) _preambleWasZeros = false;
  }
  return isDcmPrefixPresent();
/*  } catch (e) {
    _error('Error reading prefix @$_rrr: $e\n  of path: $path');
    return false;
  }*/
}

/// Read as 32-bit integer. This is faster
bool isDcmPrefixPresent() {
  final prefix = _rootBD.getUint32(128);
  if (prefix == kDcmPrefix) {
    _rIndex = 132;
    return true;
  } else {
    _warn('No DICOM Prefix present @$_rrr');
    _rIndex = 0;
    return false;
  }
}

/// Read as ASCII String
bool isAsciiPrefixPresent() {
  final chars = _rootBD.buffer.asUint8List(128, 4);
  _rIndex += 4;
  final prefix = ASCII.decode(chars);
  if (prefix == 'DICM') {
    _rIndex = 132;
    return true;
  } else {
    _warn('No DICOM Prefix present @$_rrr');
    _rIndex = 0;
    return false;
  }
}

String failedTSErrorMsg(String path, Exception x) => '''
Failed to read FMI: "$path"\nException: $x\n $_rrr
    File length: ${_rootBD.lengthInBytes}\n$ree readFMI catch: $x
''';

String failedFMIErrorMsg(String path, Error x) => '''
Failed to read FMI: "$path"\nException: $x\n'
	  File length: ${_rootBD.lengthInBytes}\n$ree readFMI catch: $x');
''';
