// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:convert/bytes/bytes.dart';

void main() {
  group('Bytes Tests', () {
    test('Test getters and initial zeros', () {
      final count = 12;

      // Check initialized with zeros
      for (var i = 0; i < count; i++) {
        final bytes = new Bytes(count);
        expect(bytes.endian == Endian.little, true);

        expect(bytes.elementSizeInBytes == 1, true);
        expect(bytes.offsetInBytes == 0, true);
        expect(bytes.buffer == bytes.bd.buffer, true);
        expect(bytes.length == count, true);
        expect(bytes.lengthInBytes == count, true);
        expect(bytes.length == bytes.lengthInBytes, true);

        expect(bytes.hashCode is int, true);

        // Verify that all elements are zero
        for (var i = 0; i < bytes.length; i++) {
          expect(bytes[i] == 0, true);
          expect(bytes.getUint8(i) == 0, true);
        }
      }
    });

    test('Test List interface: initial zeroed, equality, hashCode', () {
      final count = 255;
      final a = new Bytes(count);
      final b = new Bytes(count);

      // Check initialized with zeros
      for (var i = 0; i < count; i++) {
        expect(a[i] == 0, true);
        expect(b[i] == 0, true);
        expect(a[i] == b[i], true);

        expect(a.getUint8(i) == 0, true);
        expect(b.getUint8(i) == 0, true);
        expect(a.getUint8(i) == b.getUint8(i), true);

        expect(a == b, true);
        expect(a.hashCode == b.hashCode, true);
      }

      // Check byte Setters
      for (var i = 0; i < count; i++) {
        a[i] = count;
        b[i] = count;

        expect(a[i] == count, true);
        expect(b[i] == count, true);
        expect(a[i] == b[i], true);

        expect(a.getUint8(i) == count, true);
        expect(b.getUint8(i) == count, true);
        expect(a.getUint8(i) == b.getUint8(i), true);

        expect(a == b, true);
        expect(a.hashCode == b.hashCode, true);
      }
    });

    //TODO: finish tests
    test('Test List Int16', () {
      final loopCount = 100;
      final length = 0xFF;

      for (var i = 0; i < loopCount; i++) {
        final a = new Bytes(0xFF * Bytes.kInt16Size);
        assert(a.length == 0xFF * Bytes.kInt16Size, true);

        for (var i = 0, j = Bytes.kInt8MinValue;
            i <= 0xFF;
            i++, j++) {
          print('i: $i, j: $j');
          a.setInt16(i, j);
          expect(a.getInt16(i) == j, true);
        }
        for (var i = 0, j = Bytes.kInt8MinValue;
            j < Bytes.kInt16MaxValue; i++, j++)
          expect(a.getInt16(i) == j, true);
      }
    });
  });
}
