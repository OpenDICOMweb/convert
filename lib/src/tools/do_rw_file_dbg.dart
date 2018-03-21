// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';

import 'package:core/core.dart';

import 'package:convert/src/binary/bytes/reader/bd_reader.dart';
import 'package:convert/src/binary/bytes/writer/bd_writer.dart';
import 'package:convert/src/utilities/io_utils.dart';

/// Read a file then write it to a buffer.
bool doRWFileDebug(File f, {bool throwOnError = false, bool fast = true}) {
  log.level = Level.debug3;
  //TODO: improve output
  //  var n = getPaddedInt(fileNumber, width);
  final pad = ''.padRight(5);
  final reader0 = new BDReader.fromFile(f);
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
  log.debug('$pad    Encoded ${bytes1.lengthInBytes} bytes');
  final reader1 = new BDReader.fromBytes(bytes1);
  final rds1 = reader1.readRootDataset();
  showRDS(rds1, reader1);


  // Urgent Jim if file has dups then no test is done. Fix it.
  var same = true;
  String msg;
  // If duplicates are present the [ElementOffsets]s will not be equal.
  if (!rds0.hasDuplicates) {
    //  Compare the data byte for byte
    same = uint8ListEqual(reader0.rb.asUint8List(), reader1.rb.asUint8List());
    msg = (same != true) ? '**** Files were different!!!' : 'Files were identical.';
  } else {
    msg = '''
    	Files were not comparable!!!
    	''';
  }

  log.info('''\n
$f  
  Read ${reader0.rb.lengthInBytes} bytes
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

	final bytes0 = reader.rb.asUint8List();

  log.debug('''\n
Read ${bytes0.lengthInBytes} bytes
     RDS: ${rds.info}'
      TS: ${rds.transferSyntax}
  Pixels: $pdMsg
  $reader
  ${rds.pInfo.summary(rds)}
''');
}
