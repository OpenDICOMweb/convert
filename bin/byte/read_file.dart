// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:common/logger.dart';
import 'package:dcm_convert/data/test_files.dart';
import 'package:dcm_convert/dcm.dart';

import 'package:dcm_convert/src/dcm/dcm_reader.dart';

//Urgent: bug with path20
void main() {
  final log = new Logger("io/bin/read_files.dart", watermark: Severity.debug);
  DcmReader.log.watermark = Severity.debug1;

//  var path = 'C:/odw/test_data/mweb/100 MB Studies/1/S234601/15859205';
  // var path = 'C:/odw/test_data/6688/12/0B009D38/0B009D3D/4D4E9A56';
  // IVR with data at end of file
 // var path = 'C:/odw/test_data/mweb/1000+/TRAGICOMIX/TRAGICOMIX/Thorax '
 //  '1CTA_THORACIC_AORTA_GATED (Adult)/A Aorta w-c  3.0  B20f  '
 //      '0-95%/IM-0001-0020.dcm';

  var path = testPaths[0];
  log.config('Byte Reader: $path');
  RootByteDataset rds = ByteReader.readPath(path);
  if (rds == null) {
    log.warn('No Data: $path');
  } else {
    log.info('${rds.parseInfo.info}');
    log.info('Bytes Dataset: ${rds.info}');
  }
}
