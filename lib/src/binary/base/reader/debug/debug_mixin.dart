// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:dataset/byte_dataset.dart';
import 'package:dcm_convert/src/binary/base/reader/read_buffer.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';

abstract class DbgMixin {

  int elementCount = -1;
  //  sys.l = Level.debug;
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
  String get ree => '< $_rrr  ';

  String get pad => ''.padRight('$_rrr'.length);

  int get remaining => rb.remaining;

  void sMsg(String name, int code, int start, int vrIndex,
          [int hdrLength, int vfLengthField = -1, int inc = 1]) =>
      _msg(rbb, name, code, start, vrIndex, hdrLength, vfLengthField, inc);

  void mMsg(String name, int code, int start, int vrIndex,
          [int hdrLength, int vfLengthField = -1, int inc = 0]) =>
      _msg(rmm, name, code, start, vrIndex, hdrLength, vfLengthField, inc);

  void _msg(String offset, String name, int code, int start, int vrIndex,
      [int hdrLength, int vfLength = -1, int inc]) {
    final hasLength =
        hdrLength != null && vfLength != -1 && vfLength != kUndefinedLength;
    final sum = (hasLength) ? start + hdrLength + vfLength : -1;

    final range = (hasLength)
        ? '>$start + $hdrLength + $vfLength = $sum'
        : '>$start + ???';
    final s = '$offset $name: ${dcm(code)} vr($vrIndex) $range';
    log.debug(s, inc);
  }

  void eMsg(int eNumber, Object e, int eStart, int eEnd, [int inc = -1]) {
    final s = '$ree #$eNumber $e  |${rb.remaining} - $eEnd = ${rb.remaining -
      eEnd}';
    log.debug(s, inc);
  }

  void dbgDSReadStart(String name) => log.debug('$rbb $name');

  void dbgDSReadEnd(String name, Dataset ds) =>
      log.debug('$ree #$elementCount $name ${ds.info}');


  String vlfToString(int vlf) =>
      (vlf == null) ? "" : (vlf == kUndefinedLength) ? '0xFFFFFFFF' : '$vlf';

  void dbgReadStart(int eStart, int vrIndex, int code, String name, [int vlf]) {
    final vr = VR.lookupByIndex(vrIndex);
    final tag = Tag.lookup(code);
    final s = vlfToString(vlf);
    final sb = new StringBuffer('$rbb ${dcm(code)} $vr $name $s');
    if (system.level == Level.debug2) sb.writeln('\n  $tag');
    log.debug(sb.toString());
  }

  void dbgReadEnd(int eStart, Element e) {
    final eEnd = eStart - rb.index;
    assert(eEnd == eStart - rb.index);
    _doEndOfElementStats(e.code, eStart, e, ok);
    final sb = new StringBuffer(
        '$ree $e $eStart + vfLength(${e.vfLength}) = ${rb.index} :$remaining');
  }

  void _doEndOfElementStats(int code, int eStart, Element e, bool ok) {
    pInfo.nElements++;
    if (ok) {
      pInfo.lastElementRead = e;
      pInfo.endOfLastElement = rb.rIndex;
      if (e.isPrivate) pInfo.nPrivateElements++;
      if (e is SQ) {
        pInfo.endOfLastSequence = rb.rIndex;
        pInfo.lastSequenceRead = e;
      }
    } else {
      pInfo.nDuplicateElements++;
    }
    if (e is! SQ) offsets.add(eStart, rb.rIndex, e);
  }


}
