// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

/// Byte Data Getters for reading.
abstract class ByteDataGetMixin {
  ByteData get bd;
  
  int getInt8(int rIndex) => bd.getInt8(rIndex);

  int getUint8(int rIndex) => bd.getUint8(rIndex);

  int getUint16(int rIndex, [Endianness endian = Endian.little]) =>
      bd.getUint16(rIndex, endian);

  int getInt16(int rIndex, [Endianness endian = Endian.little]) =>
      bd.getInt16(rIndex, endian);

  int getUint32(int rIndex, [Endianness endian = Endian.little]) =>
      bd.getUint32(rIndex, endian);

  int getInt32(int rIndex, [Endianness endian = Endian.little]) =>
      bd.getInt32(rIndex, endian);

  int getUint64(int rIndex, [Endianness endian = Endian.little]) =>
      bd.getUint64(rIndex, endian);

  int getInt64(int rIndex, [Endianness endian = Endian.little]) =>
      bd.getInt64(rIndex, endian);

  double getFloat32(int rIndex, [Endianness endian = Endian.little]) =>
      bd.getFloat32(rIndex, endian);

  double getFloat64(int rIndex, [Endianness endian = Endian.little]) =>
      bd.getFloat64(rIndex, endian);
}

/// Byte Data Setters for writing.
abstract class ByteDataSetMixin {
  ByteData get bd;
  
  void setInt8(int wIndex, int value, [Endianness endian = Endian.little]) =>
      bd.setInt8(wIndex, value);

  void setUint8(int wIndex, int value, [Endianness endian = Endian.little]) =>
      bd.setUint8(wIndex, value);

  void setUint16(int wIndex, int value, [Endianness endian = Endian.little]) =>
      bd.setUint16(wIndex, value, endian);

  void setInt16(int wIndex, int value, [Endianness endian = Endian.little]) =>
      bd.setInt16(wIndex, value, endian);

  void setUint32(int wIndex, int value, [Endianness endian = Endian.little]) =>
      bd.setUint32(wIndex, value, endian);

  void setInt32(int wIndex, int value, [Endianness endian = Endian.little]) =>
      bd.setInt32(wIndex, value, endian);

  void setUint64(int wIndex, int value, [Endianness endian = Endian.little]) =>
      bd.setUint64(wIndex, value, endian);

  void setInt64(int wIndex, int value, [Endianness endian = Endian.little]) =>
      bd.setInt64(wIndex, value, endian);

  void setFloat32(int wIndex, double value, [Endianness endian = Endian.little]) =>
      bd.setFloat32(wIndex, value, endian);

  void setFloat64(int wIndex, double value, [Endianness endian = Endian.little]) =>
      bd.setFloat64(wIndex, value, endian);
}
