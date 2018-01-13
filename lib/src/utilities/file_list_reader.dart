// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:dcm_convert/bd_convert.dart';


class FileListReader {
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
    RootDataset rds;
    final fileNoWidth = getFieldWidth(paths.length);

    bool success;

    var count = -1;
    for (var i = 0; i < paths.length; i++) {
      final path = cleanPath(paths[i]);
      if (count++ % printEvery == 0) {
        final n = getPaddedInt(count, fileNoWidth);
        print('$n good($successCount), bad($failureCount)');
      }

      log.info0('$i Reading: $path ');
      try {
        success = byteReadWriteFileChecked(path, fileNumber: i);
//        log.info0('${rds.pInfo}');
//        log.info0('  Dataset: $rds');
        if (success == false) {
          failures.add('"$path "');
        } else {
          log.debug('Dataset: ${rds.info}');
          successful.add('"$path "');
        }
      } on InvalidTransferSyntax catch (e) {
        log
          ..info0(e)
          ..reset;
        badTransferSyntax.add(path);
      } catch (e) {
        log
          ..info0('Fail: $path ')
          ..reset;
        failures.add('"$path "');
        //   log.info0('failures: ${failure.length}');
        if (throwOnError) throw 'Failed: $path ';
        continue;
      }
      log.reset;
    }

    final bad = failures.join(',  \n');
    final badTS = badTransferSyntax.join(',  \n');
    //  var good = success.join(',  \n');
    log
      ..info0('Files: $length')
      ..info0('Success: $successCount')
      ..info0('Failure: $failureCount')
      ..info0('Bad TS : $badTSCount')
      ..info0('Total: ${successCount + failureCount + badTSCount}')
      ..info0('bad Files($failureCount): [\n$bad,\n]\n')
      ..info0('bad TS Files($badTSCount): [\n$badTS,\n]\n');
    //  ..info0('Good Files: [\n$good,\n]\n');

    return failures;
  }
}
