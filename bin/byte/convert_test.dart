// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:dcm_convert/src/dcm/convert_byte_to_tag.dart';
import 'package:dictionary/dictionary.dart';

const String path0 = 'C:/odw/test_data/6688/12/0B009D38/0B009D3D/4D4E9A56';
const String path1 = 'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
const String path2 = 'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
const String path3 = 'C:/odw/test_data/mweb/100 MB Studies/1/S234611/15859368';
const String path4 = 'C:/odw/test_data/mweb/100 MB Studies';

Logger log = new Logger('convert_test', watermark: Severity.info);

void main() {

  for (String path in [path0]) {
    try {
      File f = new File(path);
/*      FileResult r = readFileWithResult(f, fmiOnly: false);
      if (r == null) {
        log.config('No Result');
      } else {
        log.config('${r.info}');
      }*/
      convert(f, fmiOnly: false);
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}

bool convert(File file, {int reps = 1, bool fmiOnly = false}) {
  log.debug2('Reading: $file');
  Uint8List bytes0 = file.readAsBytesSync();
  log.debug('Convert Reading: $file with ${bytes0.lengthInBytes} bytes');
  if (bytes0 == null) return false;

  RootByteDataset byteRoot =
      DcmByteReader.readBytes(bytes0, path: file.path, fast: true);
  if (byteRoot == null) return false;

  RootTagDataset tRoot = convertByteDSToTagDS(byteRoot);

  // Test dataset equality
  if (byteRoot.length != tRoot.length) throw "";
  if (byteRoot.total != tRoot.total) throw "";
  log.info('rds0 Length: ${byteRoot.length} Total: ${byteRoot.total}');
  log.info('rds1 Length: ${tRoot.length} Total: ${tRoot.total}');
  log.info('Byte DS: ${byteRoot.info}');
  log.info('Tag DS${tRoot.info}');

  // write out converted dataset and compare the bytes
  //Urgent: make this work
  // Uint8List bytes1 = DcmWriter.writeBytes(rds1, reUseBD: true);
//  if (bytes1 == null) return false;
//  bytesEqual(bytes0, bytes1);

  if (byteRoot.parent != tRoot.parent) {
    log.error('Parents Not equal');
    log.warn('  rds0.parent: ${byteRoot.parent}');
    log.warn('  rds1.parent: ${tRoot.parent}');
  }
  if (byteRoot.hadULength != tRoot.hadULength) {
    log.error('hadULength Not equal');
    log.info('  rds0.hadULength: ${byteRoot.hadULength}');
    log.info('  rds1.hadULength: ${tRoot.hadULength}');
  }
  if (byteRoot.length != tRoot.length) {
    log.error('map.length Not equal');
    log.info('  rds0.map.length: ${byteRoot.length}');
    log.info('  rds1.map.length: ${tRoot.length}');
  }
  if (byteRoot.total != tRoot.total) {
    log.error('total Not equal');
    log.info('  rds0.total: ${byteRoot.total}');
    log.info('  rds1.total: ${tRoot.total}');
  }

  for (int code in byteRoot.map.keys) {
    ByteElement be = byteRoot.map[code];
    TagElement te = tRoot.map[code];

    bool error = false;
    if (be.code != te.code) {
      error = true;
      log.error('Code Not Equal be.code(${be.code}) != te.code(${te.code})');
    }
    if (be.vr != te.vr) {
      if (be.vr == VR.kUN && be.isPrivate) {
           log.info('--- ${toDcm(be.code)} was ${be.vr} now ${te.vr}');
           log.info('     ${te.tag}');
      } else {
        error = true;
        log.error('VR Not Equal be.vr(${be.vr}) != te.vr(${te.vr})');
      }
    }
    if (be.values.length != te.values.length) {
      if (be.vr == VR.kUN) {
        log.info('--- ${toDcm(be.code)} was ${be.values.length} '
            'now ${te.values.length}');
      } else {
        error = true;
        log.error('Length Not Equal be.length(${be.length}) != '
            'te.length(${te.length})');
      }
    }
    if (error) {
      log.error('***: ${byteRoot.map[code]}\n'
          '        !=: ${tRoot.map[code]}');
      log.info('be: ${be.info}');
      log.info('te: ${te.info}');
    }
  }

  log.info('rds0 == rds1: ${byteRoot == tRoot}');
  log.info('rds1 == rds0: ${tRoot == byteRoot}');
  return tRoot == byteRoot;
}
