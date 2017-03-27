// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:common/logger.dart';
import 'package:core/core.dart';
import 'package:dictionary/tag.dart';

import '../lib/encoder.dart';

/// Logger
Logger log = new Logger("read_write_element");

/// Simple [Element] test
void main(List<String> args) {
  AE ae = new AE(Tag.kReceivingApplicationEntityTitle, ["foo bar"]);
  elementTest(ae, ["abc", "def"]);
}

/// Test
bool elementTest(Element e0, List values) {
  DcmWriter wBuf = new DcmWriter(128);
  Element e1 = e0.update(values);
  wBuf.writeElement(e1);
  int wIndex = wBuf.writeIndex;
  DcmReader rBuf = new DcmReader.fromList(wBuf.bytes);
  //Element e2 = rBuf.readElement();
  int rIndex = rBuf.readIndex;
  if (wIndex != rIndex || e0 != e1) {
    log.warn('Unequal: $e0, $e1');
    return false;
  }
  return true;
}
