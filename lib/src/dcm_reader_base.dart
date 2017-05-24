// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:common/logger.dart';
import 'package:core/src/dataset/dataset_base.dart';
import 'package:dictionary/dictionary.dart';

import 'bytebuf/bytebuf.dart';
import 'package:core/src/dicom_utils.dart';

const k10KB = 10 * 1024;
const k20KB = 20 * 1024;
const k50KB = 50 * 1024;
const k100KB = 100 * 1024;
const k200KB = 200 * 1024;

///TODO: doc
abstract class DcmReaderBase extends ByteBuf {
  static final Logger _log =
      new Logger("DcmReader", watermark: Severity.config);

  /// The source of the [Uint8List] being read.
  final String path;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;
  final bool allowILEVR;
  final bool allowMissingPrefix;
  final bool allowMissingFMI;
  final TransferSyntax targetTS;

  /// The current dataset.  This changes as [Item]s are read.
  DatasetBase currentDS;
  int pixelDataIndex = -1;
  bool hadTrailingZeros = false;

  // **** Reader fields ****

  final ByteData bd;
  final int endOfBD;

  /// Creates a new [DcmByteReader]  where [_rIndex] = [writeIndex] = 0.
  DcmReaderBase(this.bd,
      {this.path = "",
      this.throwOnError = true,
      this.allowILEVR = true,
      this.allowMissingPrefix = true,
      this.allowMissingFMI = false,
      this.targetTS})
      : endOfBD = bd.lengthInBytes,
        super.reader(bd.buffer.asUint8List()) {
    warnIfShortFile(path);
  }

  /// The root Dataset for the object being read.
  DatasetBase get rootDS;
  int rIndex = 0;

  bool get isReadable => rIndex < endOfBD;

  /// [true] if the source [ByteData] have been read.
  bool get wasRead => (_wasRead == null) ? false : _wasRead;
  bool _wasRead;
  set wasRead(bool v) => _wasRead ??= v;

  /// [true] if the source [ByteData] has been read.
  bool hadParsingErrors = false;

  String get info => '$runtimeType: rootDS: ${rootDS.info}, currentDS: '
      '${currentDS.info}';

  int get smallFileThreshold => 1024;

  /// The beginning of reading an [ByteElement] or [ByteItem].
  String get rbb => '> R@$rIndex';

  /// In the middle of reading an [ByteElement] or [ByteItem]
  String get rmm => '| R@$rIndex';

  /// The end of reading an [ByteElement] or [ByteItem]
  String get ree => '< R@$rIndex';

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

  void warnIfShortFile(String path) {
    int length = bd.lengthInBytes;
    if (length < smallFileThreshold) {
      var s = 'Short file error: length(${bd.lengthInBytes}) $path';
      hadParsingErrors = true;
      if (length < 256)  throw 'Short File Error: ${bd.lengthInBytes}, $path';
      _log.warn('**** Reading $length bytes from File: "$path"');
    }
  }
}
