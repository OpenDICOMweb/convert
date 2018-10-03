// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.
//
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:converter/converter.dart';
import 'package:core/server.dart';
import 'package:path/path.dart' as path;

import '../test_files.dart';

Future main() async {
  Server.initialize(name: 'ReadFiles', level: Level.debug, throwOnError: false);

  for (var i = 0; i < files.length; i++) {
    final fPath = cleanPath(files[i]);

    print('$i: path: $fPath');
    print(' out: ${getTempFile(fPath, 'dcmout')}');
    final url =  Uri.file(fPath);
    stdout.writeln('Reading(byte): $url');

    final reader =  ByteReader.fromPath(fPath, doLogging: false);
    final rds = reader.readRootDataset();

    if (rds == null) {
      log.warn('Invalid DICOM file: $fPath');
    } else {
      if (reader.pInfo != null) {
        final infoPath = '${path.withoutExtension(fPath)}.info';
        log.info('infoPath: $infoPath');
        final sb =  StringBuffer('${reader.pInfo.summary(rds)}\n')
          ..write('Bytes Dataset: ${rds.summary}');
         File(infoPath).writeAsStringSync(sb.toString());
        log.debug(sb.toString());

        final formatter =  Formatter(maxDepth: -1);
        final fmtPath = '${path.withoutExtension(fPath)}.fmt';
        log.info('fmtPath: $fmtPath');
        final fmtOut = rds.format(formatter);
         File(fmtPath).writeAsStringSync(sb.toString());
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

