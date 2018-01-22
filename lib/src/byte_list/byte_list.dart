// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:collection';
import 'dart:typed_data';

import 'package:convert/src/byte_list/byte_list_mixins.dart';

//Urgent: Unit Test

/// [ByteListBase] is the base class of [ByteList]. It provides
/// a read-only byte array
/// that
/// supports
/// both
/// [Uint8List] and [ByteData] interfaces.
abstract class ByteListBase extends ListBase<int> implements Uint8List {
  Uint8List get bytes;
  ByteData get bd;

  Endian get endian;

  ByteData get byteData => bd;

  // *** List<int> interface
  @override
  int operator [](int i) => bytes[i];

  @override
  void operator []=(int i, int v) => bytes[i] = v;

  @override
  bool operator ==(Object other) {
    if (other is ByteList) {
      if (length != other.length) return false;
      for (var i = 0; i < length; i++) if (bytes[i] != other.bytes[i]) return false;
      return true;
    }
    return false;
  }

  @override
  int get hashCode => bd.hashCode;

  @override
  int get length => bd.lengthInBytes;

  @override
  set length(int newLength) => throw new UnsupportedError('Fixed Length ByteList');

  // **** TypedData interface.
  @override
  int get elementSizeInBytes => bd.elementSizeInBytes;
  @override
  int get offsetInBytes => bd.offsetInBytes;
  @override
  int get lengthInBytes => bd.lengthInBytes;
  @override
  ByteBuffer get buffer => bd.buffer;
}

/// This class provides read-only [ByteList] that implements both
/// [Uint8List] and (the readable part of) [ByteData] interfaces.
class UnmodifiableByteList extends ByteListBase
    with UnmodifiableByteListMixin, ByteListGetMixin
    implements Uint8List {
  @override
  final ByteData bd;
  @override
  final Uint8List bytes;
  @override
  final Endian endian;

  UnmodifiableByteList(ByteData bd,
      [int offset = 0, int length, this.endian = kDefaultEndian])
      : bd = _asByteData(bd, offset, length),
        bytes = _getBytes();

  UnmodifiableByteList.from(ByteListBase byteList,
      [int offset = 0, int length, this.endian = kDefaultEndian])
      : bd = _asByteData(byteList.bd, offset, length),
        bytes = _getBytes();

  UnmodifiableByteList.fromUint8List(ByteData bd,
      [int offset = 0, int length, this.endian = kDefaultEndian])
      : bd = _asByteData(bd, offset, length),
        bytes = _getBytes();

  UnmodifiableByteList.fromTypedData(TypedData bd, int offset, int length, this.endian)
      : bd = _asByteData(bd, offset, length),
        bytes = _getBytes();


  static const int k1GB = 1024 * 1024 * 1024;

  /// The Maximum length of a [ByteList].
  static const int kDefaultLimit = 10 * k1GB;

  /// The default initial length of a [ByteList]
  static const int kDefaultInitialLength = 1024;

  /// The default [Endianness] of a [ByteList].
  static const Endianness kDefaultEndian = Endian.little;
}

/// This class provides [ByteList] that implements both the
/// [Uint8List] and the [ByteData] functionality. However,
/// it is different from [ByteData] in that it is closed over
/// the [Endian]ness provided in the constructors. The Setters
/// and Getters do not take an [Endian]ness argument.
class ByteList extends ByteListBase
    with ByteListGetMixin, ByteListSetMixin
    implements Uint8List {
  @override
  final ByteData bd;
  @override
  final Uint8List bytes;
  @override
  final Endian endian;

  factory ByteList(
      [int length = kDefaultInitialLength, Endian endian = kDefaultEndian])
  => (length == null)
      ? new GrowableByteList(length, endian, GrowableByteList.kDefaultLimit)
      : new ByteList._(length, endian);

  factory ByteList.fromByteData(ByteData bd,
          [int offset = 0, int length, Endian endian = kDefaultEndian]) =>
      new ByteList._fromTypedData(bd, offset, length, endian);

  factory ByteList.fromUint8List(Uint8List bytes,
          [int offset = 0, int length, Endian endian = kDefaultEndian]) =>
      new ByteList._fromTypedData(bytes, offset, length, endian);

  ByteList._(int lengthInBytes, this.endian)
      : bd = _newBD(lengthInBytes),
        bytes = _getBytes();

  ByteList._fromTypedData(TypedData td, int offset, int length, this.endian)
      : bd = _asByteData(td, offset ?? td.offsetInBytes, length ?? td.lengthInBytes),
        bytes = _getBytes();

  static UnmodifiableByteList unmodifiableView(ByteListBase byteList,
          [int offset = 0, int length]) =>
      new UnmodifiableByteList.from(byteList, offset, length);

  static const int k1GB = 1024 * 1024 * 1024;
  static const int kDefaultInitialLength = 1024;
  static const int kDefaultLimit = 10 * k1GB;

  /// The default [Endianness] of a [ByteList].
  static const Endianness kDefaultEndian = Endian.little;
}

