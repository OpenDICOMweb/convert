// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/ascii.dart';
import 'package:common/logger.dart';
import 'package:dictionary/dictionary.dart';

const int kSQCode = 0x5153;
const int kOBCode = 0x424f;
const int kOWCode = 0x574f;
const int kUNCode = 0x4e55;

int toGroup(int code) => code >> 16;
int toElt(int code) => code & 0xFFFF;
int toCode(int group, int elt) => (group << 16) + elt;

String toGroupHex(int group) => toHex(group, 4, '0x');
String toEltHex(int elt) => toHex(elt, 4, '0x');

String toDcm(int code) {
 // int x = code & 0xFFFFFFFF;
 // assert(x < 0xFFFFFFFF);
  return '(${toHex16(code >> 16)},${toHex16(code & 0xFFFF)})';
}

String toDec(int v, int width, [String prefix = ""]) {
  return v.toRadixString(10).padLeft(width, '0');
}

String toDec32(int v) => toDec(v, 10);
String toDec16(int v) => toDec(v, 5);

String toHex(int v, int width, [String prefix = ""]) {
  if (width > 8) print('******* toHex width: $width');
  return v.toRadixString(16).padLeft(width, '0');
}

String toHex32(int v) => toHex(v, 8);
String toHex16(int v) => toHex(v, 4);
String toHex8(int v) => toHex(v, 2);

String bytesToHex(Uint8List v, int start, int end) {
  var sb = new StringBuffer();
  for (int i in v) sb.write(i.toRadixString(16).padLeft(2, '0'));
  return sb.toString();
}

final Logger _log = new Logger('dcm_no_tag', watermark: Severity.debug);

// Auxiliary used for debugging
String bdToHex(ByteData bd, int start, int end, [int pos]) {
  var bytes = bd.buffer.asUint8List(start, end);
  _log.debug('bdToHex: start($start), end($end), pos($pos');
  if (pos == null) pos = start;
  if (start >= end) return "";
  if (pos >= end) pos = end;

  _log.debug('bdToHex: start($start), end($end), pos($pos');
  var s = "";
  for (int i = start; i < pos; i++) s += ' ' + toHex8(bytes[i]);

  s += "|";
  s += toHex8(bytes[pos]);
  s += "|";

  if (end >= end) end = end;
  for (int i = pos + 1; i < end; i++) s += ' ' + toHex8(bytes[i]);
  return s;
}

// Auxiliary used for debugging
String toAscii(ByteData bd, int start, int end, [int pos]) {
  String vChar(int c) =>
      (isVisibleChar(c)) ? '_' + new String.fromCharCode(c) : '__';

  var bytes = bd.buffer.asUint8List(start, end);
  _log.debug('toAscii: start($start), end($end), pos($pos');
  if (pos == null) pos = start;
  if (start >= end) return "";
  if (pos >= end) pos = end;

  _log.debug('toAscii: start($start), end($end), pos($pos');
  String s = "";
  for (int i = start; i < pos; i++) s += ' ' + vChar(bytes[i]);
  s += "|";
  s += vChar(bytes[pos]);
  s += "|";
  if (end >= end) end = end;
  for (int i = pos + 1; i < end; i++) s += ' ' + vChar(bytes[i]);
  return '$s';
}

class InvalidTransferSyntaxError extends Error {
  final TransferSyntax ts;

  InvalidTransferSyntaxError(this.ts, [Logger log]) {
    if (log != null) log.error(toString());
  }

  @override
  String toString() => '$runtimeType:\n  Element(${ts.info})';
}
