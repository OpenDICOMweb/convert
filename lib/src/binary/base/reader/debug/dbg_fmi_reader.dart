// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:dataset/dataset.dart';
import 'package:system/core.dart';

import 'package:dcm_convert/src/binary/base/reader/read_buffer.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/errors.dart';

bool readFmi(ReadBuffer rb, RootDataset rds, [DecodingParameters dParams, ParseInfo
pInfo]) {
  if (!_readPrefix(rb, pInfo)) {
  	rb.index =  0;
	  return false;
  }
	  while (rb.isReadable) {
		  final code = rb.peekCode;
		  if (code >= 0x00030000) break;
		  rds.fmi.add(_readEvrElement());
	  }

	  if (!rb.hasRemaining(dParams.shortFileThreshold - rb.rIndex)) {
		  throw new EndOfDataError(
				  '_readFmi', 'index: ${rb.rIndex} bdLength: ${rb.lengthInBytes}');
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
bool _readPrefix(ReadBuffer rb, ParseInfo pInfo) {
  if (rb.rIndex != 0) return false;
  rb + 128;
  return _isDcmPrefixPresent(rb, pInfo);
}

/// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
/// Returns true if a valid Preamble and Prefix where read.
bool readPrefixPInfo(ReadBuffer rb, ParseInfo pInfo) {
  final sb = new StringBuffer();
  if (rb.rIndex != 0) sb.writeln('Attempt to read DICOM Prefix at ByteData[$rb.rIndex]');
  if (pInfo.hadPrefix != null)
    sb.writeln('Attempt to re-read DICOM Preamble and Prefix.');
  if (rb.lengthInBytes <= 132) sb.writeln('ByteData length(${rb.lengthInBytes}) < 132');
  if (sb.isNotEmpty) {
    rb.error(sb.toString());
    return false;
  }

  pInfo.preambleAllZeros = true;
  for (var i = 0; i < 128; i++)
    if (rb.getUint8(i) != 0) {
      pInfo..preambleAllZeros = false
      ..preamble = rb.uint8View(0, 128);
    }
  return _isDcmPrefixPresent(rb, pInfo);
}

/// Read as 32-bit integer. This is faster
bool _isDcmPrefixPresent(ReadBuffer rb, ParseInfo pInfo) {
  rb + 128;
  final prefix = rb.uint32;
  log.debug3('${rb.rmm} prefix: ${prefix.toRadixString(16).padLeft(8, '0')}');
  if (prefix == kDcmPrefix) {
    pInfo.hadPrefix = true;
    return true;
  } else {
    pInfo.hadPrefix = false;
    rb.warn('No DICOM Prefix present @${rb.rrr}');
    return false;
  }
}

/// Read as ASCII String
bool _isAsciiPrefixPresent(ReadBuffer rb) {
  final chars = rb.readUint8View(4);
  final prefix = ASCII.decode(chars);
  if (prefix == 'DICM') {
    return true;
  } else {
    rb.warn('No DICOM Prefix present @${rb.rrr}');
    return false;
  }
}
