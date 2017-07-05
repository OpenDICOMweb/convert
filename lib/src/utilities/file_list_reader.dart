// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:common/logger.dart';
import 'package:dcm_convert/dicom_no_tag.dart';

class FileListReader {
  static final Logger log =
      new Logger("read_a_directory", watermark: Severity.info);
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

    for (String path  in paths) {
      if (count++ % printEvery == 0)
        log.info('$count good($successCount), bad($failureCount)');
      log.debug('Reading file: $path ');
      File f = new File(path);
      try {
        var bytes = f.readAsBytesSync();
        rds = ByteReader.readBytes(bytes, path: path , fmiOnly: fmiOnly);
        log.info('${rds.parseInfo}');
        log.info('  Dataset: $rds');
        if (rds == null) {
          failures.add('"$path "');
        } else {
          log.debug('Dataset: ${rds.info}');
          successful.add('"$path "');
        }
      } on InvalidTransferSyntaxError catch (e) {
        log.info(e);
        badTransferSyntax.add(path );
      } catch (e) {
        log.info('Fail: $path ');
        failures.add('"$path "');
        //   log.info('failures: ${failure.length}');
        if (throwOnError) throw 'Failed: $path ';
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

