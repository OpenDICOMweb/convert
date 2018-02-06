// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/dicom.dart';
import 'package:convert/src/utilities/dicom_file_utils.dart';
import 'package:path/path.dart' as path;
import 'package:core/server.dart';

import 'package:convert/src/json/writer/fast_writer.dart';

const String k6684Dir = 'C:/odw/test_data/6684';

const String k6684x0 =
    'C:/odw/test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';

const String k6684x1 =
    'c:/odw/test_data/6684/2017/5/13/1/8D423251/B0BDD842/E52A69C2';

Future main() async {
  Server.initialize(name: 'ReadFile', level: Level.debug3, throwOnError: true);

  final fPath = k6684x0;

  print('path: $fPath');
  print(' out: ${getTempFile(fPath, 'dcmout')}');
  final url = new Uri.file(fPath);
  stdout.writeln('Reading(byte): $url');

  final bytes = await readDcmPath(fPath);
  if (bytes == null) {
    log.error('"$fPath" either does not exist or is not a valid DICOM file');
    return;
  } else {
    stdout.writeln('  Length in bytes: ${bytes.lengthInBytes}');
  }

  final rds =
      BDReader.readBytes(bytes, path: fPath, doLogging: true, showStats: true);
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

      final z = new Formatter.withIndenter(-1, Indenter.basic);
      final fmtPath = '${path.withoutExtension(fPath)}.fmt';
      log.info('fmtPath: $fmtPath');
      final fmtOut = rds.format(z);
      new File(fmtPath)..writeAsStringSync(sb.toString());
      log.debug(fmtOut);

      print(rds.format(z));
    } else {
      print('${rds.summary}');
    }
  }

  final outPath = 'out.json';
  final writer0 = new FastJsonWriter(rds, outPath, separateBulkdata: true);
  final out = writer0.write();

  print('output length: ${out.length}');
  print('output length: ${out.length ~/ 1024}K');
  await new File(outPath).writeAsString(out);

  final tagRds = convertByteDSToTagDS(rds);
  print(tagRds);
  final enrollment = new Date(1980, 1, 1);
  final old = normalizeDates(tagRds, enrollment);
  print('old: $old');

  final deIdPath = 'deid.json';
  final writer1 = new FastJsonWriter(tagRds, deIdPath, separateBulkdata: true);
  final deid = writer1.write();
  print('output length: ${deid.length}');
  print('output length: ${deid.length ~/ 1024}K');
  await new File(outPath).writeAsString(deid);
  print('done');
}

Future<Uint8List> readFileAsync(File file) async => await file.readAsBytes();

String getTempFile(String infile, String extension) {
  final name = path.basenameWithoutExtension(infile);
  final dir = Directory.systemTemp.path;
  return '$dir/$name.$extension';
}
