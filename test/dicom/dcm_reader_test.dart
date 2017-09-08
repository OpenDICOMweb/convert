// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'package:logger/logger.dart';
import 'package:core/core.dart';
import 'package:dcm_convert/src/byte/tag_reader.dart';
import 'package:system/server.dart';
import 'package:test/test.dart';

void main() {
  String path0 =
      'C:/odw/sdk/test_tools/test_data/TransferUIDs/1.2.840.10008.1.2.5.dcm';
  Server.initialize(name: 'dicom/dcm_reader_test', level: Level.info0);
  group('description', () {

    test("instance ", () {
      RootTagDataset rds = TagReader.readPath(path0);
      log.debug('${rds.info}');
      Entity entity = activeStudies.entityFromDataset(rds);
      log.debug('${entity.info}');
    });
    
  });

}