/// This class provides growable [ByteList] that implements both the
/// [Uint8List] and the [ByteData] functionality. GrowableByteList
/// automatically grows the [ByteList] when Setters have an _index_
/// argument that is greater than [length]. It also has a [length]
/// Setter, which increases the [length] of the [ByteList]. It
/// is different from [ByteData] in that it is closed over
/// the [Endian]ness provided in the constructors. The Setters
/// and Getters do not take an [Endian]ness argument.
abstract class GrowableByteListBase extends ByteListBase
    with ByteListGetMixin, ByteListSetMixin
    implements Uint8List {
  static int kMaximumLength = kDefaultLimit;

  /// The upper bound on the length of this [ByteList]. If [limit]
  /// is _null_ then its length cannot be changed.
  int get limit;
  @override
  Endian get endian;
  ByteData get bd_;
   set bd_(ByteData bd);
  Uint8List get _bytes;
  set bytes_(Uint8List bd);
  int get _length;
  set _length(int length);

  GrowableByteList(
      [int length = kDefaultInitialLength,
      this.endian = kDefaultEndian,
      this.limit = kDefaultLimit])
      : bd_ = _newBD(length ?? kDefaultInitialLength),
        bytes_ = _getBytes(),
        _length = _getLength();

  GrowableByteList.from(GrowableByteList byteList,
      [int offset = 0,
      int length,
      this.endian = kDefaultEndian,
      this.limit = kDefaultLimit])
      : bd_ = _copyTypedData(byteList.bd, offset, length ?? kDefaultInitialLength),
        bytes_ = _getBytes(),
        _length = _getLength();

  GrowableByteList.fromByteData(ByteData bd,
      [int offset = 0,
      int length,
      this.endian = kDefaultEndian,
      this.limit = kDefaultLimit])
      : bd_ = _asByteData(bd, offset, length ?? kDefaultInitialLength),
        bytes_ = _getBytes(),
        _length = _getLength();

  GrowableByteList.fromUint8List(Uint8List bytes,
      [int offset = 0,
      int length,
      this.endian = kDefaultEndian,
      this.limit = kDefaultLimit])
      : bytes_ = _asUint8List(bytes, offset, length ?? bytes.lengthInBytes),
        bd_ = _getByteData(),
        _length = _getLength();

  GrowableByteList.ofSize(int length, this.endian, this.limit)
      : bd_ = _newBD(length),
        bytes_ = _getBytes(),
        _length = _getLength();

  GrowableByteList.fromTypedData(
      TypedData bd, int offset, int length, this.endian, this.limit)
      : bd_ = _asByteData(bd, 0, bd.lengthInBytes),
        bytes_ = _getBytes(),
        _length = _getLength();

  /// Returns _this_ as [ByteData].
  @override
  ByteData get bd => bd_;

  /// Returns _this_ as [Uint8List].
  @override
  Uint8List get bytes => bytes_;

  @override
  int get length => _length;
  @override
  int operator [](int index) {
    if (index >= length) throw new RangeError.index(index, this);
    return bytes_[index];
  }

  @override
  set length(int newLength) =>
      (newLength <= _length) ? _shrinkBuffer(newLength) : growBuffer(newLength);

  @override
  void operator []=(int i, int v) {
    if (i >= bytes_.lengthInBytes) growBuffer();
    bytes_[i] = v;
  }

  @override
  void add(int v) {
    if (_length == bytes_.length) _growBuffer(_length);
    bytes_[_length++] = v;
  }

  @override
  void setRange(int start, int end, Iterable<int> source, [int skipCount = 0]) {
    if (end > _length) throw new RangeError.range(end, 0, _length);
    _setRange(start, end, source, skipCount);
  }

  /// Like [setRange], but with no bounds checking.
  void _setRange(int start, int end, Iterable<int> source, [int skipCount = 0]) {
    bytes_.setRange(start, end, source, skipCount);
    bd_ = bytes_.buffer.asByteData();
    _length = bytes_.length;
  }

  void _shrinkBuffer(int newLength) {
    for (var i = newLength; i < _length; i++) bytes_[i] = 0;
    _length = newLength;
  }

  void _growBuffer(int newLength) {
    final newBuffer = new Uint8List(newLength);
    for (var i = 0; i < _length; i++) newBuffer[i] = bytes_[i];
    bytes_ = newBuffer;
    bd_ = newBuffer.buffer.asByteData();
    _length = newLength;
  }

  /// Creates a new buffer with [length] at least [minCapacity].
  /// and copies the contents of the current buffer into it.
  /// If [minCapacity] is not null and is less or equal to [limit],
  /// the new buffer will have length equal to [minCapacity].
  /// If [minCapacity] is null the new buffer will be twice the size of the
  /// current buffer.
  bool growBuffer([int minCapacity]) {
    if (minCapacity < bytes_.length) return false;
    final newLength = _getNewLength(minCapacity);
    // Don't grow beyond limit
    if (newLength > limit) return false;
    _growBuffer(newLength);
    return true;
  }

  int _getNewLength(int minCapacity) {
    final oldLength = bytes_.lengthInBytes;
    //TODO: See if next line improves performance
    // if (oldLength > k1GB) return oldLength + k1GB;
    return (minCapacity == null) ? oldLength * 2 : minCapacity;
  }

  static const int k1GB = 1024 * 1024 * 1024;
  static const int kDefaultInitialLength = 1024;
  static const int kDefaultLimit = 10 * k1GB;
  static const Endian kDefaultEndian = Endian.little;
}


