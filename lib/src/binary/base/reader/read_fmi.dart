// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

//TODO: redoc to reflect current state of code
/// The DICOM Prefix 'DICM' as an integer.
const int kDcmPrefix = 0x4449434d;

/// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
/// if any [Fmi] [Element]s were present; otherwise, returns null.
bool _readFmi(String path, DecodingParameters dParams) {
  _isEVR = true;
  assert(_currentDS == _rootDS);
  //  log.debug('$rbb readFmi($currentDS)', -1);
  assert(_hadPrefix == null);
  _hadPrefix = _readPrefix(path, dParams.checkPreambleAllZeros);
  if (!_hadPrefix && !dParams.allowMissingPrefix) {
    _rootDS = null;
    return false;
  }
  //  log.debug1('$rmm readFMI: prefix($_hadPrefix) $rootDS');

  while (_isReadable()) {
    final code = _rb.peekCode;
    if (code == 0) _zeroEncountered(code);
    if (code >= 0x00030000) break;
    _readEvrElement();
  }
  _hadFmi = true;

  if (!_hasRemaining(shortFileThreshold - _rIndex)) {
	  _hadParsingErrors = true;
	  throw new ShortFileError();
  }

  _tsUid = _rootDS.transferSyntax;
  log.info('TS: $_tsUid');
  _isEVR = !_tsUid.isImplicitLittleEndian;
  if (!system.isSupportedTransferSyntax(_tsUid.asString)) {
    _rIndex = 0;
    _hadParsingErrors = true;
    invalidTransferSyntax(_tsUid);
    return false;
  }

  if (dParams.targetTS != null && _tsUid != dParams.targetTS)
	  invalidTransferSyntax(_tsUid, dParams.targetTS);
  return true;
}

/// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
/// Returns true if a valid Preamble and Prefix where read.
bool _readPrefix(String path, bool checkPreamble) {
  // try {
  final sb = new StringBuffer();
  if (_rIndex != 0) sb.writeln('Attempt to read DICOM Prefix at ByteData[$_rIndex]');
  if (_hadPrefix != null) sb.writeln('Attempt to re-read DICOM Preamble and Prefix.');
  if (_rb.lengthInBytes <= 132)
    sb.writeln('ByteData length(${_rb.lengthInBytes}) < 132');
  if (sb.isNotEmpty) {
    _rb.error(sb.toString());
    return false;
  }
  if (checkPreamble) {
    _preambleWasZeros = true;
    _preamble = _rb.buffer.asUint8List(0, 128);
    for (var i = 0; i < 128; i++) if (_rb.getUint8(i) != 0) _preambleWasZeros = false;
  }
  return isDcmPrefixPresent();
}

/// Read as 32-bit integer. This is faster
bool isDcmPrefixPresent() {
  final prefix = _rb.getUint32(128);
  print('prefix: ${prefix.toRadixString(16).padLeft(8, '0')}');
  if (prefix == kDcmPrefix) {
    _rIndex = 132;
    return true;
  } else {
    _rb.warn('No DICOM Prefix present @${_rb.rrr}');
    _rIndex = 0;
    return false;
  }
}

/// Read as ASCII String
bool isAsciiPrefixPresent() {
  final chars = _rb.buffer.asUint8List(128, 4);
  _rIndex += 4;
  final prefix = ASCII.decode(chars);
  if (prefix == 'DICM') {
    _rIndex = 132;
    return true;
  } else {
    _rb.warn('No DICOM Prefix present @${_rb.rrr}');
    _rIndex = 0;
    return false;
  }
}
