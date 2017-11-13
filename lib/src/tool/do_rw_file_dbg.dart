// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:dataset/byte_dataset.dart';
import 'package:element/byte_element.dart';
import 'package:system/core.dart';

import 'package:dcm_convert/src/binary/byte/read_bytes.dart';
import 'package:dcm_convert/src/binary/byte/write_bytes.dart';
import 'package:dcm_convert/src/tool/job_utils.dart';

/// Read a file then write it to a buffer.
bool doRWFileDebug(File f, {bool throwOnError = false, bool fast = true}) {
  log.level = Level.debug3;
  //TODO: improve output
  //  var n = getPaddedInt(fileNumber, width);
  final pad = ''.padRight(5);

  final Uint8List bytes = f.readAsBytesSync();
  final bd = bytes.buffer.asByteData();
  final reader0 = new ByteDatasetReader(bd, fast: true);
  final rds0 = reader0.read();
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
  ByteDatasetWriter writer;
  if (fast) {
    // Just write bytes don't write the file
    writer = new ByteDatasetWriter(rds0);
  } else {
    final outPath = getTempFile(f.path, 'dcmout');
    writer = new ByteDatasetWriter.toPath(rds0, outPath, fast: true);
  }
  final bytes1 = writer.write();
  log.debug('$pad    Encoded ${bytes1.length} bytes');

  final bd1 = bytes1.buffer.asByteData();
  final reader1 = new ByteDatasetReader(bd1, fast: true);
  final rds1 = reader1.read();
  showRDS(rds1, reader1);


  // Urgent Jim if file has dups then no test is done. Fix it.
  var same = true;
  String msg;
  // If duplicates are present the [ElementOffsets]s will not be equal.
  if (!rds0.hasDuplicates) {
    //  Compare the data byte for byte
    same = bytesEqual(reader0.rootBytes, reader1.rootBytes);
    msg = (same != true) ? '**** Files were different!!!' : 'Files were identical.';
  } else {
    msg = '''
    	Files were not comparable!!!
    	''';
  }

  log.info('''\n
$f  
  Read ${reader0.rootBytes.lengthInBytes} bytes
    DS0: ${rds0.info}'
    ${rds0.transferSyntax}
    ${reader0.info}
  Wrote ${bytes1.lengthInBytes} bytes
    $msg
    ${writer.info}
    
  ''');
  return same;
}

void showRDS(RootDatasetByte rds,  ByteDatasetReader reader) {

	final PixelData e = rds[kPixelData];
	final pdMsg =  (e == null)
	? ' ** Pixel Data Element not present'
			: e.info;

	final bytes0 = reader.rootBytes;

  log.debug('''\n
Read ${bytes0.lengthInBytes} bytes
     RDS: ${rds.info}'
      TS: ${rds.transferSyntax}
  Pixels: $pdMsg
  ${reader.info}
  ${rds.parseInfo.summary(rds)}
''');
}
