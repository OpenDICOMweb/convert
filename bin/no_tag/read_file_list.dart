// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/format.dart';
import 'package:common/logger.dart';
import 'package:common/timestamp.dart';
import 'package:convertX/src/dicom_no_tag/dataset.dart';
import 'package:convertX/src/dicom_no_tag/dcm_reader.dart';
import 'package:dictionary/dictionary.dart';
import 'package:path/path.dart' as p;

final Logger log = new Logger("convert/bin/no_tag/read_file_list.dart",
    watermark: Severity.info);

final Formatter format = new Formatter();

class FileListReader {
  List<String> paths;
  bool fmiOnly;
  int printEvery;
  int shortFileThreshold;
  bool throwOnError;
  TransferSyntax targetTS;

  List<String> successful = [];
  List<String> failures = [];
  List<String> badTransferSyntax = [];
  List<String> notTargetTS = [];
  List<String> hasTargetTS = [];
  List<String> shortFiles = [];
  List<String> duplicates = [];
  List<String> shortFileFailures = [];
  Map<String, List<String>> filesByTS = <String, List<String>>{};

  FileListReader(this.paths,
      {this.fmiOnly = true,
      this.printEvery = 25,
      this.shortFileThreshold = 200,
      this.throwOnError = false,
      this.targetTS});

  int get length => paths.length;
  int get successCount => successful.length;
  int get failureCount => failures.length;
  int get badTSCount => badTransferSyntax.length;

  int lastMS = 0;
  double elapsedMS(int elapsed) {
    var v = (elapsed - lastMS) / 1000;
    lastMS = elapsed;
    return v;
  }

  List<String> get read {
    int count = -1;
    var timestamp = new Timestamp();

    log.info('  Started Reading ${paths.length} files at $timestamp ...');
    log.info('  Target TS: $targetTS');
    var timer = new Stopwatch();
    timer.start();

    for (String path in paths) {
      count++;
      if (count % printEvery == 0)
        log.info('$count good($successCount), bad($failureCount) at '
            '${timer.elapsed} '
            'diff: ${elapsedMS(timer.elapsedMilliseconds)}');
      log.debug('Reading file: $path');

      File file = new File(path);
      Uint8List bytes;
      RootDataset rds;
      try {
        bytes = file.readAsBytesSync();
        if (bytes.length < shortFileThreshold) shortFiles.add(path);
        log.debug('fmiOnly: $fmiOnly');
        if (fmiOnly) {
          rds = DcmReader.fmi(bytes, path, targetTS);
        } else {
          rds = DcmReader.rootDataset(bytes, path, targetTS);
        }
        log.debug('$rds');
        if (rds == null) {
          failures.add('"$path"');
          continue;
        }

        // handle TransferSyntax stuff
        TransferSyntax ts = rds.transferSyntax;
        if (ts == null) {
          badTransferSyntax.add(path);
        } else if (targetTS != null) {
          if (ts != targetTS) {
            notTargetTS.add('"$path"');
          } else {
            hasTargetTS.add('"$path"');
          }
        } else {
          log.debug1('TS: $ts, file: "$path"');
          List<String> fList = filesByTS['"${ts.asString}"'];
          if (fList == null) {
            filesByTS['"${ts.asString}"'] = ['"$path"'];
          } else {
            fList.add('"$path"');
          }
        }
        if (rds.hasDuplicates) {
          duplicates.add('"$path"');
        }
        log.debug('Dataset: ${rds.info}');
        successful.add('"$path"');
      } on InvalidTransferSyntaxError catch (e) {
        log.debug(e);
        badTransferSyntax.add(path);
        continue;
      } catch (e) {
        if (bytes.length < shortFileThreshold) {
          shortFileFailures.add(path);
          continue;
        }
        log.error('Fail: $path, $e');
        failures.add('"$path"');
        if (throwOnError) rethrow;
        continue;
      } finally {
        log.reset;
      }
    }
    timer.stop();
    log.info('Elapsed time: ${timer.elapsed}');
    log.info('Files: $length');
    log.info('Success: $successCount');
    log.info('Failure: $failureCount');
    log.info('Files with duplicate elements: ${duplicates.length}');
    log.info('Short file failures: ${shortFileFailures.length}');
    log.info('Bad TS : $badTSCount');
    log.info('Total: ${successCount + failureCount + badTSCount}');
//  var good = success.join(',  \n');
    var bad = failures.join(',  \n');
    var badTS = badTransferSyntax.join(',  \n');
//  log.info('Good Files: [\n$good,\n]\n');
    if (bad.length > 0) log.info('bad Files($failureCount): [\n$bad,\n]\n');
    if (badTS.length > 0)
      log.info('bad TS Files($badTSCount): [\n$badTS,\n]\n');

//    log.info('Files by TS: $filesByTS');

    File outfile = new File('readFile.log');
    for (LogRecord r in log.records) outfile.writeAsStringSync(r.toString());
    return failures;
  }
}

