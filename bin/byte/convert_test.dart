// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:common/common.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:dcm_convert/src/dcm/convert_byte_to_tag.dart';
import 'package:dictionary/dictionary.dart';

import 'package:dcm_convert/src/dcm/dcm_reader.dart';

Logger _log = new Logger('convert_test', watermark: Severity.debug1);

void main() {
  DcmReader.log.watermark = Severity.debug1;
  print('Dart Version: ${Platform.version}');
  print('${Platform.script}');

  for (String path in [path0]) {
    try {
      File f = new File(path);
/*      FileResult r = readFileWithResult(f, fmiOnly: false);
      if (r == null) {
        _log.config('No Result');
      } else {
        _log.config('${r.info}');
      }*/
      convert(f, fmiOnly: false);
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}

bool convert(File file, {int reps = 1, bool fmiOnly = false}) {
  _log.debug2('Reading: $file');
  RootByteDataset bRoot = ByteReader.readFile(file, fast: true);
  _log.debug('bRoot.isRoot: ${bRoot.isRoot}');
  _log.debug1(bRoot.parseInfo.info);
  if (bRoot == null) return false;

  RootTagDataset tRoot = convertByteDSToTagDS(bRoot);
  _log.info('tRoot: $tRoot');

  // Test dataset equality
  _log.info('Byte DS: $bRoot');
  _log.info('Tag DS$tRoot');
  if (bRoot.length != tRoot.length) throw "Unequal Top Level";
  if (bRoot.total != tRoot.total) throw "Unequal Total";

  _log.info('Byte DS: ${bRoot.summary}');
  _log.info(' Tag DS: ${tRoot.summary}');
  // write out converted dataset and compare the bytes
  //Urgent: make this work
  // Uint8List bytes1 = DcmWriter.writeBytes(rds1, reUseBD: true);
//  if (bytes1 == null) return false;
//  bytesEqual(bytes0, bytes1);

  if (bRoot.parent != tRoot.parent) {
    _log.error('Parents Not equal');
    _log.warn('  rds0.parent: ${bRoot.parent}');
    _log.warn('  rds1.parent: ${tRoot.parent}');
  }
  if (bRoot.hadULength != tRoot.hadULength) {
    _log.error('hadULength Not equal');
    _log.info('  rds0.hadULength: ${bRoot.hadULength}');
    _log.info('  rds1.hadULength: ${tRoot.hadULength}');
  }
  if (bRoot.length != tRoot.length) {
    _log.error('map.length Not equal');
    _log.info('  rds0.map.length: ${bRoot.length}');
    _log.info('  rds1.map.length: ${tRoot.length}');
  }
  if (bRoot.total != tRoot.total) {
    _log.error('total Not equal');
    _log.info('  rds0.total: ${bRoot.total}');
    _log.info('  rds1.total: ${tRoot.total}');
  }

  for (int code in bRoot.map.keys) {
    ByteElement be = bRoot.map[code];
    TagElement te = tRoot.map[code];

    bool error = false;
    if (be.code != te.code) {
      error = true;
      _log.error('Code Not Equal be.code(${be.code}) != te.code(${te.code})');
    }
    if (be.vr != te.vr) {
      if (be.vr == VR.kUN && be.isPrivate) {
        _log.info('--- ${toDcm(be.code)} was ${be.vr} now ${te.vr}');
        _log.info('     ${te.tag}');
      } else {
        error = true;
        _log.error('VR Not Equal be.vr($be) != te.vr($te)');
      }
    }
    if (be.length != te.length) {
      if (be.vr == VR.kUN) {
        _log.info('--- ${toDcm(be.code)} was ${be.values.length} '
            'now ${te.values.length}');
      } else {
        error = true;
        _log.error('Length Not Equal be.length(${be.length}) != '
            'te.length(${te.length})');
      }
    }
    if (error) {
      _log.error('***: ${bRoot.map[code]}\n'
          '        !=: ${tRoot.map[code]}');
      _log.info('be: ${be.info}');
      _log.info('te: ${te.info}');
    }
  }

  _log.info('rds0 == rds1: ${bRoot == tRoot}');
  _log.info('rds1 == rds0: ${tRoot == bRoot}');
  return tRoot == bRoot;
}
