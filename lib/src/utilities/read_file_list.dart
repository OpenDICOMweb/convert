// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:common/logger.dart';
import 'package:convertX/dicom_no_tag.dart';

class FileListReader {
  static final Logger log =
      new Logger("read_a_directory", watermark: Severity.warn);
  List<String> paths;
  bool fmiOnly;
  bool throwOnError;
  int printEvery;

  List<String> successful = [];
  List<String> failures = [];
  List<String> badTransferSyntax = [];

  FileListReader(this.paths,
      {this.fmiOnly: false, this.throwOnError = false, this.printEvery = 100});

  int get length => paths.length;
  int get successCount => successful.length;
  int get failureCount => failures.length;
  int get badTSCount => badTransferSyntax.length;

  List<String> get read {
    int count = -1;
    RootByteDataset rds;

    for (String fPath in paths) {
      if (count++ % printEvery == 0)
        log.info('$count good($successCount), bad($failureCount)');
      log.debug('Reading file: $fPath');
      File file = new File(fPath);
      try {
        var bytes = file.readAsBytesSync();
        rds = DcmByteReader.readBytes(bytes, path: fPath, fmiOnly: fmiOnly);
        log.info('${rds.info}');
        if (rds == null) {
          failures.add('"$fPath"');
        } else {
          log.debug('Dataset: ${rds.info}');
          successful.add('"$fPath"');
        }
      } on InvalidTransferSyntaxError catch (e) {
        log.info(e);
        badTransferSyntax.add(fPath);
      } catch (e) {
        log.info('Fail: $fPath');
        failures.add('"$fPath"');
        //   log.info('failures: ${failure.length}');
        if (throwOnError) throw 'Failed: $fPath';
        continue;
      }
      log.reset;
    }

    log.info('Files: $length');
    log.info('Success: $successCount');
    log.info('Failure: $failureCount');
    log.info('Bad TS : $badTSCount');
    log.info('Total: ${successCount + failureCount + badTSCount}');
//  var good = success.join(',  \n');
    var bad = failures.join(',  \n');
    var badTS = badTransferSyntax.join(',  \n');
//  log.info('Good Files: [\n$good,\n]\n');
    log.info('bad Files($failureCount): [\n$bad,\n]\n');
    log.info('bad TS Files($badTSCount): [\n$badTS,\n]\n');

    return failures;
  }
}

/*
RootByteDataset readFMI(Uint8List bytes, [String path = ""]) =>
    DcmByteReader.readBytes(bytes, path: path, fmiOnly: true);

RootByteDataset readRoot(ByteData bd, [String path = ""]) {
  DcmByteReader reader = new DcmByteReader(bd);
  RootByteDataset rds = reader.readRootDataset();
  return rds;
}


*/
/* Enhancement
RootByteDataset readRootNoFMI(Uint8List bytes, [String path = ""]) =>
    DcmByteReader.readBytes(bytes, path: path);
*//*


RootByteDataset readBytes(Uint8List bytes,
        [String path = "", bool fmiOnly = false]) =>
    DcmByteReader.readBytes(bytes, path: path, fmiOnly: fmiOnly);

RootByteDataset readFile(File file, [String path = "", bool fmiOnly = false]) =>
    readBytes(file.readAsBytesSync(), path);

RootByteDataset readPath(String path, [bool fmiOnly = false]) =>
    readFile(new File(path), path);
*/
