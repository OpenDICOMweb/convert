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
import 'package:dcm_convert/tools.dart';
import 'package:dictionary/dictionary.dart';

/// A Program that reads a [File], decodes it into a [RootByteDataset],
/// and then converts that into a [RootTagDataset].
void main(List<String> args) {
  /// The processed arguments for this program.
  JobArgs jobArgs;

  /// The help message
  void showHelp() {
    var msg = '''
Usage: converter <input-file> [<options>]

Opens the <input-file> and then:
  1. Decodes (reads) the data in a byte array (file) into a 
     Root Byte Dataset [0]
  2. Converts the Root Byte Dataset to a Root Tag Dataset
  3. Prints a summary of the Root Tag Dataset to stdout
 
Options:
${jobArgs.parser.usage}
''';
    stdout.write(msg);
    exit(0);
  }

  Logger log = new Logger('convert_test', Level.info);
  print('log level: ${log.level}');

/* Urgent: move to io_utils with wrapper.
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.name}[${rec.level.name}]: ${rec.time}: ${rec.message}');
  });
*/

  print('Dart Version: ${Platform.version}');
  print('${Platform.script}');
  print('Logger Root Level: ${log.rootLevel} Log Level: ${log.level}');

  RootTagDataset rds;
  for (String path in [path0]) {
    try {
      rds = convertFile(path, fmiOnly: false);
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
  stdout.write(rds.summary);
}

RootTagDataset convertFile(dynamic file, {int reps = 1, bool fmiOnly = false}) {
  File f = toFile(file, mustExist: true);
  Logger log = new Logger('convertFile', Level.info);
  log.level = Level.warn1;
  log.debug2('Reading: $file');
  RootByteDataset bRoot = ByteReader.readFile(f, fast: true);
  log.debug('bRoot.isRoot: ${bRoot.isRoot}');
  log.debug1(bRoot.parseInfo.info);
  if (bRoot == null) return null;

  RootTagDataset tRoot = convertByteDSToTagDS(bRoot);
  log.info('tRoot: $tRoot');

  // Test dataset equality
  log.info('Byte DS: $bRoot');
  log.info('Tag DS$tRoot');
  if (bRoot.length != tRoot.length) throw "Unequal Top Level";
  if (bRoot.total != tRoot.total) throw "Unequal Total";

  log.info('Byte DS: ${bRoot.summary}');
  log.info(' Tag DS: ${tRoot.summary}');
  // write out converted dataset and compare the bytes
  //Urgent: make this work
  // Uint8List bytes1 = DcmWriter.writeBytes(rds1, reUseBD: true);
//  if (bytes1 == null) return false;
//  bytesEqual(bytes0, bytes1);

  if (bRoot.parent != tRoot.parent) {
    log.error('Parents Not equal');
    log.warn0('  rds0.parent: ${bRoot.parent}');
    log.warn0('  rds1.parent: ${tRoot.parent}');
  }
  if (bRoot.hadULength != tRoot.hadULength) {
    log.error('hadULength Not equal');
    log.info('  rds0.hadULength: ${bRoot.hadULength}');
    log.info('  rds1.hadULength: ${tRoot.hadULength}');
  }
  if (bRoot.length != tRoot.length) {
    log.error('map.length Not equal');
    log.info('  rds0.map.length: ${bRoot.length}');
    log.info('  rds1.map.length: ${tRoot.length}');
  }
  if (bRoot.total != tRoot.total) {
    log.error('total Not equal');
    log.info('  rds0.total: ${bRoot.total}');
    log.info('  rds1.total: ${tRoot.total}');
  }

  for (int code in bRoot.map.keys) {
    ByteElement be = bRoot.map[code];
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
        log.error('VR Not Equal be.vr($be) != te.vr($te)');
      }
    }
    if (be.length != te.length) {
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
      log.error('***: ${bRoot.map[code]}\n'
          '        !=: ${tRoot.map[code]}');
      log.info('be: ${be.info}');
      log.info('te: ${te.info}');
    }
  }

  // log.info('rds0 == rds1: ${bRoot == tRoot}');
  // log.info('rds1 == rds0: ${tRoot == bRoot}');
  //return tRoot == bRoot;
  return tRoot;
}