/// This class provides growable [ByteList] that implements both the
/// [Uint8List] and the [ByteData] functionality. GrowableByteList
/// automatically grows the [ByteList] when Setters have an _index_
/// argument that is greater than [length]. It also has a [length]
/// Setter, which increases the [length] of the [ByteList]. It
/// is different from [ByteData] in that it is closed over
/// the [Endian]ness provided in the constructors. The Setters
/// and Getters do not take an [Endian]ness argument.
class GrowableByteList extends GrowableListBase {
    with ByteListGetMixin, ByteListSetMixin
    implements Uint8List {
  static int kMaximumLength = kDefaultLimit;

  /// The upper bound on the length of this [ByteList]. If [limit]
  /// is _null_ then its length cannot be changed.
  final int limit;
  @override
  final Endian endian;
  ByteData bd_;
  Uint8List bytes_;
  int _length;

  GrowableByteList(
      [int length = kDefaultInitialLength,
        this.endian = kDefaultEndian,
        this.limit = kDefaultLimit])
      : bd_ = _newBD(length ?? kDefaultInitialLength),
        bytes_ = _getBytes(),
        _length = _getLength();

  GrowableByteList.from(GrowableByteList byteList,
                        [int offset = 0,
                          int length,
                          this.endian = kDefaultEndian,
                          this.limit = kDefaultLimit])
      : bd_ = _copyTypedData(byteList.bd, offset, length ?? kDefaultInitialLength),
        bytes_ = _getBytes(),
        _length = _getLength();

  GrowableByteList.fromByteData(ByteData bd,
                                [int offset = 0,
                                  int length,
                                  this.endian = kDefaultEndian,
                                  this.limit = kDefaultLimit])
      : bd_ = _asByteData(bd, offset, length ?? kDefaultInitialLength),
        bytes_ = _getBytes(),
        _length = _getLength();

  GrowableByteList.fromUint8List(Uint8List bytes,
                                 [int offset = 0,
                                   int length,
                                   this.endian = kDefaultEndian,
                                   this.limit = kDefaultLimit])
      : bytes_ = _asUint8List(bytes, offset, length ?? bytes.lengthInBytes),
        bd_ = _getByteData(),
        _length = _getLength();

  GrowableByteList.ofSize(int length, this.endian, this.limit)
      : bd_ = _newBD(length),
        bytes_ = _getBytes(),
        _length = _getLength();

  GrowableByteList.fromTypedData(
      TypedData bd, int offset, int length, this.endian, this.limit)
      : bd_ = _asByteData(bd, 0, bd.lengthInBytes),
        bytes_ = _getBytes(),
        _length = _getLength();

  static const int k1GB = 1024 * 1024 * 1024;
  static const int kDefaultInitialLength = 1024;
  static const int kDefaultLimit = 10 * k1GB;
  static const Endian kDefaultEndian = Endian.little;
}

// *** ByteList Internals

// Note: variables or functions named __<name> should only be used in
//       ByteList Internals section.
TypedData __td;

ByteData _newBD(int length) => __td = new ByteData(length);
ByteData _getByteData() => __td.buffer.asByteData();
Uint8List _getBytes() => __td.buffer.asUint8List();
int _getLength() => __td.lengthInBytes;

ByteData _asByteData(TypedData td, int offset, int length) =>
    __td = td.buffer.asByteData(td.offsetInBytes + offset, length);

Uint8List _asUint8List(TypedData td, int offset, int length) =>
    __td = td.buffer.asUint8List(td.offsetInBytes + offset, length);

// TODO: determine if this conses with a local variable.
// _bytes is used to avoid creating new Uint8List
Uint8List _bytes;
ByteData _copyTypedData(TypedData td, [int offset = 0, int length]) {
  _bytes = td.buffer.asUint8List(offset, length);
  final nBytes = new Uint8List.fromList(_bytes);
  return new ByteData.view(nBytes.buffer);
}
