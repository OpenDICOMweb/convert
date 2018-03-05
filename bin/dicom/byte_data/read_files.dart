// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/server.dart';
import 'package:convert/convert.dart';
import 'package:path/path.dart' as path;

import 'package:convert/data/test_files.dart';
import 'package:convert/src/utilities/dicom_file_utils.dart';
import 'package:convert/src/utilities/io_utils.dart';

const String k6684x0 =
    'C:/acr/odw/test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';

const String k6684x1 =
    'c:/odw/test_data/6684/2017/5/13/1/8D423251/B0BDD842/E52A69C2';

//Urgent: bug with path20
Future main() async {
  Server.initialize(name: 'ReadFile', level: Level.debug2, throwOnError: true);
  // for (var i = 0; i < 1; i++) {
  for (var i = 0; i < testPaths2.length; i++) {
    final fPath = k6684x0;

    print('$i: path: $fPath');
    print(' out: ${getTempFile(fPath, 'dcmout')}');
    final url = new Uri.file(fPath);
    stdout.writeln('Reading(byte): $url');

    final bytes = readPath(fPath);
    if (bytes == null) {
      log.error('"$fPath" is not a valid DICOM file');
      return;
    }

    final doLogging = system.level > Level.debug;
    final rds =
        BDReader.readBytes(bytes, path: fPath, doLogging: doLogging, showStats: true);

    if (rds == null) {
      log.warn('Invalid DICOM file: $fPath');
    } else {
      if (rds.pInfo != null) {
        final infoPath = '${path.withoutExtension(fPath)}.info';
        log.info('infoPath: $infoPath');
        final sb = new StringBuffer('${rds.pInfo.summary(rds)}\n')
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

//        print(rds.format(z));
      } else {
        print('${rds.summary}');
      }
    }
  }
}

Future<Uint8List> readFileAsync(File file) async => await file.readAsBytes();

