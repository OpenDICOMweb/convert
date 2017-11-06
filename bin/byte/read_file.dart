// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dcm_convert/byte_convert.dart';
import 'package:path/path.dart' as path;
import 'package:system/server.dart';

const String dcmDir = 'C:/odw/test_data/sfd/MG/DICOMDIR';
const String evrLarge = 'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
const String evrULength = 'c:/odw/test_data/6684/2017/5/13/1/8D423251/B0BDD842/E52A69C2';
const String evrX = 'C:/odw/test_data/mweb/ASPERA/Clean_Pixel_test_data/Sop/1.2.840'
    '.10008.5.1.4.1.1.88.67.dcm ';
// Defined and Undefined datasets
const String evrXLarge = 'C:/odw/test_data/mweb/100 MB Studies/1/S234611/15859368';
const String evrOWPixels = 'C:/odw/test_data/IM-0001-0001.dcm';

const String ivrClean = 'C:/odw/test_data/sfd/MR/PID_BREASTMR/1_DICOM_Original/'
    'EFC524F2.dcm';
const String ivrCleanMR = 'C:/odw/test_data/mweb/100 MB Studies/MRStudy/'
    '1.2.840.113619.2.5.1762583153.215519.978957063.99.dcm';

const String evrDataAfterPixels =
    'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';

//Urgent: bug with path20
Future main() async {
  Server.initialize(name: 'ReadFile', level: Level.debug3, throwOnError: true);

  final fPath = dcmDir;

  print('path: $fPath');
  print(' out: ${getTempFile(fPath, 'dcmout')}');
  final url = new Uri.file(fPath);
  stdout.writeln('Reading(byte): $url');

  final file = new File(fPath);
  final bytes = await readFileAsync(file);
  final rds = ByteReader.readBytes(bytes, showStats: true);
  if (rds == null) {
    log.warn('Invalid DICOM file: $fPath');
  } else {
    if (false || rds.parseInfo != null) {
      final infoPath = '${path.withoutExtension(fPath)}.info';
      log.info('infoPath: $infoPath');
      final sb = new StringBuffer('${rds.parseInfo.info}\n')
        ..write('Bytes Dataset: ${rds.summary}');
      new File(infoPath)..writeAsStringSync(sb.toString());
      log.debug(sb.toString());

      final z = new Formatter.withIndenter(5, Indenter.basic);
      final fmtPath = '${path.basenameWithoutExtension(fPath)}.fmt';
      log.info('fmtPath: $fmtPath');
      final fmtOut = rds.format(z);
      new File(fmtPath)..writeAsStringSync(sb.toString());
      log.debug(fmtOut);

      print(rds.format(z));
    } else {
      print('${rds.summary}');
    }
  }
}

Future<Uint8List> readFileAsync(File file) async => await file.readAsBytes();

String getTempFile(String infile, String extension) {
  final name = path.basenameWithoutExtension(infile);
  final dir = Directory.systemTemp.path;
  return '$dir/$name.$extension';
}
