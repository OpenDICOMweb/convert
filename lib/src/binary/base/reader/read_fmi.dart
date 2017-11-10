// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

/// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
/// if any [Fmi] [Element]s were present; otherwise, returns null.
bool _readFmi(RootDataset rds, String path, DecodingParameters dParams) {
  try {
    log.debug('${_rb.rbb} readFmi($_cds)');
    assert(_cds == rds);
 //   assert(_pInfo.hadPrefix == null, 'hadPrefix was non-null');
    _pInfo.hadPrefix = _readPrefix(path, dParams.checkPreambleAllZeros);
    if (!_pInfo.hadPrefix && !dParams.allowMissingPrefix) {
      return false;
    }
    //  log.debug1('$rmm readFMI: prefix($_hadPrefix) $rds');

    while (_rb.isReadable) {
      final code = _rb.peekCode;
      if (code >= 0x00030000) break;
      _readEvrElement();
    }

    _isEvr = rds.isEvr;
    _pInfo.hadFmi = _rds.hasFmi;

    if (!_rb.hasRemaining(shortFileThreshold - _rb.rIndex)) {
      _pInfo.hadParsingErrors = true;
      throw new EndOfDataError(
          '_readFmi', 'index: ${_rb.rIndex} bdLength: ${_rb.lengthInBytes}');
    }

    final ts = rds.transferSyntax;
    _pInfo.ts = ts;
    log.info('TS: $ts');
    if (!system.isSupportedTransferSyntax(ts.asString)) {
      _pInfo.hadParsingErrors = true;
      invalidTransferSyntax(ts);
      return false;
    }

    if (dParams.targetTS != null && ts != dParams.targetTS)
      invalidTransferSyntax(ts, dParams.targetTS);
  } on ShortFileError catch (e) {
    _pInfo.exceptions.add(e);
    _pInfo.hadParsingErrors = true;
    _rb.error(failedFMIErrorMsg(path, e));
    if (throwOnError) rethrow;
  } on EndOfDataError catch (e) {
    _pInfo.exceptions.add(e);
    _pInfo.hadParsingErrors = true;
    log.error(e);
    if (throwOnError) rethrow;
  } on InvalidTransferSyntax catch (e) {
    _rb.warn(failedTSErrorMsg(path, e));
    return false;
  } on RangeError catch (e) {
    _pInfo.exceptions.add(e);
    _rb.error('$e\n $_pInfo.stats');
    if (_beyondPixelData) log.info0('${_rb.rrr} Beyond Pixel Data');
    // Keep: *** Keep, but only use for debugging.
    if (throwOnError) rethrow;
  } catch (e) {
    _pInfo.exceptions.add(e);
    // _rb.set(eStart);
    _pInfo.hadParsingErrors = true;
    _rb.error(failedFMIErrorMsg(path, e));
    rethrow;
  }
  log.debug('${_rb.ree} readFMI ${rds.total} Elements read');
  return true;
}

/// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
/// Returns true if a valid Preamble and Prefix where read.
bool _readPrefix(String path, bool checkPreamble) {
  // try {
  final sb = new StringBuffer();
  if (_rb.rIndex != 0)
    sb.writeln('Attempt to read DICOM Prefix at ByteData[$_rb.rIndex]');
  if (_pInfo.hadPrefix != null)
    sb.writeln('Attempt to re-read DICOM Preamble and '
        'Prefix.');
  if (_rb.lengthInBytes < 132) sb.writeln('ByteData length(${_rb.lengthInBytes}) < 132');
  if (sb.isNotEmpty) {
    _rb.error(sb.toString());
    return false;
  }
  if (checkPreamble) {
    _pInfo.preambleWasZeros = true;
    _pInfo.preamble = _rb.uint8View(0, 128);
    for (var i = 0; i < 128; i++)
      if (_rb.getUint8(i) != 0) _pInfo.preambleWasZeros = false;
  }
  return isDcmPrefixPresent();
}

/// Read as 32-bit integer. This is faster
bool isDcmPrefixPresent() {
  _rb + 128;
  final prefix = _rb.uint32;
  log.debug3('${_rb.rmm} prefix: ${prefix.toRadixString(16).padLeft(8, '0')}');
  if (prefix == kDcmPrefix) {
    return true;
  } else {
    _rb.warn('No DICOM Prefix present @${_rb.rrr}');
    return false;
  }
}

/// Read as ASCII String
bool isAsciiPrefixPresent() {
  final chars = _rb.readUint8View(4);
  final prefix = ASCII.decode(chars);
  if (prefix == 'DICM') {
    return true;
  } else {
    _rb.warn('No DICOM Prefix present @${_rb.rrr}');
    return false;
  }
}
