// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:dataset/tag_dataset.dart';
import 'package:system/server.dart';
import 'package:tag/vr.dart';

import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/byte_convert.dart';
import 'package:dcm_convert/tools.dart';

/// A Program that reads a [File], decodes it into a [ RootDatasetByte ],
/// and then converts that into a [RootDatasetTag].
void main(List<String> args) {
  Server.initialize(name: 'convert', level: Level.info0);

  /// The processed arguments for this program.
  final jobArgs = new JobArgs(args);
  if (jobArgs.showHelp) showHelp(jobArgs);

  //TODO: move this into JobRunner
  print('Dart Version: ${Platform.version}');
  print('${Platform.script}');
  print('Logger Root Level: ${log.level} Log Level: ${log.level}');

  system.log.level = jobArgs.baseLevel;
  // Short circuiting args for testing
  final pathList = [path0];

  RootDatasetTag rds;
  for (var path in pathList) {
    try {
      rds = convertPath(path, fmiOnly: false);
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
  stdout.write(rds.summary);
}

RootDatasetTag convertPath(String path, {int reps = 1, bool fmiOnly = false}) {
  final f = pathToFile(path, mustExist: true);
  return convertFile(f, reps: reps, fmiOnly: fmiOnly);
}

RootDatasetTag convertFile(File file, {int reps = 1, bool fmiOnly = false}) {
  final log = new Logger('convertFile', Level.info)
    ..level = Level.warn1
    ..debug2('Reading: $file');
  final bRoot = ByteReader.readFile(file, fast: true);
  print('TS: ${bRoot.transferSyntax}');
  log
    ..debug('bRoot.isRoot: ${bRoot.isRoot}')
    ..debug1(bRoot.parseInfo.summary(bRoot));
  if (bRoot == null) return null;

  final tRoot = convertByteDSToTagDS<int>(bRoot);
  // Test dataset equality
  log..info0('tRoot: $tRoot')..info0('Byte DS: $bRoot')..info0('Tag DS$tRoot');
  if (bRoot.length != tRoot.length) {
    log
      ..error('map.length Not equal')
      ..info0('  rds0.map.length: ${bRoot.length}')
      ..info0('  rds1.map.length: ${tRoot.length}');
    throw 'Unequal Top Level';
  }
  if (bRoot.total != tRoot.total) {
    log
      ..error('total Not equal')
      ..info0('  rds0.total: ${bRoot.total}')
      ..info0('  rds1.total: ${tRoot.total}');
    throw 'Unequal Total';
  }

  log..info0('Byte DS: ${bRoot.summary}')..info0(' Tag DS: ${tRoot.summary}');
  // write out converted dataset and compare the bytes
  // Urgent: make this work
  // Uint8List bytes1 = DcmWriter.writeBytes(rds1, reUseBD: true);
  //  if (bytes1 == null) return false;
  //  bytesEqual(bytes0, bytes1);

  if (bRoot.parent != tRoot.parent) {
    log
      ..error('Parents Not equal')
      ..warn0('  rds0.parent: ${bRoot.parent}')
      ..warn0('  rds1.parent: ${tRoot.parent}');
  }
  if (bRoot.hadULength != tRoot.hadULength) {
    log
      ..error('hadULength Not equal')
      ..info0('  rds0.hadULength: ${bRoot.hadULength}')
      ..info0('  rds1.hadULength: ${tRoot.hadULength}');
  }

  for (var code in bRoot.elements.keys) {
    final be = bRoot.lookup(code);
    final te = tRoot.lookup(code);

    var error = false;
    if (be.code != te.code) {
      error = true;
      log.error('Code Not Equal be.code(${be.code}) != te.code(${te.code})');
    }
    if (be.vr != te.vr) {
      if (be.vr == VR.kUN && be.isPrivate) {
        log
          ..info0('--- ${dcm(be.code)} was ${be.vr} now ${te.vr}')
          ..info0('     ${te.tag}');
      } else {
        error = true;
        log.error('VR Not Equal be.vr($be) != te.vr($te)');
      }
    }
    if (be.length != te.length) {
      if (be.vr == VR.kUN) {
        log.info0('--- ${dcm(be.code)} was ${be.values.length} '
            'now ${te.values.length}');
      } else {
        error = true;
        log.error('Length Not Equal be.length(${be.length}) != '
            'te.length(${te.length})');
      }
    }
    if (error) {
      log
        ..error('***: ${bRoot.lookup(code)}\n'
            '        !=: ${tRoot.lookup(code)}')
        ..info0('be: ${be.info}')
        ..info0('te: ${te.info}');
    }
  }

  // log.info0('rds0 == rds1: ${bRoot == tRoot}');
  // log.info0('rds1 == rds0: ${tRoot == bRoot}');
  //return tRoot == bRoot;
  return tRoot;
}

/// The help message
void showHelp(JobArgs jobArgs) {
  final msg = '''
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
