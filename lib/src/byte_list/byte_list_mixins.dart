// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

/// Byte Data Getters for reading.
abstract class ByteListGetMixin {
  Endian get endian;
  ByteData get bd;

  int getInt8(int index) => bd.getInt8(index);

  int getUint8(int index) => bd.getUint8(index);

  int getUint16(int index) => bd.getUint16(index, endian);

  int getInt16(int index) => bd.getInt16(index, endian);

  int getUint32(int index) => bd.getUint32(index, endian);

  int getInt32(int index) => bd.getInt32(index, endian);

  int getUint64(int index) => bd.getUint64(index, endian);

  int getInt64(int index) => bd.getInt64(index, endian);

  double getFloat32(int index) => bd.getFloat32(index, endian);

  double getFloat64(int index) => bd.getFloat64(index, endian);
}

/// Byte Data Setters for writing.
abstract class ByteListSetMixin {
  Endian get endian;
  ByteData get bd;

  void setInt8(int index, int value) => bd.setInt8(index, value);

  void setUint8(int index, int value) => bd.setUint8(index, value);

  void setUint16(int index, int value) => bd.setUint16(index, value, endian);

  void setInt16(int index, int value) => bd.setInt16(index, value, endian);

  void setUint32(int index, int value) => bd.setUint32(index, value, endian);

  void setInt32(int index, int value) => bd.setInt32(index, value, endian);

  void setUint64(int index, int value) => bd.setUint64(index, value, endian);

  void setInt64(int index, int value) => bd.setInt64(index, value, endian);

  void setFloat32(int index, double value) => bd.setFloat32(index, value, endian);

  void setFloat64(int index, double value) => bd.setFloat64(index, value, endian);
}

abstract class UnmodifiableByteListMixin {
  int get length;

  void operator []=(int i, int v) =>
      throw new UnsupportedError('Cannot change the length of a fixed-length ByteList');

  set length(int newLength) =>
      throw new UnsupportedError('Cannot change the length of a fixed-length ByteList');
}
