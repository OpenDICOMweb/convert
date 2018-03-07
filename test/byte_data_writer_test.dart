// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Binayak Behera <binayak.b@mwebware.com> -
// See the AUTHORS file for other contributors.

import 'package:core/server.dart';
import 'package:test/test.dart';

void main() {
  Server.initialize(name: 'byte_date_writer.dart', level: Level.debug);

  group('ByteDataBuffer', () {

    test('Buffer Growing Test', () {
      final startSize = 1;
      final iterations = 1024 * 1;
      final wb = new WriteBuffer(startSize);
      log.debug('''
iterations: $iterations')
 index: ${wb.wIndex}
 maxLength: ${wb.limit}
''');

      expect(wb.wIndex == startSize, true);
      for (var i = 0; i < iterations - 1; i++) {
        final v = i % 127;
        wb.writeInt8(v);
      }
      log..debug('wb: $wb}\n  length: ${wb.wIndex}');
      expect(wb.wIndex == iterations, true);
    });
  });
}
