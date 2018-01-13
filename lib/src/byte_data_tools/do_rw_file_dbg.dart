// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:dcm_convert/src/binary/byte_data/reader/bd_reader.dart';
import 'package:dcm_convert/src/binary/byte_data/writer/bd_writer.dart';
import 'package:dcm_convert/src/byte_data_tools/job_utils.dart';

/// Read a file then write it to a buffer.
bool doRWFileDebug(File f, {bool throwOnError = false, bool fast = true}) {
  log.level = Level.debug3;
  //TODO: improve output
  //  var n = getPaddedInt(fileNumber, width);
  final pad = ''.padRight(5);

  final Uint8List bytes = f.readAsBytesSync();
  final bd = bytes.buffer.asByteData();
  final reader0 = new BDReader(bd);
  final rds0 = reader0.readRootDataset();
  showRDS(rds0, reader0);

  // TODO: move into dataset.warnings.
  final e = rds0[kPixelData];
  if (e == null) {
    log.info1('$pad ** Pixel Data Element not present');
  } else {
    log.debug1('$pad  e: ${e.info}');
  }

  // Write the Root Dataset
  log.info('Writing $rds0');
  BDWriter writer;
  if (fast) {
    // Just write bytes don't write the file
    writer = new BDWriter(rds0);
  } else {
    final outPath = getTempFile(f.path, 'dcmout');
    writer = new BDWriter.toPath(rds0, outPath);
  }
  final bytes1 = writer.writeRootDataset();
  log.debug('$pad    Encoded ${bytes1.length} bytes');

  final bd1 = bytes1.buffer.asByteData();
  final reader1 = new BDReader(bd1);
  final rds1 = reader1.readRootDataset();
  showRDS(rds1, reader1);


  // Urgent Jim if file has dups then no test is done. Fix it.
  var same = true;
  String msg;
  // If duplicates are present the [ElementOffsets]s will not be equal.
  if (!rds0.hasDuplicates) {
    //  Compare the data byte for byte
    same = bytesEqual(reader0.bd.buffer.asUint8List(), reader1.bd.buffer.asUint8List());
    msg = (same != true) ? '**** Files were different!!!' : 'Files were identical.';
  } else {
    msg = '''
    	Files were not comparable!!!
    	''';
  }

  log.info('''\n
$f  
  Read ${reader0.bd.lengthInBytes} bytes
    DS0: ${rds0.info}'
    ${rds0.transferSyntax}
    $reader0
  Wrote ${bytes1.lengthInBytes} bytes
    $msg
    $writer
    
  ''');
  return same;
}

void showRDS(BDRootDataset rds,  BDReader reader) {
	final e = rds[kPixelData];
	final pdMsg =  (e == null)
	? ' ** Pixel Data Element not present'
			: e.info;

	final bytes0 = reader.bd.buffer.asUint8List();

  log.debug('''\n
Read ${bytes0.lengthInBytes} bytes
     RDS: ${rds.info}'
      TS: ${rds.transferSyntax}
  Pixels: $pdMsg
  $reader
  ${rds.pInfo.summary(rds)}
''');
}
