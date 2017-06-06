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

const k10KB = 10 * 1024;
const k20KB = 20 * 1024;
const k50KB = 50 * 1024;
const k100KB = 100 * 1024;
const k200KB = 200 * 1024;

///TODO: doc
abstract class DcmReaderBase {
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
  //TODO: make private later
  Dataset currentDS;
  int pixelDataIndex = -1;
  bool hadTrailingZeros = false;
  bool hadParsingErrors = false;

  // **** Reader fields ****

  /// The [ByteData] being read.
  final ByteData bd;
  final int endOfBD;
  Part10Header _p10Header;
  bool _hadParsingErrors;
  bool _wasShortBD;

  /// Creates a new [DcmByteReader]  where [_rIndex] = [writeIndex] = 0.
  DcmReaderBase(this.bd,
      {this.path = "",
      this.throwOnError = true,
      this.allowILEVR = true,
      this.allowMissingPrefix = true,
      this.allowMissingFMI = false,
      this.targetTS})
      : endOfBD = bd.lengthInBytes {
    warnIfShortFile(path);
  }

  /// The root Dataset for the object being read.
  Dataset get rootDS;
  int rIndex = 0;

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
  Part10Header readPart10Header(ByteData bd) {
    if (rIndex != 0) throw 'DICOM Prefix has already been read';
    String prefix = ASCII.decode(bd.buffer.asUint8List(128, 132));
    if (prefix != 'DICM') {
      rIndex == 0;
      return null;
    }
    Map<int, Element> fmi = readFmi();
    if (fmi == null) return null;
    return new Part10Header(bd, true, fmi);
  }

  /// Read File Meta Information (PS3.10).
  Map<int, Element> readFmi() {
    Map<int, Element> fmi = <int, Element>{};
    try {
      //      _readDataset(rootDS, endOfBD, 0x00080000);
      while (rIndex < endOfBD) {
        int code = peekTagCode();
        if (code >= 0x00030000) break;
        ByteElement e = _readElement();
        fmi[e.code] = e;
      }
    } on InvalidTransferSyntaxError catch (x) {
      _hadParsingErrors = true;
      _log.warn('$ree readFMI TS catch: $x');
      //rethrow;
      rIndex = 0;
      return null;
    } catch (x) {
      _hadParsingErrors = true;
      _log.warn('Failed to read FMI: "$path"\nException: $x\n'
          'File length: ${bd.lengthInBytes}\n$ree readFMI catch: $x');
      rIndex = 0;
      rethrow;
    }

    //TODO: move to Reader
    TransferSyntax ts = rootDS.transferSyntax;
    _log.debug('$rmm readFMI: targetTS($targetTS), TS($ts) isExplicitVR: '
        '${rootDS.isEVR}');
    //Urgent: collapse to one if statement
    if (ts == TransferSyntax.kExplicitVRBigEndian) {
      hadParsingErrors = true;
      if (throwOnError)
        throw new InvalidTransferSyntaxError(
            ts, 'Explicit VR Big Endian not supported.');
      rIndex = 0;
      return null;
    } else if (!rootDS.hasValidTransferSyntax) {
      hadParsingErrors = true;
      if (throwOnError)
        throw new InvalidTransferSyntaxError(ts, 'Not supported.');
      rIndex = 0;
      return null;
    } else if (targetTS != null && ts != targetTS) {
      if (throwOnError)
        throw new InvalidTransferSyntaxError(ts, 'Non-Target TS', ts);
      rIndex = 0;
      return null;
    }
    _log.debug2('$ree readFmi:\n ${rootDS.info}');
    return fmi;
  }

  TransferSyntax defaultTransferSyntax = TransferSyntax.kImplicitVRLittleEndian;

  TransferSyntax getTransferSyntax(Map<int, Element> fmi) {
    Element e = fmi[kTransferSyntaxUID];
    if (e == null) return defaultTransferSyntax;
    if (e is UI) {
      var s = e.value;
      if (s == null) return defaultTransferSyntax;
      TransferSyntax ts = TransferSyntax.lookup(s);
      if (ts == null) return defaultTransferSyntax;

      _log.debug('$rmm readFMI: targetTS($targetTS), TS($ts) isExplicitVR: '
          '${rootDS.isEVR}');
      //Urgent: collapse to one if statement
      if (ts == TransferSyntax.kExplicitVRBigEndian) {
        hadParsingErrors = true;
        if (throwOnError)
          throw new InvalidTransferSyntaxError(
              ts, 'Explicit VR Big Endian not supported.');
        rIndex = 0;
        return null;
      } else if (!System.isSupportedTransferSyntax(ts)) {
        hadParsingErrors = true;
        if (throwOnError)
          throw new InvalidTransferSyntaxError(ts, 'Not supported.');
        rIndex = 0;
        return null;
      } else if (targetTS != null && ts != targetTS) {
        if (throwOnError)
          throw new InvalidTransferSyntaxError(ts, 'Non-Target TS', ts);
        rIndex = 0;
        return null;
      }
      _log.debug2('$ree readFmi:\n ${rootDS.info}');
      return ts;
    }
    return defaultTransferSyntax;
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

  void warnIfShortFile(String path) {
    int length = bd.lengthInBytes;
    if (length < smallFileThreshold) {
      hadParsingErrors = true;
      if (length < 256)  throw 'Short File Error: ${bd.lengthInBytes}, $path';
      _log.warn('**** Reading $length bytes from File: "$path"');
    }
  }
}
