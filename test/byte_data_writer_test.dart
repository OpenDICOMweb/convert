// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Binayak Behera <binayak.b@mwebware.com> -
// See the AUTHORS file for other contributors.

import 'package:dcm_convert/src/byte/byte_data_buffer.dart';
import 'package:system/server.dart';
import 'package:test/test.dart';
import 'package:system/server.dart';

void main() {
	Server.initialize(name: 'byte_date_writer.dart', level: Level.info0);

  group("ByteDataBuffer", () {
    test("Buffer Growing Test", () {
      int startSize = 1;
      int iterations = 1024 * 1024;
      log.debug('iterations: $iterations');
      var buf = new ByteDataBuffer(startSize);
      log.debug('maxLength: ${buf.maxLength}');
      log.debug('length: ${buf.lengthInBytes}');
      expect(buf.lengthInBytes == startSize, true);
      for (int i = 0; i < iterations - 1; i++) {
        int v = i % 128;
        buf.writeInt8(v);



      }
      log.debug('length: ${buf.lengthInBytes}');
      expect(buf.lengthInBytes == iterations, true);
    });
  });
}
