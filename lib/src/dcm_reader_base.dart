// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

import 'package:core/src/dicom_utils.dart';

/*
const k10KB = 10 * 1024;
const k20KB = 20 * 1024;
const k50KB = 50 * 1024;
const k100KB = 100 * 1024;*/
const k200KB = 200 * 1024;


// Next 3 values are 2x16bit little Endian values as one 32bit value.
const kSequenceDelimitationItem32Bit = 0xfeffdde0;
const kItem32Bit = 0xfeff00e0;
const kItemDelimitationItem32Bit = 0xfeff0de0;

///TODO: doc
abstract class DcmReaderBase {
  static final Logger _log = new Logger("DcmReader", watermark: Severity
      .debug2);

  //TODO: make private later
  /// The root Dataset for the object being read.
  Dataset get rootDS;
  Dataset get currentDS;
  int rIndex = 0;

  /// The source of the [Uint8List] being read.
  final String path;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;
  final bool allowILEVR;
  final bool allowMissingPrefix;
  final bool allowMissingFMI;
  final TransferSyntax targetTS;
  final bool reUseBD;

  int pixelDataIndex = -1;
  bool hadShortByteData;
  bool preamblePresent;
  bool hadPrefix;
  bool preambleWasZeros;
  bool hadFMI = false;
  bool hadProblems = false;
  bool hadNonZeroDelimiterLength = true;
  bool hadParsingErrors = false;
  bool hadTrailingZeros = false;
  Part10Header part10;

  // **** Reader fields ****
  /// The [ByteData] being read.
  final ByteData bd;
  final int endOfBD;
  int endOfPixelData;

  /// Creates a new [DcmByteReader]  where [_rIndex] = [writeIndex] = 0.
  DcmReaderBase(this.bd, Map<int, dynamic> fmi,
      {this.path = "",
      this.throwOnError = true,
      this.allowILEVR = true,
      this.allowMissingPrefix = true,
      this.allowMissingFMI = false,
      this.targetTS,
      this.reUseBD})
      : endOfBD = bd.lengthInBytes;

  Element readElement();

  /// The DICOM Part 10 Prefix.
  String  get prefix => 'DICM';

  bool get isReadable => rIndex < endOfBD;

  /// [true] if the source [ByteData] have been read.
  bool get wasRead => (_wasRead == null) ? false : _wasRead;
  bool _wasRead;
  set wasRead(bool v) => _wasRead ??= v;

  String get info => '$runtimeType: rootDS: ${rootDS.info}, currentDS: '
      '${currentDS.info}';

  int get smallFileThreshold => 1024;

  bool get isSmallFile => bd.lengthInBytes > smallFileThreshold;

  /// The beginning of reading an [ByteElement] or [ByteItem].
  String get rbb => '> R@$rIndex';

  /// In the middle of reading an [ByteElement] or [ByteItem]
  String get rmm => '| R@$rIndex';

  /// The end of reading an [ByteElement] or [ByteItem]
  String get ree => '< R@$rIndex';

  /// Reads File Meta Information ([Fmi]) and returns a Map<int, Element>
  /// if any [Fmi] [ByteElement]s were present; otherwise, returns null.
  bool readPrefix(ByteData bd, [bool checkForZeros = true]) {
    _log.debugDown('$rbb readPrefix');
    if (rIndex != 0) throw 'Read Index $rIndex != 0';
    if (rootDS == null) throw 'Missing Root Dataset';
    if (bd.lengthInBytes < smallFileThreshold) {
      hadProblems = true;
      hadShortByteData == true;
      if (bd.lengthInBytes < 256) throw 'File too short';
    }

    if (checkForZeros) {
      for(int i = 0; i < 128; i += 8)
        if (bd.getUint64(i) != 0) preambleWasZeros = false;;
      preambleWasZeros = true;
      rIndex = 128;
    }

    var token = ASCII.decode(bd.buffer.asUint8List(128, 4));
    if (token == 'DICM') {
      preamblePresent = true;
      rIndex = 132;
      _log.debug('$ree readPrefix true');
      return true;
    }
    rIndex = 0;
    _log.debug('$rbb readPrefix **** false');
    return false;
  }

