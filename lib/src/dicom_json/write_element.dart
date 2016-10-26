// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';
String _out;

String add(String s) => _out += s;

String addSlice(String s, [int offset= 0, int length]) {
  length = ((length == null) || (length > s.length)) ? s.length : length;
  return _out += s.substring(offset, length);
}

String basicListToString(List<String> values) {
  _out += '[';
  for(int i = 0; i < values.length; i++) {
    if (i != values.length - 1) {
      _out += '"s",';
    } else {
      _out += '"s"';
    }
  }
  return _out += "]";
}

String toDcmString(List<String> v) => _out += '"${v.join('\\')}"';


String toBase64(Uint8List values) => _out += '"${BASE64.encode(values)}"';

String toNumber(num value) => '${value.toString()}';

toList(List v) => '[ ${v.join(",")}';





typedef String VFWriter(Element e);


  /// writes the next [Element] in the [ByteBuf]
void _addValue(Element a) {
    // Element writers
    Map<int, VFWriter> vfWriter = {
      0x4145: writeAE,
      0x4153: writeAS,
      0x4154: writeAT,
      // 0x4252: writeBR,
      0x4353: writeCS,
      0x4441: writeDA,
      0x4453: writeDS,
      0x4454: writeDT,
      0x4644: writeFD,
      0x464c: writeFL,
      0x4953: writeIS,
      0x4c4f: writeLO,
      0x4c54: writeLT,
      0x4f42: writeOB,
      0x4f44: writeOD,
      0x4f46: writeOF,
      0x4f57: writeOW,
      0x504e: writePN,
      0x5348: writeSH,
      0x534c: writeSL,
      0x5351: writeSQ,
      0x5353: writeSS,
      0x5354: writeST,
      0x544d: writeTM,
      0x5543: writeUC,
      0x5549: writeUI,
      0x554c: writeUL,
      0x554e: writeUN,
      0x5552: writeUR,
      0x5553: writeUS,
      0x5554: writeUT
    };
    if (isNotWritable) {
      var msg = "Write Buffer empty: readIndex($readIndex), writeIndex($writeIndex)";
      log.error(msg);
      throw msg;
    }

    //print('_writeInteral: $a');
    writeTag(a.tag);
    int vrCode = a.vr.code;
    writeVR(vrCode);
    log.debug('write: $a');
    VFWriter writer = vfWriter[vrCode];

    var values = a.values;
    bool shouldPrint = true;
    if (shouldPrint) {
      print('writer: ${writer.runtimeType}, '
                'tag: ${toHexString(a.tag, 8)}, '
                'vrCode: ${toHexString(vrCode, 4)}, '
                'VR: ${a.vr}, '
                'values: $values. '
            // 'length: ${values.length}, '
                'writeIndex: $writeIndex');
      print('values: ${a.values}');
    }
    if (writer == null) {
      var msg = "Invalid vrCode(${toHexString(vrCode, 4)})";
      log.error(msg);
      throw msg;
    }
    writer(a);
  }



  //**** VR writers ****

  void writeAE(AE e) {
    assert(e.vr == VR.kAE);
    List<String> v = e.v.join('\\');
     add('[ $);
  }

  void writeAS(AS a) {
    assert(a.vr == VR.kAS);
    writeShortDcmString(a);
  }

  void writeAT(AT a) {
    assert(a.vr == VR.kAT);
    writeDcmUint32List(a.values);
  }

  void writeBR(BR a) {
    assert(a.vr == VR.kBR);
    throw "Unimplemented";
  }

  void writeCS(CS a) {
    assert(a.vr == VR.kCS);
    writeShortDcmString(a);
  }

  void writeDA(DA a) {
    writeShortDcmString(a);
  }

  void writeDS(DS a) {
    assert(a.vr == VR.kDS);
    writeShortDcmString(a);
  }

  void writeDT(DT a) {
    assert(a.vr == VR.kDT);
    writeShortDcmString(a);
  }

  void writeFD(FD a) {
    assert(a.vr == VR.kFD);
    writeDcmFloat64List(a.values, isShort: true);
  }

  void writeFL(FL a) {
    assert(a.vr == VR.kFD);
    writeDcmFloat32List(a.values, isShort: true);
  }

  void writeIS(IS a) {
    assert(a.vr == VR.kIS);
    writeShortDcmString(a);
  }

  void writeLO(LO a) {
    assert(a.vr == VR.kLO);
    writeShortDcmString(a);
  }

  void writeLT(LT a) {
    assert(a.vr == VR.kLT);
    writeShortDcmString(a);
  }

  //TODO: need transfer syntax to do this correctly
  void writeOB(OB a) {
    assert(a.vr == VR.kOB);
    if (a.hadUndefinedLength) {
      writeLongLength(kUndefinedLength);
      writeUint8List(a.values);
      writeUint32(kSequenceDelimitationItem);
    }
    writeDcmUint8List(a.values, isShort: false);
  }

  void writeOD(OD a) {
    assert(a.vr == VR.kOD);
    writeDcmFloat64List(a.values, isShort: false);
  }

  void writeOF(OF a) {
    assert(a.vr == VR.kOF);
    writeDcmFloat32List(a.values, isShort: false);
  }

  //TODO: need transfer syntax to do this correctly
  void writeOL(OL a) {
    assert(a.vr == VR.kOL);
    writeDcmUint32List(a.values, isShort: false);
  }

  // depends on Transfer Syntax
  //TODO: need transfer syntax to do this correctly
  void writeOW(OW a) {
    assert(a.vr == VR.kOW);
    writeDcmUint16List(a.values, isShort: false);
  }

  void writePN(PN a) {
    assert(a.vr == VR.kPN);
    writeShortDcmString(a);
  }

  void writeSH(SH a) {
    assert(a.vr == VR.kSH);
    writeShortDcmString(a);
  }

  void writeSL(SL a) {
    assert(a.vr == VR.kSL);
    writeDcmInt32List(a.values, isShort: true);
  }

  void writeSQ(SQ sq) {
    assert(sq.vr == VR.kSQ);
    writeSequence(sq);
  }

  void writeSS(SS a) {
    assert(a.vr == VR.kSS);
    writeDcmInt16List(a.values, isShort: true);
  }

  void writeST(ST a) {
    assert(a.vr == VR.kST);
    writeShortDcmString(a);
  }

  void writeTM(TM a) {
    assert(a.vr == VR.kTM);
    writeShortDcmString(a);
  }

  void writeUC(UC a) {
    assert(a.vr == VR.kUC);
    writeLongDcmString(a);
  }

  //TODO: move to encode Dcm/ constants
  static const String uidPaddingChar = "\x00";

  void writeUI(UI a) {
    assert(a.vr == VR.kUI);
    writeShortDcmString(a, padChar: uidPaddingChar);
  }

  void writeUL(UL a) {
    assert(a.vr == VR.kUL);
    print('UL: ${a.values}');
    writeDcmUint32List(a.values);
  }

  void writeUN(UN a) {
    assert(a.vr == VR.kUN);
    writeDcmUint8List(a.values, isShort: false);
  }

  void writeUR(UR a) {
    assert(a.vr == VR.kUR);
    writeLongDcmString(a);
  }

  void writeUS(US a) {
    assert(a.vr == VR.kUS);
    writeDcmUint8List(a.values, isShort: true);
  }

  /// Unlimited Text (UT) Value Representation
  void writeUT(UT a) {
    assert(a.vr == VR.kUT);
    writeLongDcmString(a);
  }

