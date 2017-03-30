// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:common/logger.dart';
import 'package:convertX/convert.dart';
import 'package:core/core.dart';
import 'package:dictionary/tag.dart';

/// Logger
Logger log = new Logger("read_write_element");

/// Simple [Element] test
void main(List<String> args) {
  testPrivateGroupLength();
  testPrivateIllegal();
  testPrivateCreator();
  testPrivateData();
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
  Element e2 = rBuf.readElement();
  int rIndex = rBuf.readIndex;
  if (wIndex != rIndex || e0 != e1) {
    log.warn('Unequal: $e0, $e1');
    return false;
  }
  return true;
}

bool testPrivateGroupLength() {
  // Create Element
  Tag glTag = new PrivateTag.groupLength(0x00090000);
  Element e0 = new UL(glTag, [99999]);
  //TODO: create Dataset DS0 and write E0
  //      create writer
  RootDataset ds0 = new RootDataset(DSSource.kUnknown);
  //TODO: which call to make
  DcmWriter wBuf0 = new DcmWriter(128);
  RootDataset rds0 = new RootDataset(DSSource.kUnknown);
  wBuf0.writeExplicitVRElement(e0);
  int wIndex0 = wBuf0.writeIndex;

  // Read the Dataset from the bytes.
  //TODO: create Dataset DS1
  DcmReader rBuf = new DcmReader.fromList(wBuf0.bytes);
  Element e1 = rBuf.readExplicitVRElement();
  int rIndex = rBuf.readIndex;
  if (wIndex0 != rIndex || e0 != e1) {
    log.warn('Unequal: $e0, $e1');
    return false;
  }
  bool v = compareDatasets(ds0, ds1);
  //TODO: create Dataset DS2 and write E1
  DcmWriter wBuf1 = new DcmWriter(128);
  wBuf1.writeElement(e0);
  int wIndex1 = wBuf1.writeIndex;

  return true;
}

bool testPrivateIllegal(){

}
bool testPrivateCreator(){}
bool testPrivateData(){}
