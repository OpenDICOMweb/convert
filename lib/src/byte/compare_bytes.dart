// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:system/core.dart';
import 'package:core/core.dart';
import 'package:tag/tag.dart';

/// TODO DOC
bool bytesEqual1(Uint8List b0, Uint8List b1, [bool throwOnError = false]) {
  if (b0.lengthInBytes != b1.lengthInBytes) return compareUnequalLengths(b0, b1);

  for (int i = 0; i < b0.length; i++) {
    if (b0[i] != b1[i]) {
      if (throwOnError) {
        showBytes(b0, b1, i);
        throw "Non-matching bytes at index: $i";
      } else {
        return false;
      }
    }
  }
  return true;
}

bool bytesEqual(Uint8List b0, Uint8List b1) {
  int length = b0.lengthInBytes;
  if (length != b1.lengthInBytes) return compareUnequalLengths(b0, b1);
  var bd0 = b0.buffer.asByteData();
  var bd1 = b1.buffer.asByteData();

  // Note: optimized to use 4 byte boundary
  int remainder = length % 4;
  assert(remainder.isEven);
  int end = length - remainder;
  for (int i = 0; i < end; i += 4)
    if (bd0.getUint32(i) != bd1.getUint32(i)) {
      if (throwOnError) {
        showBytes(bd0.buffer.asUint8List(), bd1.buffer.asUint8List(), i);
        throw "Non-matching bytes at index: $i";
      } else {
        return false;
      }
    }
  if (end < length) if (bd0.getUint16(end) != bd1.getUint16(end)) return false;
  return true;
}

bool compareUnequalLengths(Uint8List b0, Uint8List b1, [bool throwOnError = true]) {
  int length =
      (b0.lengthInBytes < b1.lengthInBytes) ? b0.lengthInBytes : b1.lengthInBytes;
  for (int i = 0; i < length; i++) {
    if (b0[i] != b1[i]) {
      print('  diff @$i');
      print('  b0: ${b0.sublist(i, i + 20)}');
      print('  b1: ${b1.sublist(i, i + 20)}');
      return false;
    }
  }
  return true;
}

void showBytes(Uint8List b0, Uint8List b1, int offset) {
  print('offset: $offset');
  var b0x = b0.buffer.asUint8List(offset, offset + 16);
  var b1x = b1.buffer.asUint8List(offset, offset + 16);
  print(b0x);
  print(b1x);
  int pos = offset % 4;
  int line = (offset ~/ 4) * 4;
  int startLine = line;
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
  var dcm0 = dcm(v0);
  var dcm1 = dcm(v1);
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

bool compareByteDatasets(ByteDataset ds0, ByteDataset ds1, [bool throwOnError = false]) {
  for (ByteElement e0 in ds0.elements) {
    ByteElement e1 = ds1[e0.code];
    if (e0.vrCode == VR.kSQ.code) {
      if (e1.vrCode != VR.kSQ.code) return false;
      if (!compareSequences(e0, e1)) return false;
    } else {
      if (e0.code != e1.code ||
          e0.vrCode != e1.vrCode ||
          e0.vfLength != e1.vfLength ||
          e0.vfBytes.length != e1.vfBytes.length) {
        if (throwOnError) {
          throw 'ds0 != ds1';
        } else {
          return false;
        }
      }
      for (int i = 0; i < e0.vfBytes.length; i++) {
        if (e0.vfBytes[i] != e1.vfBytes[i]) {
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

bool compareSequences(Element s0, Element s1) {
  if (s0.code != s1.code || s0.vrCode != s1.vrCode) return false;
  if (s0 is EVRByteSQ && s1 is EVRByteSQ) {
    if (s0.items.length != s1.items.length) return false;
    for (int i = 0; i < s0.items.length; i++) {
      var item0 = s0[i];
      var item1 = s1[i];
      if (!compareByteDatasets(item0, item1)) return false;
    }
    return true;
  } else if (s0 is IVRByteSQ && s1 is IVRByteSQ) {
    if (s0.items.length != s1.items.length) return false;
    for (int i = 0; i < s0.items.length; i++) {
      var item0 = s0[i];
      var item1 = s1[i];
      if (!compareByteDatasets(item0, item1)) return false;
    }
    return true;
  }
  return false;
}
