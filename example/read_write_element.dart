// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:common/logger.dart';
import 'package:core/core.dart';
import 'package:dictionary/tag.dart';

import 'package:convertX/dicom.dart';

/// Logger
Logger log = new Logger("read_write_element");

/// Simple [Element] test
void main(List<String> args) {
  SH sh = new SH(PTag.kReceivingApplicationEntityTitle, ["foo bar"]);
  elementTest(sh, ["abc", "def"]);
}

/// Test
bool elementTest(TElement e0, List values) {

  TElement e1 = e0.copy;
  log.debug('e0: ${e0.info}, e1: ${e1.info}');
  TElement e2 = e0.update(values);
  log.debug('e1: ${e0.info}, e2: ${e1.info}');
  if (e0 != e1) return false;
  if (e1 != e2) return false;

  // Write the element
  DcmWriter wBuf = new DcmWriter(lengthInBytes: 128);
  wBuf.xWritePublicElement(e1);
  int wIndex = wBuf.writeIndex;

  // Read the element
  DcmReader reader = new DcmReader.fromBytes(wBuf.bytes);
  TElement e3 = reader.xReadElement(isExplicitVR: true);
  int rIndex = reader.readIndex;
  log.debug('wIndex: $wIndex, rIndex: $rIndex');
  if (wIndex != rIndex) return false;

  log.debug('e0: $e3, e3: $e3');
  if (e0 != e3) return false;
  return true;
}
