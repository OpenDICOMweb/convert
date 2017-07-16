// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Binayak Behera <binayak.b@mwebware.com> -
// See the AUTHORS file for other contributors.

import 'package:test/test.dart';
import 'package:typed_buffers/typed_buffer.dart';

void main() {
  group("ByteDataBuffer", () {
    test("Buffer Growing Test", () {
      int startSize = 1;
      int iterations = 1024 * 1024;
      var buf = new ByteDataBuffer(startSize);
      print('length: ${buf.lengthInBytes}');
      expect(buf.lengthInBytes == startSize, true);
      for (int i = 0; i < iterations; i++) {
        int v = i % 128;
        buf.setInt8(i, v);
        var x = buf.getInt8(i);
        expect(x == v, true);
      }
      print('length: ${buf.lengthInBytes}');
      expect(buf.lengthInBytes == iterations, true);
    });
  });
}
