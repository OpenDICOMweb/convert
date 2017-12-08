// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:dataset/dataset.dart';
import 'package:element/element.dart';
import 'package:system/core.dart';

import 'package:dcm_convert/src/binary/base/reader/read_buffer.dart';
import 'package:dcm_convert/src/decoding_parameters.dart';
import 'package:dcm_convert/src/errors.dart';

/// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
/// if any [Fmi] [Element]s were present; otherwise, returns null.
bool readFmi(ReadBuffer rb, RootDataset rds, [DecodingParameters dParams]) {
  if (!_readPrefix(rb)) {
  	rb.index =  0;
	  return false;
  }
	  while (rb.isReadable) {
		  final code = rb.peekCode;
		  if (code >= 0x00030000) break;
		  rds.fmi.add(readEvrElement());
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
bool _readPrefix(ReadBuffer rb) {
  if (rb.rIndex != 0) return false;
  rb + 128;
  return isDcmPrefixPresent(rb);
}

/// Reads the Preamble (128 bytes) and Prefix ('DICM') of a PS3.10 DICOM File Format.
/// Returns true if a valid Preamble and Prefix where read.
bool readPrefixPInfo(ReadBuffer rb, ParseInfo pInfo) {
  if (rb.rIndex != 0 || rb.lengthInBytes <= 132) return false;
  rb.index = 128;
  return isDcmPrefixPresent(rb);
}

/// Read as 32-bit integer. This is faster
bool isDcmPrefixPresent(ReadBuffer rb) {
  rb + 128;
  final prefix = rb.uint32;
  if (prefix == kDcmPrefix) {
    return true;
  } else {
    rb.warn('No DICOM Prefix present @${rb.rrr}');
    return false;
  }
}

/// Read as ASCII String
bool isAsciiPrefixPresent(ReadBuffer rb) {
  final chars = rb.readUint8View(4);
  final prefix = ASCII.decode(chars);
  if (prefix == 'DICM') {
    return true;
  } else {
    rb.warn('No DICOM Prefix present @${rb.rrr}');
    return false;
  }
}
