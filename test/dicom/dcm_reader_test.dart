// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'package:common/logger.dart';
import 'package:core/core.dart';
import 'package:dcm_convert/src/dcm/tag_reader.dart';
import 'package:test/test.dart';

void main() {
  String path0 =
      'C:/odw/sdk/test_tools/test_data/TransferUIDs/1.2.840.10008.1.2.5.dcm';
  final Logger log = new Logger('dcm_reader_test.dart', watermark: Severity
      .debug);
  group('description', () {

    test("instance ", () {
      RootTagDataset rds = TagReader.readPath(path0);
      log.debug('${rds.info}');
      Entity entity = activeStudies.entityFromDataset(rds);
      log.debug('${entity.info}');
    });
    
  });

}
