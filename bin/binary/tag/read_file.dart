// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:io';

import 'package:core/server.dart';
import 'package:convert/convert.dart';
import 'package:path/path.dart' as path;

// This import contains a bunch of predefined paths
// import 'package:convert/data/test_files.dart';

const String f6684a =
    'C:/acr/odw/test_data/6684/2017/5/12/16/05223B30/05223B35/45804B79';

const String x1evr = 'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
const String x2evr = 'C:/acr/odw/test_data/6684/2017/5/12/21/E5C692DB/A108D14E/A619BCE3';
const String x3evr = 'C:/acr/odw/test_data/6684/2017/5/12/16/05223B30/05223B35/45804B79';
const String x4ivr = 'C:/acr/odw/test_data/6684/2017/5/12/16/AF8741DF/AF8741E2/1636525D';
const String x5ivr = 'C:/acr/odw/test_data/6684/2017/5/12/16/AF8741DF/AF8741E2/1636525D ';

void main() {
  Server.initialize(name: 'Tag ReadFile', level: Level.debug, throwOnError: true);

//  const fPath = 'C:/acr/odw/test_data/6684/2017/5/12/16/05223B30/05223B35/45804B79';
  const fPath = x5ivr;
  print('path: $fPath');
  print(' out: ${getTempFile(fPath, 'dcmout')}');
  final url = new Uri.file(fPath);
  stdout.writeln('Reading(byte): $url');

  final bList = new File(fPath).readAsBytesSync();
  final reader = new TagReader(bList, doLogging: true);
  final rds = TagReader.readPath(fPath, doLogging: true);
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

      final z = new Formatter.withIndenter(-1, Prefixer.basic);
      final fmtPath = '${path.withoutExtension(fPath)}.fmt';
      log.info('fmtPath: $fmtPath');
      final fmtOut = rds.format(z);
      new File(fmtPath)..writeAsStringSync(sb.toString());
      log.debug(fmtOut);

//        print(rds.format(z));
    } else {
      print('${rds.summary}');
    }
  }
}