  /// Returns a valid [TransferSyntax] or [null] if not valid.
  TransferSyntax getTransferSyntax(Map<int, Element> fmi,
      [TransferSyntax targetTS]) {
    TransferSyntax ts;
    Element e = fmi[kTransferSyntaxUID];
    if (e == null) return null;
    _log.debug('TS: (${e.asString.length})"${e.asString}"');
    if (e.vr != VR.kUI) return null;

    var s = e.asString;
    if (s != null) ts = TransferSyntax.lookup(s);
    if (ts == null) {
      _log.warn('Unknown Transfer Syntax: "${e.asString}"');
      return null;
    }

    _log.debug('targetTS($targetTS), TS($ts)');
    if (targetTS != null && ts != targetTS && throwOnError)
      throw new InvalidTransferSyntaxError(ts, 'Non-Target TS', ts);
    if (!System.isSupportedTransferSyntax(ts) && throwOnError)
      throw new InvalidTransferSyntaxError(ts, 'Not supported.');
    if (ts == TransferSyntax.kExplicitVRBigEndian && throwOnError) {
      throw new InvalidTransferSyntaxError(
          ts, 'Explicit VR Big Endian not supported.');
    }
    return ts;
  }


  int readUint16() {
    int v = bd.getUint16(rIndex, Endianness.HOST_ENDIAN);
    rIndex += 2;
    return v;
  }

  int readUint32() {
    int v = bd.getUint32(rIndex, Endianness.HOST_ENDIAN);
    rIndex += 4;
    return v;
  }

  bool inRange(int index) => index >= 0 || index < endOfBD;

  int skip(int n) {
    int index = rIndex + n;
    if (inRange(index)) rIndex = index;
    return rIndex;
  }

  Uint8List readChars(int length) {
    var chars = bd.buffer.asUint8List(rIndex, length);
    rIndex += length;
    return chars;
  }

  String readAsciiString(int length) {
    var s = ASCII.decode(readChars(length));
    return s;
  }

//  String _readUtf8String(int length) => UTF8.decode(_readChars(length));

  // **** DICOM encoding stuff ****

  /// Peek at next tag - doesn't move the [rIndex].
  int peekTagCode() {
    int group = bd.getUint16(rIndex, Endianness.HOST_ENDIAN);
    int elt = bd.getUint16(rIndex + 2, Endianness.HOST_ENDIAN);
    return (group << 16) + elt;
  }

  /// Returns a 32-bit DICOM Tag Code, or [null] if [code] > [tagLimit].
  int readTagCodeNoChecking() {
    int group = bd.getUint16(rIndex, Endianness.HOST_ENDIAN);
    int elt = bd.getUint16(rIndex + 2, Endianness.HOST_ENDIAN);
    rIndex += 4;
    return (group << 16) + elt;
  }

  /// Returns a 32-bit DICOM Tag Code, or [null] if [code] > [tagLimit].
  int readTagCode() {
    int group = bd.getUint16(rIndex, Endianness.HOST_ENDIAN);
    int elt = bd.getUint16(rIndex + 2, Endianness.HOST_ENDIAN);
    rIndex += 4;
    int code = (group << 16) + elt;
    if (code == 0) {
      if (rootDS[kPixelData] != null) if ((code > 0xFFFCFFFC && code < kItem)) {
        skip(-4);
        _log.error('attempt to read beyone end of Dataset');
        return null;
      } else {
        zeroEncountered(code);
      }
    }
    return code;
  }

  int zeroEncountered(int code) {
    var firstTime = true;
    if (code == 0 && firstTime == true) {
      firstTime = false;
      return readTagCodeNoChecking();
    } else {
      int start = rIndex - 4;
      _log.warn('$rmm Zero code($code) encountered @$start');
      _log.debug(bd.buffer.asUint8List(rIndex, 100));
      _log.debug(bd.buffer.asUint8List(rIndex, 100));
      while (isReadable) {
        int v = readUint32();
        if (v != 0) {
          //     rIndex = start - 8;
          while (isReadable && rIndex < (start + 40)) {
            int tag = peekTagCode();
            int val = readUint32();
            skip(-3);
            var s = val.toString().padLeft(8, "0");
            _log.debug('$rmm ${toDcm(tag)} $s');
          }
          hadParsingErrors = true;
          throw "bad code ${toDcm(code)}";
        }
        hadTrailingZeros = true;
      }
      _log.warn('returning from reading zeros at bytes @$rIndex in "$path"');
      return 0;
    }
  }

  bool warnIfShortFile(String path) {
    int length = bd.lengthInBytes;
    if (length < smallFileThreshold) {
      hadProblems = true;
      if (length < 256) throw 'Short File Error: ${bd.lengthInBytes}, $path';
      _log.warn('**** Reading $length bytes from File: "$path"');
      return true;
    }
    return false;
  }

}
