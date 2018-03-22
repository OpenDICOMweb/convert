// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:core/server.dart';

import 'package:convert/data/test_files.dart';
import 'package:convert/convert.dart';
import 'package:convert/tools.dart';

// ignore_for_file: only_throw_errors, avoid_catches_without_on_clauses

/// A Program that reads a [File], decodes it into a [RootDataset],
/// and then converts that into a [TagRootDataset].
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
  final pathList = [path1];

  TagRootDataset rds;
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

TagRootDataset convertPath(String path, {int reps = 1, bool fmiOnly = false}) {
  final f = pathToFile(path, mustExist: true);
  return convertFile(f, reps: reps, fmiOnly: fmiOnly);
}

TagRootDataset convertFile(File file, {int reps = 1, bool fmiOnly = false}) {
  final log = new Logger('convertFile', Level.info)
    ..level = Level.warn1
    ..debug2('Reading: $file');
  final bdRds = ByteReader.readFile(file);
  print('TS: ${bdRds.transferSyntax}');
  log
    ..debug('bRoot.isRoot: ${bdRds.isRoot}')
    ..debug1(bdRds.pInfo.summary(bdRds));
  if (bdRds == null) return null;

  final tRoot = DatasetConverter.fromBDRootDataset(bdRds);
  // Test dataset equality
  log..info0('tRoot: $tRoot')..info0('Byte DS: $bdRds')..info0('Tag DS$tRoot');
  if (bdRds.length != tRoot.length) {
    log
      ..error('map.length Not equal')
      ..info0('  rds0.map.length: ${bdRds.length}')
      ..info0('  rds1.map.length: ${tRoot.length}');
    throw 'Unequal Top Level';
  }
  if (bdRds.total != tRoot.total) {
    log
      ..error('total Not equal')
      ..info0('  rds0.total: ${bdRds.total}')
      ..info0('  rds1.total: ${tRoot.total}');
    throw 'Unequal Total';
  }

  log..info0('Byte DS: ${bdRds.summary}')..info0(' Tag DS: ${tRoot.summary}');
  // write out converted dataset and compare the bytes
  // Urgent: make this work
  // Uint8List bytes1 = DcmWriter.writeBytes(rds1, reUseBD: true);
  //  if (bytes1 == null) return false;
  //  bytesEqual(bytes0, bytes1);

  if (bdRds.parent != tRoot.parent) {
    log
      ..error('Parents Not equal')
      ..warn0('  rds0.parent: ${bdRds.parent}')
      ..warn0('  rds1.parent: ${tRoot.parent}');
  }
  if (bdRds.hadULength != tRoot.hadULength) {
    log
      ..error('hadULength Not equal')
      ..info0('  rds0.hadULength: ${bdRds.hadULength}')
      ..info0('  rds1.hadULength: ${tRoot.hadULength}');
  }

  for (var e in bdRds.elements) {
    final code = e.code;
    final be = bdRds.lookup(code);
    final te = tRoot.lookup(code);

    var error = false;
    if (be.code != te.code) {
      error = true;
      log.error('Code Not Equal be.code(${be.code}) != te.code(${te.code})');
    }
    if (be.vrIndex != te.vrIndex) {
      if (be.vrIndex == kUNIndex && be.isPrivate) {
        log
          ..info0('--- ${dcm(be.code)} was ${be.vrIndex} now ${te.vrIndex}')
          ..info0('     ${te.tag}');
      } else {
        error = true;
        log.error('VR Not Equal be.vr($be) != te.vr($te)');
      }
    }
    if (be.length != te.length) {
      if (be.vrIndex == kUNIndex) {
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
        ..error('***: ${bdRds.lookup(code)}\n'
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
