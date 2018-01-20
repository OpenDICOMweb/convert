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

  int getInt8(int rIndex) => bd.getInt8(rIndex);

  int getUint8(int rIndex) => bd.getUint8(rIndex);

  int getUint16(int rIndex) => bd.getUint16(rIndex, endian);

  int getInt16(int rIndex) => bd.getInt16(rIndex, endian);

  int getUint32(int rIndex) => bd.getUint32(rIndex, endian);

  int getInt32(int rIndex) => bd.getInt32(rIndex, endian);

  int getUint64(int rIndex) => bd.getUint64(rIndex, endian);

  int getInt64(int rIndex) => bd.getInt64(rIndex, endian);

  double getFloat32(int rIndex) => bd.getFloat32(rIndex, endian);

  double getFloat64(int rIndex) => bd.getFloat64(rIndex, endian);
}

/// Byte Data Setters for writing.
abstract class ByteListSetMixin {
  Endian get endian;
  ByteData get bd;

  void setInt8(int wIndex, int value) => bd.setInt8(wIndex, value);

  void setUint8(int wIndex, int value) => bd.setUint8(wIndex, value);

  void setUint16(int wIndex, int value) => bd.setUint16(wIndex, value, endian);

  void setInt16(int wIndex, int value) => bd.setInt16(wIndex, value, endian);

  void setUint32(int wIndex, int value) => bd.setUint32(wIndex, value, endian);

  void setInt32(int wIndex, int value) => bd.setInt32(wIndex, value, endian);

  void setUint64(int wIndex, int value) => bd.setUint64(wIndex, value, endian);

  void setInt64(int wIndex, int value) => bd.setInt64(wIndex, value, endian);

  void setFloat32(int wIndex, double value) => bd.setFloat32(wIndex, value, endian);

  void setFloat64(int wIndex, double value) => bd.setFloat64(wIndex, value, endian);
}
