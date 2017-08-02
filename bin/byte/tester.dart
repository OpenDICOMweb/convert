// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:common/common.dart';
import 'package:dcm_convert/dcm.dart';
import 'package:dictionary/dictionary.dart';

import 'job_reporter.dart';

var dir0 =
    'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/Thorax 1CTA_THORACIC_AORTA_GATED (Adult)/';
String outRoot0 = 'test/output/root0';
String outRoot1 = 'test/output/root1';
String outRoot2 = 'test/output/root2';
String outRoot3 = 'test/output/root3';
String outRoot4 = 'test/output/root4';

//TODO: modify so that it takes the following arguments
// 1. dirname
// 2. reportIncrement
void main()  {
  List<String> args = ["C:/odw/test_data/sfd/MG", 'd'];
  var parser = getParser();

  var dirName = args[0];
  var dir = toDirectory(dirName);
  if (dir == null) {
    stderr.write('Error: $dirName does not exist');
    exit(-1);
  }
 // var results = parser.parse(args.sublist(1));
//  print('parser: $results');

 // var mode = results['mode'];
//  print('mode: $mode');

  //  var Level = Level.lookup(mode);
  DcmReader.log.level = Level.debug;
  DcmWriter.log.level = Level.info;
  FileListReader.log.level = Level.info;

  JobRunner.job(dir, doReadWriteReadByteFile,
      interval: 10, level: Level.info);
}

String logFileName;
String mode;
ArgParser getParser() => new ArgParser()
  ..addOption('logFile',
      abbr: 'f',
      defaultsTo: '<program>.log',
      callback: (logFile) => logFileName = logFile,
      help: 'The logging mode - defaults to info')
  ..addOption('mode',
      abbr: 'm',
      allowed: ['error', 'config', 'info', 'debug', 'debug1', 'debug2', 'debug'
          '3'],
      defaultsTo: 'info',
      help: 'The logging mode - defaults to info')
  ..addOption('outDir', abbr: 'o',
      defaultsTo: '<inputDir>/output/',
      help: 'The output directory')
  ..addOption('results', abbr: 'r',
      defaultsTo: './results.txt',
      help: 'The results file')
  ..addFlag('silent', abbr: 's',
      defaultsTo: false,
      callback: (silent) => mode = 'error',
      help: 'Silent mode - mode is set to "error"')
  ..addFlag('config', abbr: 'c',
      defaultsTo: false,
      callback: (config) => mode = 'config',
      help: 'mode is set to "config"')
  ..addFlag('info', abbr: 'i',
      defaultsTo: false,
      callback: (info) => mode = 'info',
      help: 'mode is set to "info"')
  ..addFlag('debug', abbr: 'd',
      defaultsTo: false,
      callback: (debug) => mode = 'debug' ,
      help: 'mode is set to "debug"')
  ..addFlag('verbose', abbr: 'v',
      defaultsTo: false,
      callback: (verbose) => mode = 'debug3' ,
      help: 'mode is set to "debug"');



final Logger log = new Logger("doFile", Level.error);

bool doReadWriteReadByteFile(File f,
    [bool throwOnError = true, bool fast = true]) {

  try {
    var reader0 = new ByteReader.fromFile(f);
    RootByteDataset rds0 = reader0.readRootDataset();
    var bytes0 = reader0.buffer;
    log.debug('''$pad  Read ${bytes0.lengthInBytes} bytes
$pad    DS0: ${rds0.info}'
$pad    TS String: ${rds0.transferSyntaxString}
$pad    TS: ${rds0.transferSyntax}
$pad    ${rds0.parseInfo.info}''');

// TODO: move into dataset.warnings.
    ByteElement e = rds0[kPixelData];
    if (e == null) {
      log.warn('$pad ** Pixel Data Element not present');
    } else {
      BytePixelData bpd = e;
      log.debug1('$pad  bpd: ${bpd.info}');
    }

    // Write the Root Dataset
    ByteWriter writer;
    if (fast) {
      // Just write bytes don't write the file
      writer = new ByteWriter(rds0);
    } else {
      writer = new ByteWriter.toPath(rds0, outPath);
    }
    Uint8List bytes1 = writer.writeRootDataset();
    log.debug('$pad    Encoded ${bytes1.length} bytes');

    if (!fast) {
      log.debug('Re-reading: ${bytes1.length} bytes');
    } else {
      log.debug('Re-reading: ${bytes1.length} bytes from $outPath');
    }
    ByteReader reader1;
    if (fast) {
      // Just read bytes not file
      reader1 = new ByteReader(
          bytes1.buffer.asByteData(bytes1.offsetInBytes, bytes1.lengthInBytes));
    } else {
      reader1 = new ByteReader.fromPath(outPath);
    }
    var rds1 = reader1.readRootDataset();
    //   RootByteDataset rds1 = ByteReader.readPath(outPath);
    log.debug('$pad Read ${reader1.bd.lengthInBytes} bytes');
    log.debug1('$pad DS1: $rds1');

    if (rds0.hasDuplicates) log.warn('$pad  ** Duplicates Present in rds0');
    if (rds0.parseInfo != rds1.parseInfo) {
      log.warn('$pad ** ParseInfo is Different!');
      log.debug1('$pad rds0: ${rds0.parseInfo.info}');
      log.debug1('$pad rds1: ${rds1.parseInfo.info}');
      log.debug2(rds0.format(new Formatter(maxDepth: -1)));
      log.debug2(rds1.format(new Formatter(maxDepth: -1)));
    }

    // If duplicates are present the [ElementList]s will not be equal.
    if (!rds0.hasDuplicates) {
      // Compare [ElementList]s
      if (reader0.elementList == writer.elementList) {
        log.debug('$pad ElementLists are identical.');
      } else {
        log.warn('$pad ElementLists are different!');
      }
    }

    // Compare [Dataset]s - only compares the elements in dataset.map.
    var same = (rds0 == rds1);
    if (same) {
      log.debug('$pad Datasets are identical.');
    } else {
      log.warn('$pad Datasets are different!');
    }

    // If duplicates are present the [ElementList]s will not be equal.
    if (!rds0.hasDuplicates) {
      //  Compare the data byte for byte
      var same = bytesEqual(bytes0, bytes1);
      if (same == true) {
        log.debug('$pad Files bytes are identical.');
      } else {
        log.warn('$pad Files bytes are different!');
      }
    }
    if (same) log.info('$pad Success!');
    return same;
  } on ShortFileError {
    log.warn('$pad ** Short File(${f.lengthSync()} bytes): $f');
  } catch (e) {
    log.error(e);
    if (throwOnError) rethrow;
  }
  return false;
}
