// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/convert.dart';
import 'package:convert/src/utilities/io_utils.dart';
import 'package:path/path.dart' as path;
import 'package:core/server.dart';

import 'package:convert/src/json/writer/fast_writer.dart';

const String k6684Dir = 'C:/acr/odw/test_data/6684';

const String k6684x0 =
    'C:/acr/odw/test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';

const String k6684x1 =
    'c:/odw/test_data/6684/2017/5/13/1/8D423251/B0BDD842/E52A69C2';

Formatter z = new Formatter(maxDepth: -1);

Future main() async {
  Server.initialize(name: 'ReadFile', level: Level.debug3, throwOnError: true);

  const fPath = k6684x0;
  final z = new Formatter.basic();

  print('path: $fPath');
  print(' out: ${getTempFile(fPath, 'dcmout')}');
  final url = new Uri.file(fPath);
  stdout.writeln('Reading(byte): $url');

  final bytes = readPath(fPath);
  if (bytes == null) {
    log.error('"$fPath" either does not exist or is not a valid DICOM file');
    return;
  } else {
    stdout.writeln('  Length in bytes: ${bytes.lengthInBytes}');
  }

  final bdRDS =
      ByteReader.readBytes(bytes, path: fPath, doLogging: true, showStats: true);
  if (bdRDS == null) {
    log.warn('Invalid DICOM file: $fPath');
  } else {
    print('${bdRDS.summary}');
  }

  const outPath = 'out.json';
  final writer0 = new FastJsonWriter(bdRDS, outPath, separateBulkdata: true);
  final out = writer0.write();

  print('output length: ${out.length}');
  print('output length: ${out.length ~/ 1024}K');
  await new File(outPath).writeAsString(out);

  final tagRds = DatasetConverter.fromBDRootDataset(bdRDS);
  print('tagRDS Summary: ${tagRds.summary}');

  final removed = <Element>[];
  for (var code in deIdRemoveCodes) {
    final eList = tagRds.deleteAll(code, recursive: true);
    if (eList.isNotEmpty) {
//      print(z.fmt('Removed: ${eList.length}', eList));
      removed.addAll(eList);
    }
  }
  print(z.fmt('Total Removed: ${removed.length}', removed));
  print('tagRDS Summary: ${tagRds.summary}');

  const deIdPath = 'deid.json';
  final writer1 = new FastJsonWriter(tagRds, deIdPath, separateBulkdata: true);
  final deid = writer1.write();
  print('output length: ${deid.length}');
  print('output length: ${deid.length ~/ 1024}K');
  await new File(deIdPath).writeAsString(deid);
  print('done');
}

Future<Uint8List> readFileAsync(File file) async => await file.readAsBytes();

String getTempFile(String infile, String extension) {
  final name = path.basenameWithoutExtension(infile);
  final dir = Directory.systemTemp.path;
  return '$dir/$name.$extension';
}
