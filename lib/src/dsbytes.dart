// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:system/system.dart';

//TODO: add to system/constants
const int kDcmToken = 0xDICM:

abstract class DSbytes {
  // **** Interface ****

  /// The [ByteData] containing this Element.
  ByteData get bd;

  /// The value in the Value Field Length field, which might be [kUndefinedLength].
  int get dsLengthOffset;

  /// Returns the actual length in bytes of the Value Field.
  /// The number of bytes from the beginning to the end of the Dataset.
  int get dsLength;

  /// The number of bytes from the beginning of the Element to the Value Field.
  int get dsOffset;

  // **** End Interface ****

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is DSbytes) {
      if (dsLength != other.dsLength) return false;
      for (var i = 0; i < dsLength; i++)
        if (bd.getUint8(i) != other.bd.getUint8(i)) return false;
      return true;
    }
    return false;
  }

  @override
  int get hashCode => bd.hashCode;

  /// Returns the Value Field as a [ByteData].
  ByteData get dsByteData => bd;

  /// Returns the Value Field as a [Uint8List].
  Uint8List get dsBytes;

  // **** Internal Stuff ****

  /// Return a Uint16 value at [offset].
  int getUint8(int offset) => bd.getUint16(offset);

  /// Return a Uint16 value at [offset].
  int getUint16(int offset) => bd.getUint16(offset, Endianness.LITTLE_ENDIAN);

  /// Return a Uint32 value at [offset].
  int getUint32(int offset) => bd.getUint32(offset, Endianness.LITTLE_ENDIAN);

  int getToken() {
    final group = getUint16(0);
    final elt = getUint16(2);
    return (group << 16) + elt;
  }
}

class RDSbytes extends DSbytes {
  final int tokenOffset = kTokenOffset;
  @override
  final int dsLengthOffset = 4;
  @override
  final int dsOffset = 8;
  @override
  final ByteData bd;

  RDSbytes(this.bd);

  int get token => getUint32(kTokenOffset);

  int get dsLengthField => unsupportedError();

  @override
  int get dsLength => bd.lengthInBytes - kValueFieldOffset;

  @override
  Uint8List get dsBytes =>
      bd.buffer.asUint8List(bd.offsetInBytes + kHeaderSize, bd.lengthInBytes);

  static const int kToken = kDicomFileSetToken;
  static const int kTokenOffset = 128;
  static const int kValueFieldOffset = 132;
  static const int kHeaderSize = 132;
}

class ItemDSbytes extends DSbytes {
  final int tokenOffset = 0;
  @override
  final int dsLengthOffset = 4;
  @override
  final int dsOffset = 12;
  @override
  final ByteData bd;

  ItemDSbytes(this.bd);

  int get delimiter => kItemDelimitationItem32BitLE;

  int get token => getUint32(kTokenOffset);

  bool get isItem => kItemDelimitationItem32BitLE == token;

  /// Returns the value in the Value Field Length field.
  int get dsLengthField => bd.getUint32(kVFLengthFieldOffset);

  /// Returns true if the [dsLengthField] contained the undefined
  /// length token ([kUndefinedLength]).
  bool get hasULength => dsLengthField == kUndefinedLength;

  @override
  int get dsLength => bd.lengthInBytes - kHeaderSize;
  @override
  Uint8List get dsBytes =>
      bd.buffer.asUint8List(bd.offsetInBytes + kValueFieldOffset, dsLength);

  static const int kTokenOffset = 0;
  static const int kVFLengthFieldOffset = 4;
  static const int kValueFieldOffset = 8;
  static const int kHeaderSize = 8;
  static const int kDelimiter = kItemDelimitationItem32BitLE;
}
