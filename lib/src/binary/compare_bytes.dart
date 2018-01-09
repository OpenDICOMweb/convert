// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dataset/dataset.dart';
import 'package:element/element.dart';
import 'package:element/bd_element.dart';
import 'package:system/core.dart';
import 'package:vr/vr.dart';

/// TODO DOC
bool bytesEqual1(Uint8List b0, Uint8List b1) {
  if (b0.lengthInBytes != b1.lengthInBytes) return compareUnequalLengths(b0, b1);

  for (var i = 0; i < b0.length; i++) {
    if (b0[i] != b1[i]) {
      if (throwOnError) {
        showBytes(b0, b1, i);
        throw 'Non-matching bytes at index: $i';
      } else {
        return false;
      }
    }
  }
  return true;
}

/* TODO: compare with element/byte_element_mixin
bool bytesEqual(Uint8List b0, Uint8List b1) {
  final length = b0.lengthInBytes;
  if (length != b1.lengthInBytes) return compareUnequalLengths(b0, b1);
  final bd0 = b0.buffer.asByteData();
  final bd1 = b1.buffer.asByteData();

  // Note: optimized to use 4 byte boundary
  final remainder = length % 4;
  assert(remainder.isEven);
  final end = length - remainder;
  for (var i = 0; i < end; i += 4)
    if (bd0.getUint32(i) != bd1.getUint32(i)) {
      if (throwOnError) {
        showBytes(bd0.buffer.asUint8List(), bd1.buffer.asUint8List(), i);
        throw 'Non-matching bytes at index: $i';
      } else {
        return false;
      }
    }
  if (end < length) if (bd0.getUint16(end) != bd1.getUint16(end)) return false;
  return true;
}
*/

bool compareUnequalLengths(Uint8List b0, Uint8List b1) {
  final length =
      (b0.lengthInBytes < b1.lengthInBytes) ? b0.lengthInBytes : b1.lengthInBytes;
  for (var i = 0; i < length; i++) {
    if (b0[i] != b1[i]) {
      log
        ..debug('  diff @$i')
        ..debug('  b0: ${b0.sublist(i, i + 20)}')
        ..debug('  b1: ${b1.sublist(i, i + 20)}');
      return false;
    }
  }
  return true;
}

void showBytes(Uint8List b0, Uint8List b1, int offset) {
  log.debug('offset: $offset');
  final b0x = b0.buffer.asUint8List(offset, offset + 16);
  final b1x = b1.buffer.asUint8List(offset, offset + 16);
  log..debug(b0x)..debug(b1x);
  final pos = offset % 4;
  final line = (offset ~/ 4) * 4;
  final startLine = line;
  final endLine = line + 96;

  log
    ..debug('Non-matching bytes at offset: $offset')
    ..debug('O     B0           B1        B0   B1       B0          B1');
//log.debug('(gggg,eeee)  (gggg,eeee)  abcf abcd  0123456789  0123456789');

  for (var i = startLine; i < line - 1; i += 4) {
    printLine(i, b0, b1);
  }
  printLine(line, b0, b1, pos);
  for (var i = line + 1; i < endLine; i += 4) {
    printLine(i, b0, b1);
  }
}

void printLine(int line, Uint8List b0, Uint8List b1, [int pos]) {
  final bd0 = b0.buffer.asByteData();
  final bd1 = b1.buffer.asByteData();

  final v0 = bd0.getUint32(line);
  final v1 = bd1.getUint32(line);
  final dcm0 = dcm(v0);
  final dcm1 = dcm(v1);
  final dec0 = toDec32(v0);
  final dec1 = toDec32(v1);
  final s0 = toStr(b0, line);
  final s1 = toStr(b1, line);
  if (pos != null) {
    log.debug('$pos: $dcm0  $dcm1  "$s0"  "$s1"  $dec0 $dec1');
  } else {
    log.debug('   $dcm0  $dcm1  "$s0"  "$s1"  $dec0 $dec1');
  }
}

String toStr(Uint8List bytes, int index) {
  final line = bytes.buffer.asUint8List(index, 4);
  for (var i = 0; i < 4; i++) {
    if (!isVisibleChar(line[i])) line[i] = kAsterisk;
  }
  return new String.fromCharCodes(line);
}

bool compareByteDatasets(Dataset ds0, Dataset ds1) {
  for (var e0 in ds0.elements) {
    final e1 = ds1[e0.code];
    if (e0.vrCode == VR.kSQ.code) {
      if (e1.vrCode != VR.kSQ.code) return false;
      if (!compareSequences(e0, e1)) return false;
    } else {
      if (e0.code != e1.code ||
          e0.vrCode != e1.vrCode ||
          e0.length != e1.length ||
          e0.vfBytes.length != e1.vfBytes.length) {
        if (throwOnError) {
          throw 'ds0 != ds1';
        } else {
          return false;
        }
      }
      for (var i = 0; i < e0.vfBytes.length; i++) {
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

bool compareSequences(SQ s0, SQ s1) {
  if (s0.code != s1.code || s0.vrCode != s1.vrCode) return false;
  if (s0.items.length == s1.items.length) {
    for (var i = 0; i < s0.items.length; i++) {
      final item0 = s0[i];
      final item1 = s1[i];
      if (!compareByteDatasets(item0, item1)) return false;
    }
    return true;
  }
  return false;
}
