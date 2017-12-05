// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

/// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
/// if any [Fmi] [Element]s were present; otherwise, returns null.
bool _readFmi(ByteReader rb, RootDataset rds, [DecodingParameters dParams]) {
  assert(_cds == rds);

  if (!_readPrefix(rb)) {
  	rb.index =  0;
	  return false;
  }
	  while (_rb.isReadable) {
		  final code = _rb.peekCode;
		  if (code >= 0x00030000) break;
		  rds.fmi.add(_readEvrElement());
	  }

	  if (!_rb.hasRemaining(dParams.shortFileThreshold - _rb.rIndex)) {
		  throw new EndOfDataError(
				  '_readFmi', 'index: ${_rb.rIndex} bdLength: ${_rb.lengthInBytes}');
	  }

	  final ts = rds.transferSyntax;
	  if (!system.isSupportedTransferSyntax(ts.asString)) {
		  return invalidTransferSyntax(ts);
	  }
	  if (dParams.targetTS != null && ts != dParams.targetTS)
		  return invalidTransferSyntax(ts, dParams.targetTS);

	  return true;
}

/// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
/// Returns true if a valid Preamble and Prefix where read.
bool _readPrefix(ByteReader rb) {
  if (rb.rIndex != 0) return false;
  rb + 128;
  return isDcmPrefixPresent(rb);
}

/// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
/// Returns true if a valid Preamble and Prefix where read.
bool readPrefixPInfo(ByteReader rb, ParseInfo pInfo) {
  final sb = new StringBuffer();
  if (rb.rIndex != 0) sb.writeln('Attempt to read DICOM Prefix at ByteData[$rb.rIndex]');
  if (_pInfo.hadPrefix != null)
    sb.writeln('Attempt to re-read DICOM Preamble and Prefix.');
  if (rb.lengthInBytes <= 132) sb.writeln('ByteData length(${rb.lengthInBytes}) < 132');
  if (sb.isNotEmpty) {
    rb.error(sb.toString());
    return false;
  }

  _pInfo.preambleAllZeros = true;
  for (var i = 0; i < 128; i++)
    if (rb.getUint8(i) != 0) {
      _pInfo.preambleAllZeros = false;
      _pInfo.preamble = rb.uint8View(0, 128);
    }
  return isDcmPrefixPresent(rb);
}

/// Read as 32-bit integer. This is faster
bool isDcmPrefixPresent(ByteReader rb) {
  rb + 128;
  final prefix = rb.uint32;
  log.debug3('${rb.rmm} prefix: ${prefix.toRadixString(16).padLeft(8, '0')}');
  if (prefix == kDcmPrefix) {
    _pInfo.hadPrefix = true;
    return true;
  } else {
    _pInfo.hadPrefix = false;
    rb.warn('No DICOM Prefix present @${rb.rrr}');
    return false;
  }
}

/// Read as ASCII String
bool isAsciiPrefixPresent(ByteReader rb) {
  final chars = rb.readUint8View(4);
  final prefix = ASCII.decode(chars);
  if (prefix == 'DICM') {
    return true;
  } else {
    rb.warn('No DICOM Prefix present @${rb.rrr}');
    return false;
  }
}

