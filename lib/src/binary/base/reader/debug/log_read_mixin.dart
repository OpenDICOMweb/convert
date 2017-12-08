// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:dataset/dataset.dart';
import 'package:element/element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';
import 'package:vr/vr.dart';

import 'package:dcm_convert/src/binary/base/reader/log_read_mixin_base.dart';
import 'package:dcm_convert/src/binary/base/reader/read_buffer.dart';
import 'package:dcm_convert/src/element_offsets.dart';

abstract class LogReadMixin implements LogReadMixinBase {
  bool get isEvr;
  int elementCount;
  ReadBuffer get rb;
  ParseInfo get pInfo;
  ElementOffsets get offsets;

// **** these next four are utilities for logger
  /// The current readIndex as a string.
  String get _rrr => 'R@${rb.index.toString().padLeft(5, '0')}';

  String get rrr => '$_rrr';

  /// The beginning of reading something.
  String get rbb => '> $_rrr';

  /// In the middle of reading something.
  String get rmm => '| $_rrr  ';

  /// The end of reading something.
  String get ree => '< $_rrr ';

//  String get pad => ''.padRight('$_rrr'.length);

  int get remaining => rb.remaining;

/*
  void _sMsg(String name, int code, int start, int vrIndex,
          [int hdrLength, int vfLengthField = -1, int inc = 1]) =>
      _msg(rbb, name, code, start, vrIndex, hdrLength, vfLengthField, inc);

  void _mMsg(String name, int code, int start, int vrIndex,
          [int hdrLength, int vfLengthField = -1, int inc = 0]) =>
      _msg(rmm, name, code, start, vrIndex, hdrLength, vfLengthField, inc);

  void _msg(String offset, String name, int code, int start, int vrIndex,
      [int hdrLength, int vfLength = -1, int inc]) {
    final hasLength = hdrLength != null && vfLength != -1 && vfLength != kUndefinedLength;
    final sum = (hasLength) ? start + hdrLength + vfLength : -1;

    final range =
        (hasLength) ? '>$start + $hdrLength + $vfLength = $sum' : '>$start + ???';
    final s = '$offset $name: ${dcm(code)} vr($vrIndex) $range';
    log.debug(s, inc);
  }

  void _eMsg(int eNumber, Object e, int eStart, int eEnd, [int inc = -1]) {
    final s = '$ree #$eNumber $e  |${rb.remaining} - $eEnd = ${rb.remaining -
      eEnd}';
    log.debug(s, inc);
  }

  void dbgDSReadStart(String name) => log.debug('$rbb $name');

  void dbgDSReadEnd(String name, Dataset ds) =>
      log.debug('$ree #$elementCount $name ${ds.info}');
*/

  String vlfToString(int vlf) =>
      (vlf == null) ? '' : (vlf == kUndefinedLength) ? '0xFFFFFFFF' : '$vlf';

  String _startReadElement(int code, int vrIndex, int eStart, int vlf, String name) {
    final vr = VR.lookupByIndex(vrIndex);
    final tag = Tag.lookup(code);
    final s = vlfToString(vlf);
    final sb = new StringBuffer('$rbb ${dcm(code)} $vr length($s) $name');
    if (system.level == Level.debug2) sb.writeln('\n  $tag');
    return sb.toString();
  }

  @override
  void logStartRead(int code, int vrIndex, int eStart, int vlf, String name) {
    final s = _startReadElement(code, vrIndex, eStart, vlf, name);
    log.debug(s);
  }

  String _endReadElement(int eStart, Element e, String name, {bool ok = true}) {
    final eEnd = eStart - rb.index;
    assert(eEnd == eStart - rb.index);
    _doEndOfElementStats(e.code, eStart, e, ok);
    final sb = new StringBuffer('$ree $e $name :$remaining');
    return sb.toString();
  }

  @override
  void logEndRead(int eStart, Element e, String name, {bool ok = true}) {
    final s = _endReadElement(eStart, e, name, ok: ok);
    log.debug(s);
  }

  @override
  void logStartSQRead(int code, int vrIndex, int eStart, int vlf, String name) {
    final s = _startReadElement(code, vrIndex, eStart, vlf, name);
    log..debug(s)..down;
  }

  @override
  void logEndSQRead(int eStart, Element e, String name, {bool ok = true}) {
    final s = _endReadElement(eStart, e, name, ok: ok);
    log..up..debug(s);
  }

  void _doEndOfElementStats(int code, int eStart, Element e, bool ok) {
    pInfo.nElements++;
    if (ok) {
      pInfo
        ..lastElement = e
        ..endOfLastElement = rb.index;
      if (e.isPrivate) pInfo.nPrivateElements++;
      if (e is SQ) {
        pInfo
          ..endOfLastSequence = rb.index
          ..lastSequence = e;
      }
    } else {
      pInfo.nDuplicateElements++;
    }
    if (e is! SQ) offsets.add(eStart, rb.index, e);
  }


  // **** Below this level is all for debugging and can be commented out for
  // **** production.

  void showNext(int start) {
    if (isEvr) {
      _showShortEVR(start);
      _showLongEVR(start);
      _showIVR(start);
      _showShortEVR(start + 4);
      _showLongEVR(start + 4);
      _showIVR(start + 4);
    } else {
      _showIVR(start);
      _showIVR(start + 4);
    }
  }

  void _showShortEVR(int start) {
    if (rb.hasRemaining(8)) {
      final code = rb.getCode(start);
      final vrCode = rb.getUint16(start + 4);
      final vr = VR.lookupByCode(vrCode);
      final vfLengthField = rb.getUint16(start + 6);
      log.debug('**** Short EVR: ${dcm(code)} $vr vlf: $vfLengthField');
    }
  }

  void _showLongEVR(int start) {
    if (rb.hasRemaining(8)) {
      final code = rb.getCode(start);
      final vrCode = rb.getUint16(start + 4);
      final vr = VR.lookupByCode(vrCode);
      final vfLengthField = rb.getUint32(start + 8);
      log.debug('**** Long EVR: ${dcm(code)} $vr vlf: $vfLengthField');
    }
  }

  void _showIVR(int start) {
    if (rb.hasRemaining(8)) {
      final code = rb.getCode(start);
      final tag = Tag.lookupByCode(code);
      if (tag != null) log.debug(tag);
      final vfLengthField = rb.getUint16(start + 4);
      log.debug('**** IVR: ${dcm(code)} vlf: $vfLengthField');
    }
  }

  String toVFLength(int vfl) => 'vfLengthField($vfl, ${hex32(vfl)})';
  String toHadULength(int vfl) =>
      'HadULength(${(vfl == kUndefinedLength) ? 'true': 'false'})';

  void showReadIndex([int index, int before = 20, int after = 28]) {
    index ??= rb.index;
    if (index.isOdd) {
      rb.warn('**** Index($index) is not at even offset ADDING 1');
      index++;
    }

    for (var i = index - before; i < index; i += 2) {
      log.debug('$i:   ${hex16(rb.getUint16 (i))} - ${rb.getUint16 (i)}');
    }

    log.debug('** ${hex16(rb.getUint16 (index))} - ${rb.getUint16 (index)}');

    for (var i = index + 2; i < index + after; i += 2) {
      log.debug('$i: ${hex16(rb.getUint16 (i))} - ${rb.getUint16 (i)}');
    }
  }
}
