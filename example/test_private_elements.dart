// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:convertX/convert.dart';
import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

/// Logger
Logger log = new Logger("read_write_element", watermark: Severity.debug);

/// Simple [Element] test
void main(List<String> args) {
  testPublicElement();
  /*
  testPrivateGroupLength();
  testPrivateIllegal();
  testPrivateCreator();
  testPrivateData();
//AE ae = new AE(PTag.kReceivingApplicationEntityTitle, ["foo bar"]);
//elementTest(ae, ["abc", "def"]);
*/
}

bool writeReadElementTest<E>(Element<E> e0, [PrivateCreator pc]) {
  log.debug('writeReadElement: ${e0.info}');
  // Create Dataset DS0 and write E0
  DcmWriter wBuf0 = new DcmWriter(512);
  wBuf0.writeElement(e0);
  int wIndex0 = wBuf0.writeIndex;
  log.debug('wIndex0($wIndex0)');

  // Now read the Dataset from the bytes.
  Uint8List bytes = wBuf0.bytes;
  log.debug('bytes: (${bytes.length})$bytes');
  DcmReader rBuf0 = new DcmReader.fromList(wBuf0.bytes);
  log.debug('rBuf0: $rBuf0');

  int rIndex0;
  Element pc0;
  Element e1;
  if (e0.tag.isPublic) {
    e1 = rBuf0.readElement();
    log.debug('e1: ${e1.info}');
    rIndex0 = rBuf0.readIndex;
  } else if (e0.tag.isCreator) {
    pc0 = rBuf0.xReadPrivateCreator();
    log.debug('e1: ${pc0.info}');
    rIndex0 = rBuf0.readIndex;
  } else if (e0.tag.isPrivateData) {
    e1 = rBuf0.xReadPrivateData(pc0);
    log.debug('e1: ${e1.info}');
    rIndex0 = rBuf0.readIndex;
  }

  // Now Compare the buffer index and the elements
  if (wIndex0 != rIndex0) {
    log.warn('Unequal: wIndex: $wIndex0, rIndex: $rIndex0');
    return false;
  }
  if (e0 != e1) {
    log.warn('Unequal: $e0, $e1');
    return false;
  }

  DcmWriter wBuf1 = new DcmWriter(128);
  wBuf1.writeElement(e1);
  int wIndex1 = wBuf1.writeIndex;

  // Now read the Dataset from the bytes.
  DcmReader rBuf1 = new DcmReader.fromList(wBuf1.bytes);
  Element e2 = rBuf1.readElement();
  int rIndex1 = rBuf1.readIndex;

  // Now Compare the buffer index and the elements
  if (wIndex1 != rIndex1) {
    log.warn('Unequal: wIndex: $wIndex1, rIndex: $rIndex1');
    return false;
  }
  if (e1 != e2) {
    log.warn('Unequal: $e1, $e2');
    return false;
  }

  return true;
}

Element<E> writeReadDataset<E>(RootDataset ds0, Element<E> e0) {
  RootDataset ds0 = new RootDataset(DSSource.kUnknown);
  ds0.add(e0);
  DcmWriter wBuf0 = new DcmWriter(128);
  wBuf0.writeDataset(ds0);
  //TODO: create Dataset DS2 and write E1

  // Dataset rds1 = rBuf.readRootDataset()
}

/// Test Public Element
void testPublicElement() {
  Tag e0Tag = PTag.lookupCode(0x00020000, VR.kUL);
  UL e0 = new UL(e0Tag, [128]);
  log.debug('e0: ${e0.info}');
  bool v = writeReadElementTest(e0);
  log.debug('expect true: $v');

  e0Tag = PTag.lookupCode(0x00080000, VR.kUL);
  e0 = new UL(e0Tag, [128]);
  log.debug('e0: ${e0.info}');
  v = writeReadElementTest(e0);
  log.debug('expect true: $v');


}

void testPrivateGroupLengthElement() {
  Tag e0Tag = PTag.lookupCode(0x00090000, VR.kUL);
  UL e0 = new UL(e0Tag, [128]);
  log.debug('e0: ${e0.info}');
  bool v = writeReadElementTest(e0);
  log.debug('expect true: $v');


}


bool testPrivateGroupLength() {
  // Create Element
  Tag glTag = new PrivateGroupLengthTag(0x00090000, VR.kCS);
  Element e0 = new UL(glTag, [1024]);
  //TODO: create Dataset DS0 and write E0
  //      create writer
  RootDataset rds0 = new RootDataset(DSSource.kUnknown);
  rds0.add(e0);
  DcmWriter wBuf0 = new DcmWriter(128);
  wBuf0.writeElement(e0);
  // wBuf0.writeDataset(rds0);
  int wIndex = wBuf0.writeIndex;

  // Read the Dataset from the bytes.
  //TODO: create Dataset DS1
  DcmReader rBuf = new DcmReader.fromList(wBuf0.bytes);
  Element e1 = rBuf.readElement();
 // Dataset rds1 = rBuf.readRootDataset()
  int rIndex = rBuf.readIndex;
  if (wIndex != rIndex || e0 != e1) {
    log.warn('Unequal: wIndex: $wIndex, rIndex: $rIndex');
    return false;
  }
  if (e0 != e1) {
    log.warn('Unequal: $e0, $e1');
  }
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
