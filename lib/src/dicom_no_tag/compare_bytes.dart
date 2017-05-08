// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/ascii.dart';
import 'package:dictionary/dictionary.dart';

import 'dataset.dart';
import 'element.dart';
import 'utils.dart';

/// TODO
bool bytesEqual(Uint8List b0, Uint8List b1, [bool throwOnError = true]) {
  if (b0.lengthInBytes != b1.lengthInBytes) return false;
  for (int i = 0; i < b0.length; i++) {
    if (b0[i] != b1[i]) {
      if (throwOnError) {
        showBytes(b0, b1, i);
        throw "non-matching bytes at indexL $i";
      } else {
        return false;
      }
    }
  }
  return true;
}

void showBytes(Uint8List b0, Uint8List b1, int offset) {
  int pos = offset % 4;
  int line = (offset ~/ 4) * 4;
  int startLine = line - 12;
  int endLine = line + 96;
  print('Non-matching bytes at offset: $offset');
  print('O     B0           B1        B0   B1       B0          B1');
//print('(gggg,eeee)  (gggg,eeee)  abcf abcd  0123456789  0123456789');

  for (int i = startLine; i < line - 1; i += 4) {
    printLine(i, b0, b1);
  }
  printLine(line, b0, b1, pos);
  for (int i = line + 1; i < endLine; i += 4) {
    printLine(i, b0, b1);
  }
}

void printLine(int line, Uint8List b0, Uint8List b1, [int pos]) {
  ByteData bd0 = b0.buffer.asByteData();
  ByteData bd1 = b1.buffer.asByteData();

  var v0 = bd0.getUint32(line);
  var v1 = bd1.getUint32(line);
  var dcm0 = toDcm(v0);
  var dcm1 = toDcm(v1);
  var dec0 = toDec32(v0);
  var dec1 = toDec32(v1);
  var s0 = toStr(b0, line);
  var s1 = toStr(b1, line);
  if (pos != null) {
    print('$pos: $dcm0  $dcm1  "$s0"  "$s1"  $dec0 $dec1');
  } else {
    print('   $dcm0  $dcm1  "$s0"  "$s1"  $dec0 $dec1');
  }
}

String toStr(Uint8List bytes, int index) {
  var line = bytes.buffer.asUint8List(index, 4);
  for (int i = 0; i < 4; i++) {
    if (!isVisibleChar(line[i])) line[i] = kAsterisk;
  }
  return new String.fromCharCodes(line);
}

bool compareDatasets(Dataset ds0, Dataset ds1, [bool throwOnError = false]) {
  for (Element e0 in ds0.elements) {
    Element e1 = ds1[e0.code];
    if (e0.vrCode == VR.kSQ.code) {
      if (e1.vrCode != VR.kSQ.code) return false;
      if (!compareSequences(e0, e1)) return false;
    } else {
      if (e0.code != e1.code ||
          e0.vrCode != e1.vrCode ||
          e0.vfLength != e1.vfLength ||
          e0.vf.length != e1.vfLength) {
        if (throwOnError) {
          throw 'ds0 != ds1';
        } else {
          return false;
        }
      }
      for (int i = 0; i < e0.vf.length; i++) {
        if (e0.vf[i] != e1.vf[i]) {
          if (throwOnError) {
            throw 'e0.vf[$i] != e1.vf[$i]';
          } else {
            return false;
          }
        }
      }
    }
  }
  return true;
}


bool compareSequences(SQ s0, SQ s1) {
  if (s0.code != s1.code ||
      s0.vrCode != s1.vrCode ||
      s0.items.length != s1.items.length) return false;
  for (int i = 0; i < s0.items.length; i++) {
    var item0 = s0[i];
    var item1 = s1[i];
    if (!compareDatasets(item0, item1)) return false;
  }
  return true;
}
