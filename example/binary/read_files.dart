// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:converter/converter.dart';
import 'package:core/server.dart';
import 'package:path/path.dart' as path;

import 'test_files.dart';

Future main() async {
  Server.initialize(name: 'ReadFiles', level: Level.debug, throwOnError: true);

  for (var i = 0; i < files.length; i++) {
    final fPath = files[i];

    print('$i: path: $fPath');
    print(' out: ${getTempFile(fPath, 'dcmout')}');
    final url = new Uri.file(fPath);
    stdout.writeln('Reading(byte): $url');

    final reader = new ByteReader.fromPath(fPath, doLogging: false);
    final rds = reader.readRootDataset();

    if (rds == null) {
      log.warn('Invalid DICOM file: $fPath');
    } else {
      if (reader.pInfo != null) {
        final infoPath = '${path.withoutExtension(fPath)}.info';
        log.info('infoPath: $infoPath');
        final sb = new StringBuffer('${reader.pInfo.summary(rds)}\n')
          ..write('Bytes Dataset: ${rds.summary}');
        new File(infoPath)..writeAsStringSync(sb.toString());
        log.debug(sb.toString());

        //   final formatter = new Formatter.withIndenter(-1, Indenter.basic);
        final formatter = new Formatter(maxDepth: -1);
        final fmtPath = '${path.withoutExtension(fPath)}.fmt';
        log.info('fmtPath: $fmtPath');
        final fmtOut = rds.format(formatter);
        new File(fmtPath)..writeAsStringSync(sb.toString());
        log.debug(fmtOut);
      } else {
        print('${rds.summary}');
      }
    }
  }
}

Future<Uint8List> readFileAsync(File file) async => await file.readAsBytes();

String getTempFile(String infile, String extension) {
  final name = path.basenameWithoutExtension(infile);
  final dir = Directory.systemTemp.path;
  return '$dir/$name.$extension';
}

