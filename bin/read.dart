// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

//import 'dart:io';
import 'dart:io';
import 'dart:typed_data';

import 'package:odwsdk/attribute.dart';
import 'package:convert/src/dcm_bytebuf/dcm_bytebuf.dart';



//import 'sop_data.dart';

const String tdir = "C:/mint_test_data/CR";

String t1dir = "D:/M2sata/mint_test_data/sfd/cr";

String f1 = "D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255.393386351.1568457295.17895.5.dcm";
String f2 = "D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255.393386351.1568457295.48879.7.dcm";

void main() {
  var files = [f1, f2];

  Uint8List data = readBytesSync(f1);
  print('f1: len= ${data.length}');

  DcmByteBuf buf = new DcmByteBuf.fromUint8List(data);
  Uint8List prefix = readPrefix(buf);

  var fmi = readFileMetaInfo(buf);
}

Uint8List readPrefix(DcmByteBuf buf) {
  Uint8List prefix = buf.readUint8List(128);
  print('"$prefix"');
  String dicm = buf.readString(4);
  print('DICM=$dicm');
  if (dicm != "DICM") {
    throw "parseDicom: DICM prefix not found at location 132";
  }
  return prefix;
}

readFileMetaInfo(DcmByteBuf buf) {
  // Read the tag and verify
  int tag = buf.readTag();
  print('Tag: ${tagToHex(tag)}');
  if (tag != 0x00020000) {
    buf.skip(-4);
    return null;
  }

  // Read the VR which must be UL
  int vr = buf.readVR();
  print('VR: ${VR.vrToString(vr)}');
  if (vr != VR.kUL) {
    buf.seek(-6);
    return null;
  }

  int vfLen = buf.readShortLength();
  print('vfLen: $vfLen');
  int fmiLength = buf.readUint32();
  print('FMI Length: $fmiLength');

  DcmByteBuf fmiBuf = buf.readSlice(0, fmiLength);

  Map<int, Attribute> fmi = {};
  fmi[tag] = new UL(tag, value);

  while (fmiBuf.isReaderEmpty) {
    tag = fmiBuf.readTag();
    vr = fmiBuf.readVR();
    fmi[tag] = buf.readAttribute(tag);

  }

  int group = buf.readUint16();
  int element = buf.readUint16();
  print('Tag: $group, $element');
  vr = buf.readUint16();
  print('VR: ${VR.vrToString(vr)}');
  if (vfLength(vr) == 2) {
    vfLen = buf.readUint16();
    print('vfLen: $vfLen');
  } else {
    buf.seek(2);
    vfLen = buf.readUint32();
    print('vfLen: $vfLen');
  }
  Uint8List value = buf.readUint8List(vfLen);
  print('value: $value');

}