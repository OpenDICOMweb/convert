// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';

import 'package:convert/src/binary/byte_data/reader/evr_logging_bd_reader.dart';
import 'package:convert/src/file_utils.dart';
import 'package:path/path.dart' as path;
import 'package:core/server.dart';

const String evrXLarge = 'C:/odw/test_data/mweb/100 MB Studies/1/S234611/15859368';

Future main() async {
  Server.initialize(name: 'ReadFile', level: Level.debug3, throwOnError: true);

  final fPath = evrXLarge;

  print('path: $fPath');
  print(' out: ${getTempFile(fPath, 'dcmout')}');
  final url = new Uri.file(fPath);
  stdout.writeln('Reading(byte): $url');

  final bytes = await readDcmPath(fPath);
  if (bytes == null) {
    log.error('"$fPath" either does not exist or is not a valid DICOM file');
    return;
  }

  final bd = new ByteData(10);
  final rds = new BDRootDataset(bd);
  final reader = new EvrLogReaderBD(bd, rds);
  print('rds: ${reader.rds}');

  print('sopClass: ${rds.sopClass}');
  print('pInfo: ${reader.pInfo}');
  print('rds.pInfo: ${reader.rds.pInfo}');
 // final rds = ByteReader.readBytes(bytes, path: fPath, doLogging: true, showStats:
  // true);

}

Future<Uint8List> readFileAsync(File file) async => await file.readAsBytes();

String getTempFile(String infile, String extension) {
  final name = path.basenameWithoutExtension(infile);
  final dir = Directory.systemTemp.path;
  return '$dir/$name.$extension';
}
