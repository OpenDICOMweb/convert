// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:core/core.dart';
import 'package:dictionary/tag.dart';

import 'package:dcm_convert/src/dicom_no_tag/test_dcm_byte_reader.dart';
import 'package:dcm_convert/src/dicom_no_tag/test_dcm_byte_writer.dart';

/// Logger
Logger log = new Logger("read_write_element");

/// Simple [Element] test
void main(List<String> args) {
  SH sh = new SH(PTag.kReceivingApplicationEntityTitle, ["foo bar"]);
  elementTest(sh, ["abc", "def"]);
}

/// Test
bool elementTest(Element e0, List values) {

  Element e1 = e0.copy;
  log.debug('e0: ${e0.info}, e1: ${e1.info}');
  Element e2 = e0.update(values);
  log.debug('e1: ${e0.info}, e2: ${e1.info}');
  if (e0 != e1) return false;
  if (e1 != e2) return false;

  // Write the element
  var bd = new ByteData(4096);
  TestDcmByteWriter writer = new TestDcmByteWriter(new RootByteDataset(bd));
  writer.xWritePublicElement(e1);
  int wIndex = writer.wIndex;

  // Read the element
  RootTagDataset rds1 = new RootTagDataset.empty();
  TestDcmByteReader reader = new TestDcmByteReader.fromList(writer.bytes, rds1);
  Element e3 = reader.xReadPublicElement();
  int rIndex = reader.rIndex;
  log.debug('wIndex: $wIndex, rIndex: $rIndex');
  if (wIndex != rIndex) return false;

  log.debug('e0: $e3, e3: $e3');
  if (e0 != e3) return false;
  return true;
}
