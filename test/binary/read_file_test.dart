// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.


import 'package:core/server.dart';
import 'package:test/test.dart';

import 'package:convert/binary.dart';

void main() {
  Server.initialize(name: 'dcm_reader_test', level: Level.info0);
  const path0 =
      'C:/odw/sdk/test_tools/test_data/TransferUIDs/1.2.840.10008.1.2.5.dcm';


  group('Simple binary read', () {

    test('Read file', () {
      final rds = ByteReader.readPath(path0);
      log.debug('${rds.info}');
      final entity = activeStudies.entityFromRootDataset(rds);
      log.debug('${entity.info}');
    });


    
  });

}
