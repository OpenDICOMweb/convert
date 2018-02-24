// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/dicom.dart';
import 'package:convert/src/utilities/dicom_file_utils.dart';
import 'package:convert/src/utilities/convert_to_dataset_by_group.dart';
import 'package:path/path.dart' as path;
import 'package:core/server.dart';

import 'package:convert/src/json/writer/fast_writer.dart';

const String k6684Dir = 'C:/odw/test_data/6684';

const String k6684x0 =
    'C:/odw/test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';

const String k6684x1 =
    'c:/odw/test_data/6684/2017/5/13/1/8D423251/B0BDD842/E52A69C2';

Formatter z = new Formatter.basic();

Future main() async {
  Server.initialize(name: 'ReadFile', level: Level.debug2, throwOnError: true);

  final fPath = k6684x0;

  ///  final z = new Formatter.basic();

  log..debug('path: $fPath')..debug(' out: ${getTempFile(fPath, 'dcmout')}');
  final url = new Uri.file(fPath);
  stdout.writeln('Reading(byte): $url');

  final bytes = await readDcmPath(fPath);
  if (bytes == null) {
    log.error('"$fPath" either does not exist or is not a valid DICOM file');
    return;
  } else {
    stdout.writeln('  Length in bytes: ${bytes.lengthInBytes}');
  }

  final bdRDS =
      BDReader.readBytes(bytes, path: fPath, doLogging: false, showStats: true);
  if (bdRDS == null) {
    log.warn('Invalid DICOM file: $fPath');
  } else {
    if (bdRDS.pInfo != null) {
      final infoPath = '${path.withoutExtension(fPath)}.info';
      log.info('infoPath: $infoPath');
      final sb = new StringBuffer('${bdRDS.pInfo.summary(bdRDS)}\n')
        ..write('Bytes Dataset: ${bdRDS.summary}');
      new File(infoPath)..writeAsStringSync(sb.toString());
      log.debug(sb.toString());

      final fmtPath = '${path.withoutExtension(fPath)}.fmt';
      log.info('fmtPath: $fmtPath');
      final fmtOut = bdRDS.format(z);
      new File(fmtPath)..writeAsStringSync(sb.toString());
      log.debug(fmtOut);
    } else {
      log.debug('bdRDS: ${bdRDS.summary}');
      //   log.debug('bdRDS: ${bdRDS.format(z)}');
    }
  }

  final outPath = 'out.json';
  log.debug('Writing "$outPath"...');
  final writer0 = new FastJsonWriter(bdRDS, outPath, separateBulkdata: true);
  final out = writer0.write();
  await new File(outPath).writeAsString(out);
  log
    ..debug('Wrote JSON: $outPath')
    ..debug('  Output length: ${out.length}')
    ..debug('  Output length: ${out.length ~/ 1024}K\n');

  log.debug('Converting bdRds($bdRDS) to TagDataset ...');
  final tagRds0 = convertBDDSToTagDS(bdRDS);
  print('tagRds0: ${tagRds0.info}');
  print('tagRds0: ${tagRds0.format(z)}');
  log
    ..debug('Converted tagRds0: $tagRds0')
    ..debug(' ${tagRds0.summary}');

  final converter = new ConvertToDatasetByGroup(bdRDS);
  final privateRds = converter.find();
  log
    ..debug('privateRds: ${privateRds.format(z)}')
    ..debug('privateRds: ${privateRds.summary}');

  var count = 0;
  // Urgent: where not working
  tagRds0.where((e) {
    if (e.isPrivate) {
      count++;
      log.debug('** P: $e');
      return true;
    } else {
      return false;
    }
  });
  log.debug('Private count: $count');

  final pList = tagRds0.findAllPrivate();
  log
    ..debug('Private Top Level: ${pList.length}')
    ..debug(z.fmt('Private: ${pList.length}', pList));

  final dList = tagRds0.deleteAllPrivate(recursive: true);
  log.debug('Private removed: ${dList.length}');
//  log.debug(z.fmt('Private removed: ${dList.length}', dList));

  if (pList.length != dList.length)
    log.debug('**** Private ${pList.length} '
        'and Removed ${dList.length} not equal.');

//  log.debug(z('Total Private Removed: ${dList.length}', private));
//  log.debug('tagRDS Summary: ${tagRds.summary}');

  count = 0;
  tagRds0.where((e) {
    if (e.isPrivate) {
      log.debug('** P: $e');
      return true;
    } else {
      return false;
    }
  });
  log.debug('Private count: $count');

  final deIdPath = 'deid.json';
  final writer1 = new FastJsonWriter(tagRds0, deIdPath, separateBulkdata: true);
  final deid = writer1.write();
  await new File(deIdPath).writeAsString(deid);
  log
    ..debug('Wrote DeIdJSON: $deIdPath')
    ..debug('output length: ${deid.length}')
    ..debug('output length: ${deid.length ~/ 1024}K')
    ..debug('done');
}

Future<Uint8List> readFileAsync(File file) async => await file.readAsBytes();

String getTempFile(String infile, String extension) {
  final name = path.basenameWithoutExtension(infile);
  final dir = Directory.systemTemp.path;
  return '$dir/$name.$extension';
}
