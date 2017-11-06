// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Binayak Behera <binayak.b@mwebware.com> -
// See the AUTHORS file for other contributors.

import 'package:system/server.dart';
import 'package:test/test.dart';

import 'package:dcm_convert/src/binary/base/writer/byte_writer.dart';

void main() {
  Server.initialize(name: 'byte_date_writer.dart', level: Level.info0);

  group('ByteDataBuffer', () {
    test('Buffer Growing Test', () {
      final startSize = 1;
      final iterations = 1024 * 1024;
      final buf = new ByteWriter(startSize);
      log
        ..debug('iterations: $iterations')
        ..debug('maxLength: ${buf.maxLength}')
        ..debug('length: ${buf.lengthInBytes}');
      expect(buf.lengthInBytes == startSize, true);
      for (var i = 0; i < iterations - 1; i++) {
        final v = i % 128;
        buf.int8(v);
      }
      log.debug('length: ${buf.lengthInBytes}');
      expect(buf.lengthInBytes == iterations, true);
    });
  });
}
