// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:dcm_convert/convert.dart';
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

bool writeReadElementTest<E>(TagElement<E> e0, [PrivateCreator pc]) {
  log.debug('writeReadElement: ${e0.info}');
  // Create Dataset DS0 and write E0
  RootTagDataset rds0 = new RootTagDataset.empty();
  DcmTagWriter writer0 = new DcmTagWriter(rds0);
  writer0.xWritePublicElement(e0);
  int wIndex0 = writer0.wIndex;
  log.debug('wIndex0($wIndex0)');

  // Now read the Dataset from the bytes.
  Uint8List bytes = writer0.bytes;
  log.debug('bytes: (${bytes.length})$bytes');
  DcmReader rBuf0 = new DcmReader.fromBytes(writer0.bytes);
  log.debug('rBuf0: $rBuf0');

  int rIndex0;
  TagElement pc0;
  TagElement e1;
  if (e0.tag is PTag) {
    e1 = rBuf0.xReadPublicElement();
    log.debug('PTag: ${e1.info}');
  } else if (e0.tag is PCTag) {
    pc0 = rBuf0.xReadPrivateCreator();
    log.debug('PCTag: ${pc0.info}');
  } else if (e0.tag is PDTag) {
    e1 = rBuf0.xReadPrivateData(pc0);
    log.debug('PDTag: ${e1.info}');
  } else if (e0.tag is PrivateGroupLengthTag) {
    e1 = rBuf0.xReadPrivateData(pc0);
    log.debug('PrivateGroupLengthTag: ${e1.info}');
  } else if (e0.tag is PrivateTag) {
    e1 = rBuf0.xReadPrivateData(pc0);
    log.debug('PrivateTag.illegal: ${e1.info}');
  }
  rIndex0 = rBuf0.rIndex;

  // Now Compare the buffer index and the elements
  if (wIndex0 != rIndex0) {
    log.warn('Unequal: wIndex: $wIndex0, rIndex: $rIndex0');
    return false;
  }
  if (e0 != e1) {
    log.warn('Unequal: $e0, $e1');
    return false;
  }

  DcmTagWriter wBuf1 = new DcmTagWriter(lengthInBytes: 128);
  wBuf1.xWritePublicElement(e1);
  int wIndex1 = wBuf1.writeIndex;

  // Now read the Dataset from the bytes.
  DcmReader rBuf1 = new DcmReader.fromBytes(wBuf1.bytes);
  TagElement e2 = rBuf1.xReadPublicElement();
  int rIndex1 = rBuf1.rIndex;

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

TagElement<E> writeReadDataset<E>(RootTDataset ds0, TagElement<E> e0) {
  RootTDataset ds0 = new RootTDataset();
  ds0.add(e0);
  DcmTagWriter wBuf0 = new DcmTagWriter(lengthInBytes: 128);
  wBuf0.writeDataset(ds0);
  TagElement<E> e;
  //TODO: create Dataset DS2 and write E1

  // Dataset rds1 = rBuf.readRootDataset()

  return e;
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
  Tag tag = new PrivateGroupLengthTag(0x00090000, VR.kCS);
  TagElement e0 = new UL(tag, [1024]);
  //TODO: create Dataset DS0 and write E0
  //      create writer
  RootTDataset rds0 = new RootTDataset();
  rds0.add(e0);
  DcmTagWriter wBuf0 = new DcmTagWriter(lengthInBytes: 128);
  wBuf0.xWritePublicElement(e0);
  // wBuf0.writeDataset(rds0);
  int wIndex0 = wBuf0.wIndex;

  // Read the Dataset from the bytes.
  //TODO: create Dataset DS1
  DcmReader rBuf = new DcmReader.fromBytes(wBuf0.bytes);
  TagElement e1 = rBuf.xReadPublicElement();
 // Dataset rds1 = rBuf.readRootDataset()
  int rIndex = rBuf.rIndex;
  if (wIndex0 != rIndex || e0 != e1) {
    log.warn('Unequal: wIndex: $wIndex0, rIndex: $rIndex');
    return false;
  }
  if (e0 != e1) {
    log.warn('Unequal: $e0, $e1');
  }
  //TODO: create Dataset DS2 and write E1
  DcmTagWriter wBuf1 = new DcmTagWriter(lengthInBytes: 128);

  wBuf1.xWritePublicElement(e0);
  int wIndex1 = wBuf1.wIndex;
  if (wIndex0 != wIndex1) return false;
  return true;
}

bool testPrivateIllegal(){
  bool v;

  return v;
}
bool testPrivateCreator(){
  bool v;

  return v;
}
bool testPrivateData(){
  bool v;

  return v;
}
