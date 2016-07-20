// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:logger/server.dart';

import 'package:odwsdk/dataset_sop.dart';
import 'package:convert/src/dcm/dcm_decoder.dart';

import 'package:convert/dcm.dart';

const String tdir = "C:/mint_test_data/CR";

String t1dir = "D:/M2sata/mint_test_data/sfd/cr";

String crf1 = "D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255"
    ".393386351.1568457295.17895.5.dcm";
String crf2 = "D:/M2sata/mint_test_data/sfd/CR/PID_MINT10/1_DICOM_Original/CR.2.16.840.1.114255"
    ".393386351.1568457295.48879.7.dcm";

String patient3CardiacCT =
    'D:/M2sata/mint_test_data/sfd/CT/Patient_3_Cardiac_CTA/1_DICOM_Original';



void main() {
  Logger log = ServerLogger.init(name: "convert/bin/read");
  log.config('Program convert/bin/read: starting');

  List<String> files = [crf1, crf2];

  Study study;

  for (String s in files) {
    File file = new File(s);
    //Uint8List data = file.readAsBytesSync();
    //log.info('${file1.path}(len=${data.length}):');

    //DcmReader buf = new DcmReader.fromUint8List(data);

    DcmDecoder reader = new DcmDecoder.fromFile(file);

    var instance = reader.readSopInstance();
    study = instance.study;

    Format fmt = new Format();
    fmt.study(study);
    print('Study: $study');
    //print('Series: ${study.series}');
    //print('Instances: ${study.instances}');
    //study.display();

  }
}


//TODO: Flush
/*
Map<int, Attribute> readFileMetaInfo(DcmBuf buf) {
  final Logger log = new Logger("Fmi", Level.info);
  // Read the File prefix: skip 128 bytes then read magic = "DICM"
  Prefix prefix = Prefix.readPrefix(buf);
  log.debug('Prefix: $prefix');
  if (prefix == null) return null;

  Map<int, Attribute> fmi = {};

  // Read the tag and verify. If the first [tag] is not an [FMi] [tag],
  // unread the [tag] and return [null].
  int tag = buf.peekTag();
  log.finest('First Tag: ${tagToHex(tag)}');
  if (tag != 0x00020000) {
    log.warning("Invalid FMI Tag: ${toHexString(tag, 8)}");
    // Unread everything read to this point
    buf.setReadIndex(0);
    return null;
  }


  // Read the FMI Group Length
  var fmiLength;
  Attribute a = buf.readAttribute();
  if ((a.tag != kFileMetaInformationGroupLength) || (a.vr != VR.kUL)) {
    log.finest('VR(${a.vr}): ${intToHex(a.vr.code)}');
    buf.unreadBytes(6);
    return null;
  } else {
    // The Group Length for FMI
    fmiLength = buf.readIndex + a.values[0];
    log.info('Group Length: $fmiLength');
    log.info('$a');
    fmi[a.tag] = a;
  }
  */
  // Read the rest of [Fmi].
  /*
  while (buf.readIndex < fmiLength) {
    int tag = buf.peekTag();
    log.finest('peekTag: ${intToHex(tag, 8)}');
    if (tagGroup(tag) == 0x0002) {
      Attribute a = buf.readAttribute();
      log.info('$a');
      fmi[tag] = a;
    }
  }
  return fmi;
}
*/
/*
Map readDataset(DcmBuf buf) {
  final Logger log = new Logger("DS", Level.debug);
  Map<int, Attribute> aMap = {};


  while (buf.isReadable) {
      Attribute a = buf.readAttribute();
      aMap[a.tag] = a;
      if (a.tag == kPixelData) {
        log.info('PixelData: ${fmtTag(a.tag)}, ${a.vr}, length= ${a.values.length}');
      } else {
        log.info('$a');
      }
    }
  log.info('ByteBuf: $buf');
  return aMap;
}
*/