List<String> readDirectory(String path,
    {bool fmiOnly = false,
    TransferSyntax targetTS,
    int printEvery = 100,
    bool throwOnError = false,
    String fileExt = ""}) {
  int fsEntityCount;

  Directory dir = new Directory(path);

  List<FileSystemEntity> fList = dir.listSync(recursive: true);
  fsEntityCount = fList.length;
  log.debug('FSEntity count: $fsEntityCount');

  List<String> files = <String>[];

  /* var timer = new Stopwatch();
  var timestamp = new Timestamp();
  timer.start();
  log.info('   at: $timestamp');
  */

  for (FileSystemEntity fse in fList) {
    if (fse is File) {
      var path = fse.path;
      var ext = p.extension(path);
      if (fileExt == "" || ext == fileExt) {
        //    log.debug('File: $fse');
        files.add(fse.path);
      }
    }
  }
  var reader = new FileListReader(files,
      fmiOnly: fmiOnly,
      printEvery: printEvery,
      throwOnError: throwOnError,
      targetTS: targetTS);
  log.info('Reading ${files.length} from Directory: $path');
  reader.read;
  // timer.stop();
  // log.info('Elapsed time: ${timer.elapsed}');
  return files;
}

RootDataset readBytes(Uint8List bytes, String path,
    {bool fmiOnly = false, TransferSyntax targetTS}) {
  log.debug('fmiOnly: $fmiOnly');
  File file = new File(path);

  Uint8List bytes = file.readAsBytesSync();
  log.info('Reading ${bytes.lengthInBytes} bytes fromfile $path...');
  if (bytes.length < 1024)
    log.warn('***** Short file length: ${bytes.length} - ${file.path}');
  RootDataset rds;

  var timer = new Stopwatch();
  var timestamp = new Timestamp();
  timer.start();
  log.info('   at: $timestamp');
  if (fmiOnly) {
    rds = DcmReader.fmi(bytes, path);
  } else {
    rds = DcmReader.rootDataset(bytes, path);
  }
  timer.stop();
  log.info('Elapsed time: ${timer.elapsed}');

  log.info('TS: ${rds.transferSyntax}');
  log.info('hasValidTS: ${rds.hasValidTransferSyntax}');
  if (rds == null) {
    log.error('Null Instance $path');
    return null;
  }
  log.info('readFile: ${rds.info}');
  if (log.watermark == Severity.info) formatDataset(rds);
  return rds;
}

void formatDataset(RootDataset rds, [bool includePrivate = true]) {
  var z = new Formatter(maxDepth: 146);
  log.debug(rds.format(z));
}

RootDataset readFMI(Uint8List bytes, [String path = ""]) =>
    DcmReader.fmi(bytes);

RootDataset readRoot(Uint8List bytes, [String path = ""]) {
  ByteData bd = bytes.buffer.asByteData();
  DcmReader reader = new DcmReader(bd);
  RootDataset rds = reader.readRootDataset();
  return rds;
}

RootDataset readRootNoFMI(Uint8List bytes, [String path = ""]) {
  ByteData bd = bytes.buffer.asByteData();
  DcmReader decoder = new DcmReader(bd);
  Dataset rds = decoder.xReadDataset();
  return rds;
}

RootDataset readFile(File file, [String path = "", bool fmiOnly = false]) =>
    readBytes(file.readAsBytesSync(), path, fmiOnly: fmiOnly);

RootDataset readPath(String path, {bool fmiOnly = false}) =>
    readFile(new File(path), path, fmiOnly);
