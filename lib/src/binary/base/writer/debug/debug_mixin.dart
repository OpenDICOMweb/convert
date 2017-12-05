// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:dataset/byte_dataset.dart';
import 'package:dcm_convert/src/binary/base/writer/base/write_buffer.dart';
import 'package:dcm_convert/src/element_offsets.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';
import 'package:tag/tag.dart';
import 'package:vr/vr.dart';

abstract class DbgMixin {
  int elementCount = -1;
  //  sys.l = Level.debug;
  WriteBuffer get wb;
  ParseInfo get pInfo;
  ElementOffsets get offsets;

// **** these next four are utilities for logger
  /// The current readIndex as a string.
  String get _www => 'R@${wb.index.toString().padLeft(5, '0')}';

  String get www => '$_www';

  /// The beginning of reading something.
  String get wbb => '> $_www';

  /// In the middle of reading something.
  String get wmm => '| $_www  ';

  /// The end of reading something.
  String get wee => '< $_www  ';

  String get pad => ''.padRight('$_www'.length);

  int get remaining => wb.remaining;

  void sMsg(String name, int code, int start, int vrIndex,
          [int hdrLength, int vfLengthField = -1, int inc = 1]) =>
      _msg(wbb, name, code, start, vrIndex, hdrLength, vfLengthField, inc);

  void mMsg(String name, int code, int start, int vrIndex,
          [int hdrLength, int vfLengthField = -1, int inc = 0]) =>
      _msg(wmm, name, code, start, vrIndex, hdrLength, vfLengthField, inc);

  void _msg(String offset, String name, int code, int start, int vrIndex,
      [int hdrLength, int vfLength = -1, int inc]) {
    final hasLength = hdrLength != null && vfLength != -1 && vfLength != kUndefinedLength;
    final sum = (hasLength) ? start + hdrLength + vfLength : -1;

    final range =
        (hasLength) ? '>$start + $hdrLength + $vfLength = $sum' : '>$start + ???';
    final s = '$offset $name: ${dcm(code)} vr($vrIndex) $range';
    log.debug(s, inc);
  }

  void eMsg(int eNumber, Object e, int eStart, int eEnd, [int inc = -1]) {
    final s = '$wee #$eNumber $e  |${wb.remaining} - $eEnd = ${wb.remaining -
      eEnd}';
    log.debug(s, inc);
  }

  void dbgDSWriteStart(String name) => log.debug('$wbb $name');

  void dbgDSWriteEnd(String name, Dataset ds) =>
      log.debug('$wee #$elementCount $name ${ds.info}');

  String vlfToString(int vlf) =>
      (vlf == null) ? '' : (vlf == kUndefinedLength) ? '0xFFFFFFFF' : '$vlf';

  void dbgWriteStart(int eStart, int vrIndex, int code, String name, [int vlf]) {
    final vr = VR.lookupByIndex(vrIndex);
    final tag = Tag.lookup(code);
    final s = vlfToString(vlf);
    final sb = new StringBuffer('$wbb ${dcm(code)} $vr $name $s');
    if (system.level == Level.debug2) sb.writeln('\n  $tag');
    log.debug(sb.toString());
  }

  void dbgWriteEnd(int eStart, Element e, {bool ok = true}) {
    final eEnd = eStart - wb.index;
    assert(eEnd == eStart - wb.index);
    _doEndOfElementStats(e.code, eStart, e, ok);
    final sb = new StringBuffer(
        '$wee $e $eStart + vfLength(${e.vfLength}) = ${wb.index} :$remaining');
    log.debug(sb.toString());
  }

  void _doEndOfElementStats(int code, int eStart, Element e, bool ok) {
    pInfo.nElements++;
    if (ok) {
      pInfo
        ..lastElement = e
        ..endOfLastElement = wb.index;
      if (e.isPrivate) pInfo.nPrivateElements++;
      if (e is SQ) {
        pInfo
          ..endOfLastSequence = wb.index
          ..lastSequence = e;
      }
    } else {
      pInfo.nDuplicateElements++;
    }
    if (e is! SQ) offsets.add(eStart, wb.index, e);
  }
}
