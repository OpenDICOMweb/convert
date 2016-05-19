// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

//import 'dart:io';
import 'dart:typed_data';

import 'package:attribute/attribute.dart';
import 'package:io/io.dart';
import 'package:convert/reader.dart';

//import 'sop_data.dart';

const String tdir = "C:/mint_test_data/CR";

String t1dir = "D:/M2sata/mint_test_data/sfd/cr";

String f1 = "D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255.393386351.1568457295.17895.5.dcm";
String f2 = "D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255.393386351.1568457295.48879.7.dcm";

void main() {

  var files = [f1, f2];

  Uint8List data = readBytesSync(f1);
  print('f1: len= ${data.length}');

  ByteArray buf = new ByteArray(data);
  Uint8List prefix = readPrefix(buf);

  readFileMetaInfo(buf);

}

Uint8List readPrefix(ByteArray buf) {
  Uint8List prefix = buf.readUint8List(128);
  print('"$prefix"');
  String dicm = buf.readString(4);
  print('DICM=$dicm');
  if (dicm != "DICM") {
    throw "parseDicom: DICM prefix not found at location 132";
  }
  return prefix;
}

readFileMetaInfo(ByteArray buf) {
  // Read the tag and verify
  int tag = buf.readTag();
  print('Tag: ${tagToHex(tag)}');
  if (tag != 0x00020000) {
    buf.seek(-4);
    return null;
  }

  // Read the VR which must be UL
  VR vr = VR.readVR(buf);
  print('VR: ${vrToString(vr)}');
  if (vr != kUL) {
    buf.seek(-6);
    return null;
  }

  int vfLen = vr.readVFLength(buf);
  print('vfLen: $vfLen');
  int fmiLength = buf.readUint32();
  print('FMI Length: $fmiLength');

  ByteArray fmiBuf = new ByteArray.fromBytes(0, fmiLength);

  Map<int, Attribute> fmi = {};
  fmi[tag] = new UL(tag, vr, value);

  while (fmi.isNotEmpty) {
    tag = fmi.readTag();
    vr = fmi.readVR();
    length = fmi.readVFLength();
    value = vr.read(fmi)
    fmi[tag] = new Attribute(tag, vr, value);
  }

  group = buf.readUint16();
  element = buf.readUint16();
  print('Tag: $group, $element');
  vr = buf.readUint16();
  print('VR: ${vrToString(vr)}');
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