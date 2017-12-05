// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Binayak Behera <binayak.b@mwebware.com> -
// See the AUTHORS file for other contributors.

import 'package:system/server.dart';
import 'package:test/test.dart';

import 'package:dcm_convert/src/binary/base/writer/old/write_buffer.dart';

void main() {
  Server.initialize(name: 'byte_date_writer.dart', level: Level.debug);

  group('ByteDataBuffer', () {
    test('Buffer Growing Test', () {
      final startSize = 1;
      final iterations = 1024 * 1;
      final wb = new WriteBuffer(startSize);
      log
        ..debug('iterations: $iterations')
        ..debug('maxLength: ${wb.maxLength}')
        ..debug('length: ${wb.lengthInBytes}');
      expect(wb.lengthInBytes == startSize, true);
      for (var i = 0; i < iterations - 1; i++) {
        final v = i % 127;
        wb.int8(v);
      }
      log..debug('wb: $wb}\n  length: ${wb.lengthInBytes}');
      expect(wb.lengthInBytes == iterations, true);
    });
  });
}
