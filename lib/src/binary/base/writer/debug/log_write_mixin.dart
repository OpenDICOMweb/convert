// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:dataset/dataset.dart';
import 'package:element/element.dart';
import 'package:system/core.dart';

import 'package:dcm_convert/src/binary/base/writer/log_write_mixin_base.dart';
import 'package:dcm_convert/src/binary/base/writer/write_buffer.dart';
import 'package:dcm_convert/src/element_offsets.dart';

abstract class LogWriteMixin implements LogWriteMixinBase {
  int get elementCount;
  WriteBuffer get wb;
  ParseInfo get pInfo;
  ElementOffsets get inputOffsets;
  ElementOffsets get outputOffsets;

  void updatePInfoPixelData(Element e) {
    log
      ..debug('Pixel Data: ${e.info}')
      ..debug('vfLength: ${e.vfLength}')
      ..debug('vfLengthField: ${e.vfLengthField}')
      ..debug('fragments: ${e.fragments.info}');
    pInfo
      ..pixelDataVR = e.vr
      ..pixelDataStart = wb.wIndex
      ..pixelDataLength = e.vfLength
      ..pixelDataHadFragments = e.fragments != null
      ..pixelDataHadUndefinedLength = e.vfLengthField == kUndefinedLength;
  }

  void doEndOfElementStats(int start, int end, Element e) {
    pInfo.nElements++;
    pInfo
      ..lastElement = e
      ..endOfLastElement = end;
    if (e.isPrivate) pInfo.nPrivateElements++;
    if (e is SQ) {
      pInfo
        ..endOfLastSequence = end
        ..lastSequence = e;
    }

    if (e is! SQ && inputOffsets != null) {
      outputOffsets.add(start, end, e);

      final iStart = inputOffsets.starts[elementCount];
      final iEnd = inputOffsets.ends[elementCount];
      final ie = inputOffsets.elements[elementCount];
      if (iStart != start || iEnd != end || ie != e) {
        log.debug('''
**** Unequal Offset at Element $elementCount
	** $iStart to $iEnd read $e
  ** $start to $end wrote $e''');
        throw 'badOffset';
      }
    }
  }

  void showOffsets() {
    log
      ..info(' input offset length: ${inputOffsets.length}')
      ..info('output offset length: ${outputOffsets.length}');
    for (var i = 0; i < inputOffsets.length; i++) {
      final iStart = inputOffsets.starts[i];
      final iEnd = inputOffsets.ends[i];
      final ioe = inputOffsets.elements[i];
      final oStart = outputOffsets.starts[i];
      final oEnd = outputOffsets.ends[i];
      final ooe = outputOffsets.elements[i];

      log
        ..info('iStart: $iStart iEnd: $iEnd e: $ioe')
        ..info('oStart: $oStart iEnd: $oEnd e: $ooe');
    }
  }

// **** these next four are utilities for logger
  /// The current writeIndex as a string.
  /// The current writeIndex as a string.
  String get _www => 'W@${wb.index.toString().padLeft(5, '0')}';
  String get www => _www;

  /// The beginning of writing something.
  String get wbb => '> $_www';

  /// In the middle of writing something.
  String get wmm => '| $_www';

  /// The end of writing something.
  String get wee => '< $_www';

  String get pad => ''.padRight('$_www'.length);

  int get remaining => wb.remaining;

/*
  void _sMsg(String name, int code, int start, int vrIndex,
          [int hdrLength, int vfLengthField = -1, int inc = 1]) =>
      _msg(wbb, name, code, start, vrIndex, hdrLength, vfLengthField, inc);

  void _mMsg(String name, int code, int start, int vrIndex,
          [int hdrLength, int vfLengthField = -1, int inc = 0]) =>
      _msg(wmm, name, code, start, vrIndex, hdrLength, vfLengthField, inc);
*/

/*
  void _msg(String offset, String name, int code, int start, int vrIndex,
      [int hdrLength, int vfLength = -1, int inc]) {
    final hasLength = hdrLength != null && vfLength != -1 && vfLength != kUndefinedLength;
    final sum = (hasLength) ? start + hdrLength + vfLength : -1;

    final range =
        (hasLength) ? '>$start + $hdrLength + $vfLength = $sum' : '>$start + ???';
    final s = '$offset $name: ${dcm(code)} vr($vrIndex) $range';
    log.debug(s, inc);
  }
*/

/*
  void _eMsg(int eNumber, Object e, int eStart, int eEnd, [int inc = -1]) {
    final s = '$wee #$eNumber $e  |${wb.remaining} - $eEnd = ${wb.remaining -
      eEnd}';
    log.debug(s, inc);
  }
*/
/*

  void _dbgDSWriteStart(String name) => log.debug('$wbb $name');

  void _dbgDSWriteEnd(String name, Dataset ds) =>
      log.debug('$wee #$elementCount $name ${ds.info}');
*/

  String vlfToString(int vlf) =>
      (vlf == null) ? '' : (vlf == kUndefinedLength) ? '0xFFFFFFFF' : '$vlf';

  @override
  void logStartWrite(Element e, String name) {
    final s = _startWriteElement(e, name);
    log.debug(s);
  }

  String _startWriteElement(Element e, String name) {
    final vr = e.vr;
    final tag = e.tag;
    final code = e.code;
    final s = vlfToString(e.vfLengthField);
    final sb = new StringBuffer('$wbb ${dcm(code)} $vr length($s) $name');
    if (system.level == Level.debug2) sb.writeln('\n  $tag');
    return sb.toString();
  }

  @override
  void logEndWrite(int eStart, Element e, String name, {bool ok = true}) {
    final s = _endWriteElement(eStart, e, name, ok: ok);
    log.debug(s);
  }

  String _endWriteElement(int eStart, Element e, String name, {bool ok = true}) {
    final eEnd = wb.index;
    _doEndOfElementStats(e.code, eStart, e, ok);
    final sb = new StringBuffer('$wee $e $eStart - $eEnd = ${eEnd - eStart}:$remaining');
    return sb.toString();
  }

  @override
  void logStartSQWrite(Element e, String name) {
    final s = _startWriteElement(e, name);
    log..debug(s)..down;
  }

  @override
  void logEndSQWrite(int eStart, Element e, String name, {bool ok = true}) {
    final s = _endWriteElement(eStart, e, name, ok: ok);
    log..up..debug(s);
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
    if (e is! SQ) outputOffsets.add(eStart, wb.index, e);
  }
}
