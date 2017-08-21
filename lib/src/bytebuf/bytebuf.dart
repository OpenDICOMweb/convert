// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:number/number.dart';
import 'package:string/ascii.dart';
import 'package:system/system.dart';

//TODO:
// 1. Put all index checking and moving into same section and eliminate redundancy
// 2. Aggregate errors in one section
// 3. Consolidate RangeErrors into internal methods
// 4. Should we change 'ListView' to 'View' since by definition a 'View' is always of a [List].

// TODO:
//  * Finish documentation
//  * Make buffers Unmodifiable
//  * Make buffer pools, both heap and non-heap and use check accessable.
//  * Make buffers growable
//  * Make a LoggingByteBuf
//  * create a big_endian_bytebuf.
//  * Can the Argument Errors and RangeErrors be merged
//  * reorganize:
//    ** ByteBufBase contains global static, general constructors and private fields and getters
//    ** ByteBufReader extends Base with Read constructors, methods and readOnly getter...
//    ** ByteBuf extends Reader with read and write constructors, methods...

/// A Byte Buffer implementation based on Netty's ByteBuf.
///
/// A [ByteBuf] uses an underlying [Uint8List] to contain byte data,
/// where a "byte" is an unsigned 8-bit integer.  The "capacity" of the
/// [ByteBuf] is always equal to the [length] of the underlying [Uint8List].
//TODO: finish description

const kKB = 1024 * 1024;
const kMB = kKB * 1024;
const kGB = kMB * 1024;
const int kMaxCapacity = kGB;

/// A skeletal implementation of a buffer.
class ByteBuf {
  static const int defaultLengthInBytes = 1 * kKB;
  static const int defaultMaxCapacity = 1 * kGB;
  static const int maxMaxCapacity = 2 * kGB;
  static const Endianness endianness = Endianness.LITTLE_ENDIAN;

  /// The complete buffer from 0 to [_bytes].[lengthInBytes].
  final Uint8List _bytes;

  //TODO: document these
  ByteData _bd;
  int _readIndex;
  int _writeIndex;
  int _readIndexMark;

  //*** Constructors ***

  ByteBuf([int lengthInBytes = defaultLengthInBytes])
      : _bytes = _getBytes(lengthInBytes),
        _readIndex = 0,
        _writeIndex = 0 {
    _bd = _bytes.buffer.asByteData();
  }

  ByteBuf._(this._bytes, this._readIndex, this._writeIndex);

  ByteBuf.reader(Uint8List bytes, [int index = 0, int lengthInBytes])
      : _bytes = _getByteView(bytes, index, lengthInBytes, lengthInBytes),
        _readIndex = 0 {
    _writeIndex = _bytes.lengthInBytes;
    _bd = _bytes.buffer.asByteData();
  }

  ByteBuf.writer([int lengthInBytes = defaultLengthInBytes])
      : _bytes = new Uint8List(_validateLengthIB(lengthInBytes, lengthInBytes)),
        _readIndex = 0 {
    _writeIndex = 0;
    _bd = _bytes.buffer.asByteData();
  }

  ByteBuf.from(ByteBuf buf,
      [int readIndex = 0, int writeIndex, int lengthInBytes = kKB])
      : _bytes = _copyBytes(buf._bytes, readIndex, lengthInBytes),
        _readIndex = 0,
        _writeIndex = _validateWriteIndex(0, writeIndex, lengthInBytes) {
    _bd = _bytes.buffer.asByteData();
  }

  ByteBuf.fromList(List<int> list) : _bytes = new Uint8List.fromList(list) {
    _readIndex = 0;
    _writeIndex = _bytes.lengthInBytes;
    _bd = _bytes.buffer.asByteData();
  }

  //TODO: is _writeIndex correct
  ByteBuf.view(ByteBuf buf, [int index = 0, int lengthInBytes])
      : _bytes = _getByteView(buf._bytes, index, lengthInBytes) {
    _readIndex = 0;
    _writeIndex = _bytes.lengthInBytes;
    _bd = _bytes.buffer.asByteData();
  }

  //**** Methods that Return new [ByteBuf]s.  ****

  /// Creates a new [ByteBuf] that is a view of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  ByteBuf readView(int index, int lengthInBytes) =>
      _getBufView(_bytes, index, lengthInBytes, lengthInBytes);

  /// Creates a new [ByteBuf] that is a view of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  ByteBuf writeView(int index, int lengthInBytes) =>
      _getBufView(_bytes, 0, 0, lengthInBytes);

  /// Creates a new [ByteBuf] that is a [sublist] of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  ByteBuf sublist(int start, int end) =>
      _getByteBuf(start, end - start, end - start);

  //*** Operators ***

  /// Returns the byte (Uint8) value at [index]
  int operator [](int index) => getUint8(index);

  /// Sets the byte (Uint8) at [index] to [value].
  void operator []=(int index, int value) {
    setUint8(index, value);
  }

  @override
  bool operator ==(Object object) =>
      (this == object) ||
      ((object is ByteBuf) && (this.hashCode == object.hashCode));

  //*** Internal Utilities ***

  //TODO: decide if access to this is needed
  //ByteData get bd => _bd;

  /// Returns the length of the underlying [Uint8List].
  int get lengthInBytes => _bytes.lengthInBytes;


  /// Sets the [readIndex] to [index].  If [index] is not valid a [RangeError] is thrown.
  ByteBuf _setReadIndex(int index) {
    if (index < 0 || index > _writeIndex)
      throw new RangeError(
          "readIndex: $index (expected: 0 <= readIndex <= writeIndex($_writeIndex))");
    _readIndex = index;
    return this;
  }

  /// Sets the [writeIndex] to [index].  If [index] is not valid a [RangeError] is thrown.
  ByteBuf _setWriteIndex(int index) {
    if (index < _readIndex || index > lengthInBytes)
      throw new RangeError(
          "writeIndex: $index (expected: readIndex($_readIndex) <= writeIndex <= lengthInBytes($lengthInBytes))");
    _writeIndex = index;
    return this;
  }

  /* Flush
  /// Sets the [rIndex] and [wIndex].  If either is not valid a [RangeError] is thrown.
  ByteBuf _setIndices(int rIndex, int wIndex) {
    if (rIndex < 0 || rIndex > wIndex || wIndex > lengthInBytes)
      throw new RangeError("readIndex: $rIndex, writeIndex: $wIndex "
          "(expected: 0 <= readIndex <= writeIndex <= lengthInBytes($lengthInBytes))");
    _readIndex = rIndex;
    _writeIndex = wIndex;
    return this;
  }
  */

  //*** Getters and Setters ***

  Uint8List get bytes => _bytes;
  ByteData get byteData => _bd;

  //TODO: verify that this is good enough
  @override
  int get hashCode => _bytes.hashCode;

  /// Returns the current value of the index where the next read will start.
  int get readIndex => _readIndex;

  /// Sets the [readIndex] to [index].
  set readIndex(int index) {
    _setReadIndex(index);
  }

  /// Returns the current value of the index where the next write will start.
  int get writeIndex => _writeIndex;

  /// Sets the [writeIndex] to [index].
  set writeIndex(int index) {
    _setWriteIndex(index);
  }

  /// Returns [true] if [this] is a read only.
  bool get isReadOnly => false;

  //TODO: create subclass
  /// Returns an unmodifiable version of [this].
  /// Note: an UnmodifiableByteBuf can still be read.
  //BytebBufBase get asReadOnly => new UnmodifiableByteBuf(this);

  //*** ByteBuf [_bytes] management

  //Flush or replace lengthInBytes with this.
  /// Returns the number of bytes (octets) this buffer can contain.
  //int get capacity => _bytes.lengthInBytes;

  /// _Deprecated: use [readCapacity] instead._
  @deprecated
  int get readableBytes => _writeIndex - _readIndex;

  /// Returns the number of readable bytes (octets) left in this buffer.
  int get readCapacity => _writeIndex - _readIndex;

  /// _Deprecated: use [writeCapacity] instead._
  @deprecated
  int get writableBytes => lengthInBytes - _writeIndex;

  /// Returns the number of writable bytes (octets) left in this buffer.
  int get writeCapacity => lengthInBytes - _writeIndex;

  /// Returns [true] if there are readable bytes available, false otherwise.
  bool get isReadable => _readIndex < _writeIndex;

  /// Returns [true] if there are no readable bytes available, false otherwise.
  bool get isNotReadable => !isReadable;

  /// Returns [true] if there are writable bytes available, false otherwise.
  bool get isWritable => lengthInBytes > _writeIndex;

  /// Returns [true] if there are no writable bytes available, false otherwise.
  bool get isNotWritable => !isWritable;

  int get readIndexMark => _readIndexMark;
  int get setReadIndexMark => _readIndexMark = _readIndex;
  int get resetReadIndexMark => _readIndex = _readIndexMark;

  //TODO: move to ByteBuf
  /// The current readIndex as a string.
  String get rrr => 'R@$_readIndex';

  /// The current writeIndex as a string.
  String get www => 'W@$_writeIndex';

  /// The beginning of reading an [Element] or [Item].
  String get rbb => '> $rrr';

  /// In the middle of reading an [Element] or [Item]
  String get rmm => '| $rrr';

  /// The end of reading an [Element] or [Item]
  String get ree => '< $rrr';

  /// The beginning of reading an [Element] or [Item].
  String get wbb => '> $www';

  /// In the middle of reading an [Element] or [Item]
  String get wmm => '| $www';

  /// The end of reading an [Element] or [Item]
  String get wee => '< $www';

  /// Returns [true] if there are [lengthInBytes] available to read, false otherwise.
  bool hasReadable(int lengthInBytes) => readCapacity >= lengthInBytes;

  /// Returns [true] if there are [nBytes] available to write, false otherwise.
  bool hasWritable(int nBytes) => writeCapacity >= nBytes;
  //*** Buffer Management Methods ***

  /// _Deprecated: use [hasReadable] instead._
  @deprecated
  void checkReadableBytes(int minimumReadableBytes) {
    if (minimumReadableBytes < 0)
      throw new ArgumentError(
          "minimumReadableBytes: $minimumReadableBytes (expected: >= 0)");
    _checkReadableBytes(minimumReadableBytes);
  }

  /// _Deprecated: use [hasWritable] instead._
  @deprecated
  void checkWritableBytes(int minimumWritableBytes) {
    if (minimumWritableBytes < 0)
      throw new ArgumentError(
          "minimumWritableBytes: $minimumWritableBytes (expected: >= 0)");
    _checkWritableBytes(minimumWritableBytes);
  }

  // Ensures that there are at least [minReadableBytes] available to read.
  /// _Deprecated: use [hasReadable] instead._
  @deprecated
  void ensureReadable(int minReadableBytes) {
    if (minReadableBytes < 0)
      throw new ArgumentError(
          "minWritableBytes: $minReadableBytes (expected: >= 0)");
    if (minReadableBytes > readableBytes)
      throw new RangeError("writeIndex($_writeIndex) + "
          "minWritableBytes($minReadableBytes) exceeds lengthInBytes($lengthInBytes): $this");
    return;
  }

  // Ensures that there are at least [minWritableBytes] available to write.
  /// _Deprecated: use [hasWritable] instead._
  @deprecated
  void ensureWritable(int minWritableBytes) {
    if (minWritableBytes < 0)
      throw new ArgumentError(
          "minWritableBytes: $minWritableBytes (expected: >= 0)");
    if (minWritableBytes > writableBytes)
      throw new RangeError("writeIndex($_writeIndex) + "
          "minWritableBytes($minWritableBytes) exceeds lengthInBytes($lengthInBytes): $this");
    return;
  }

  /// Reset the [readIndex] and [writeIndex] to 0; however, if [hasZeros]
  /// is [true] the contents of the [Uint8List] are set to 0;
  ByteBuf clear({bool hasZeros: false}) {
    if (hasZeros) clearBytes(0, lengthInBytes);
    _readIndex = _writeIndex = 0;
    return this;
  }

  /// Zeros out the bytes from [start] to [end].  Returns [true] if successful
  /// and [false] otherwise.  Does not modify the [readIndex] or [writeIndex].
  ByteBuf clearBytes(int start, [int end]) {
    if (end == null) end = lengthInBytes;
    if (((start < 0) || (start >= lengthInBytes)) ||
        ((end <= start) || (end > _bytes.lengthInBytes)))
      throw new RangeError('Invalid start($start) or end($end)');
    //TODO: could be optimized to use [Uint64List] to zero out.
    //      Note: it might have to be on a 32 or 64 bit boundary.
    for (int i = start; i < end; i++) _bytes[i] = 0;
    return this;
  }

  //*** Read Methods ***

  /// Returns the number of zeros read.
  int getZeros(int index, int length) {
    int count = 0;
    for (int i = 0; i < length; i++) {
      var val = getUint8(index);
      if (val != 0) return count - 1;
    }
    return 0;
  }

  /// Return [true] if [length] Uint8 values
  /// equal to zero (0) were read, false otherwise.
  int readZeros(int length) {
    var v = getZeros(_readIndex, length);
    _readIndex += length;
    return v;
  }

  ///Returns a [bool] value.  [bool]s are encoded as a single byte
  ///where 0 is false and any other value is true.
  bool getBoolean(int index) => getUint8(index) != 0;

  /// Reads a [bool] value.  [bool]s are encoded as a single byte
  /// where 0 is false and any other value is true,
  /// and advances the [readIndex] by 1.
  bool readBoolean() => readUint8() != 0;

  /// Returns an [List] of [bool].
  List<bool> getBooleanList(int index, int length) {
    _checkReadIndex(index, length);
    List<bool> list = new List(length);
    for (int i = 0; i < length; i++) list[i] = getBoolean(i);
    return list;
  }

  /// Reads and Returns a [List] of [bool], and advances
  /// the [readIndex] by the number of byte read.
  List<bool> readBooleanList(int length) {
    _checkReadIndex(_readIndex, length);
    var list = getBooleanList(_readIndex, length);
    _readIndex += length;
    return list;
  }

  //*** Int8 Read Methods ***

  /// Returns an signed 8-bit integer.
  int getInt8(int index) {
    _checkReadIndex(index, 1);
    return _bd.getInt8(index);
  }

  /// Read and returns an signed 8-bit integer.
  int readInt8() {
    var v = getInt8(_readIndex);
    _readIndex++;
    return v;
  }

  final Int8List emptyInt8List = new Int8List(0);

  /// Returns an [Int8List] of signed 8-bit integers.
  Int8List getInt8List(int index, int lengthIB) {
    if (lengthIB == 0) return emptyInt8List;
    _checkReadIndex(index, lengthIB);
    return _bytes.buffer.asInt8List(index, lengthIB).sublist(0);
  }

  /// Reads and Returns an [Int8List] of signed 8-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Int8List readInt8List(int length) {
    var list = getInt8List(_readIndex, length);
    _readIndex += length;
    return list;
  }

  /// Returns an [Int8List] view of signed 8-bit integers.
  ///
  /// Note: DICOM File Format (PS3.10) are always aligned
  /// on 2-byte boundary. So, no alignment check is needed.
  Int8List getInt8View(int index, int lengthIB) {
    if (lengthIB == 0) return emptyInt8List;
    _checkReadIndex(index, lengthIB);
    return _bytes.buffer.asInt8List(index, lengthIB);
  }

  /// Returns an [Int8List] view of signed 8-bit integers.
  Int8List readInt8View(int index, int lengthIB) {
    var list = getInt8View(index, lengthIB);
    _readIndex += lengthIB;
    return list;
  }

  //*** Uint8 get, Read Methods ***

  /// Returns an unsigned 8-bit integer.
  int getUint8(int index) {
    _checkReadIndex(index, 1);
    return _bd.getUint8(index);
  }

  /// Reads and returns an unsigned 8-bit integer.
  int readUint8() {
    var v = getUint8(_readIndex);
    _readIndex++;
    return v;
  }

  final Uint8List emptyUint8List = new Uint8List(0);

  /// _Internal_: Returns an [Uint8List] of unsigned 8-bit integers.
  Uint8List _getUint8List(int index, int length) {
    if (length == 0) return emptyUint8List;
    return _bytes.sublist(index, index + length);
  }

  /// Returns an [Uint8List] of unsigned 8-bit integers.
  Uint8List getUint8List(int index, int lengthInBytes) {
    _checkReadIndex(index, lengthInBytes);
    return _getUint8List(index, lengthInBytes);
  }

  /// Reads and Returns an [Uint8List] of unsigned 8-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Uint8List readUint8List(int lengthInBytes) {
    Uint8List list = getUint8List(_readIndex, lengthInBytes);
    _readIndex += lengthInBytes;
    return list;
  }

  /// Returns an [Uint8List] view of unsigned 8-bit integers.
  ///
  /// Note: DICOM File Format (PS3.10) are always aligned on
  /// 2-byte boundary. So, no alignment check is needed.
  Uint8List getUint8View(int index, int length) {
    if (length == 0) return emptyUint8List;
    _checkReadIndex(index, length);
    return _getUint8List(index, length);
  }

  /// Returns an [Uint8List] view of unsigned 8-bit integers.
  Uint8List readUint8View(int lengthInBytes) {
    var list = getUint8View(_readIndex, lengthInBytes);
    _readIndex += lengthInBytes;
    return list;
  }

  //*** Int16 get, Read Methods ***

  /// Returns an unsigned 8-bit integer.
  int getInt16(int index) {
    _checkReadIndex(index, 2);
    return _bd.getInt16(index, endianness);
  }

  /// Returns an unsigned 8-bit integer.
  int readInt16() {
    var v = getInt16(_readIndex);
    _readIndex += 2;
    return v;
  }

  final Int16List emptyInt16List = new Int16List(0);

  /// Returns an [Int16List] of unsigned 8-bit integers.
  Int16List _getInt16List(int index, int length) {
    if (length == 0) return emptyInt16List;
    var list = new Int16List(length);
    for (int i = 0; i < length; i++, index += 2) list[i] = getInt16(index);
    return list;
  }

  /// Returns a [new] [Int16List] of unsigned 8-bit integers.
  /// [length] is the number of elements in the returned list.
  Int16List getInt16List(int index, int length) {
    _checkReadIndex(index, length * 2);
    return _getInt16List(index, length);
  }

  /// Reads and Returns an [Int16List] of signed 16-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Int16List readInt16List(int length) {
    var list = getInt16List(_readIndex, length);
    _readIndex += length * 2;
    return list;
  }

  /// Returns an [Int16List] View of unsigned 8-bit integers in [_bytes].
  ///
  /// Note: DICOM File Format (PS3.10) are always aligned on 2-byte boundary.
  /// So, no alignment check is needed.
  Int16List getInt16View(int index, int length) {
    if (length == 0) return emptyInt16List;
    _checkReadIndex(index, length * 2);
    return _bytes.buffer.asInt16List(index, length);
  }

  /// Returns an [Int16List] view of unsigned 8-bit integers.
  Int16List readInt16View(int length) {
    var view = getInt16View(_readIndex, length);
    _readIndex += length * 2;
    return view;
  }

  //*** Uint16 get, Read Methods ***

  /// Returns an unsigned 16-bit integer.
  int getUint16(int index) {
    _checkReadIndex(index, 2);
    return _bd.getUint16(index, endianness);
  }

  /// Returns an unsigned 16-bit integer.
  int readUint16() {
    var v = getUint16(_readIndex);
    _readIndex += 2;
    return v;
  }

  final Uint16List emptyUint16List = new Uint16List(0);

  /// _Internal_: Returns a [new] [Uint16List] of unsigned 16-bit integers.
  Uint16List _getUint16List(int index, int length) {
    if (length == 0) return emptyUint16List;
    var list = new Uint16List(length);
    for (int i = 0; i < length; i++) {
      list[i] = getUint16(index + i * 2);
      //  print('$i: ${list[i]}');
    }
    return list;
  }

  /// Returns an [Uint16List] of unsigned 16-bit integers.
  /// [length] is the number of elements in the returned list.
  Uint16List getUint16List(int index, int length) {
    //  print('getUint16: $index: $length');
    _checkReadIndex(index, length * 2);
    return _getUint16List(index, length);
  }

  /// Reads and Returns an [Uint16List] of unsigned 16-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Uint16List readUint16List(int length) {
    var list = getUint16List(_readIndex, length);
    _readIndex += length * 2;
    //  print('** $list');
    return list;
  }

  /// Returns an [Uint16List] View of unsigned 16-bit integers in [_bytes].
  ///
  /// Note: DICOM File Format (PS3.10) are always aligned on
  /// 2-byte boundary. So, no alignment check is needed.
  Uint16List getUint16View(int index, int length) {
    if (length == 0) return emptyUint16List;
    _checkReadIndex(index, length * 2);
    return _bytes.buffer.asUint16List(index, length);
  }

  /// Reads and Returns an [Uint16List] of unsigned 16-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Uint16List readUint16View(int length) {
    var list = getUint16View(_readIndex, length);
    _readIndex += length * 2;
    return list;
  }

  //*** Int32 get, Read Methods **

  /// Returns an signed 32-bit integer.
  int getInt32(int index) {
    _checkReadIndex(index, 4);
    return _bd.getInt32(index, endianness);
  }

  /// Returns an signed 32-bit integer.
  int readInt32() {
    var v = getInt32(_readIndex);
    _readIndex += 4;
    return v;
  }

  final Int32List emptyInt32List = new Int32List(0);

  /// Returns a [new] [Int32List] of signed 32-bit integers from [_bytes].
  /// [length] is the number of elements in the returned list.
  Int32List _getInt32List(int index, int length) {
    if (length == 0) return emptyInt32List;
    var list = new Int32List(length);
    for (int i = 0; i < length; i++, index += 4) list[i] = getInt32(index);
    return list;
  }

  /// Returns an [Int32List] of signed 32-bit integers.
  /// [length] is the number of elements in the returned list.
  Int32List getInt32List(int index, int length) {
    _checkReadIndex(index, length * 4);
    return _getInt32List(index, length);
  }

  /// Reads and Returns an [Int32List] of signed 32-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Int32List readInt32List(int length) {
    var list = getInt32List(_readIndex, length);
    _readIndex += length * 4;
    return list;
  }

  /// Returns an [Int32List] signed 32-bit integers.
  ///
  /// If [index] is aligned on a 4-byte boundary, a View of
  /// [_bytes] is returned, and the data is not copied; however,
  /// if [index] is unaligned the data must be copied.
  Int32List getInt32View(int index, int length) {
    if (length == 0) return emptyInt32List;
    if (_checkReadIndexAligned(index, length, 4)) {
      return _bytes.buffer.asInt32List(index, length);
    } else {
      return _getInt32List(index, length);
    }
  }

  /// Reads and Returns an [Int32List] view of signed 32-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Int32List readInt32View(int length) {
    var list = getInt32View(_readIndex, length);
    _readIndex += length * 4;
    return list;
  }

  //*** Uint32 get, Read Methods **

  /// Returns an unsigned 32-bit integer.
  int getUint32(int index) {
    _checkReadIndex(index, 4);
    return _bd.getUint32(index, endianness);
  }

  /// Returns an unsigned 32-bit integer.
  int readUint32() {
    var v = getUint32(_readIndex);
    _readIndex += 4;
    return v;
  }

  final Uint32List emptyUint32List = new Uint32List(0);

  /// _Internal_: Creates a [new] [Uint32List].
  Uint32List _getUint32List(int index, int length) {
    if (length == 0) return emptyUint32List;
    var list = new Uint32List(length);
    for (int i = 0; i < length; i++, index += 4) list[i] = getUint32(index);
    return list;
  }

  /// Returns a new [Uint32List] of unsigned 32-bit integers.
  /// [length] is the number of elements in the returned list.
  Uint32List getUint32List(int index, int length) {
    _checkReadIndex(index, length * 4);
    return _getUint32List(index, length);
  }

  /// Reads and Returns a [new] [Uint32List] of unsigned 32-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Uint32List readUint32List(int length) {
    var list = getUint32List(_readIndex, length);
    _readIndex += length * 4;
    return list;
  }

  /// Returns an [Uint32List] view of unsigned 32-bit integers.
  ///
  /// If [index] is aligned on a 4-byte boundary, a View of
  /// [_bytes] is returned, and the data is not copied; however,
  /// if [index] is unaligned the data must be copied.
  Uint32List getUint32View(int index, int length) {
    if (length == 0) return emptyUint32List;
    if (_checkReadIndexAligned(index, length, 4)) {
      return _bytes.buffer.asUint32List(index, length);
    } else {
      return _getUint32List(index, length);
    }
  }

  /// Reads and Returns an [Uint32List] view of unsigned 32-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Uint32List readUint32View(int length) {
    //  print('rU32View: l($length)');
    var list = getUint32View(_readIndex, length);
    _readIndex += length * 4;
    return list;
  }

  //*** Int64 get, Read Methods **

  /// Returns an signed 64-bit integer.
  int getInt64(int index) {
    _checkReadIndex(index, 8);
    return _bd.getInt64(index, endianness);
  }

  /// Returns an signed 64-bit integer.
  int readInt64() {
    var v = getInt64(_readIndex);
    _readIndex += 8;
    return v;
  }

  final Int64List emptyInt64List = new Int64List(0);

  /// _Internal_: Returns an [Int64List] of signed 64-bit integers.
  Int64List _getInt64List(int index, int length) {
    if (length == 0) return emptyInt64List;
    var list = new Int64List(length);
    for (int i = 0; i < length; i++, index += 8) list[i] = getInt64(index);
    return list;
  }

  /// Returns an [Int64List] of signed 64-bit integers.
  /// [length] is the number of elements in the returned list.
  Int64List getInt64List(int index, int length) {
    _checkReadIndex(index, length * 8);
    return _getInt64List(index, length);
  }

  /// Reads and Returns an [Int64List] of signed 64-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Int64List readInt64List(int length) {
    var list = getInt64List(_readIndex, length);
    _readIndex += length * 8;
    return list;
  }

  /// Returns an [Int64List] view of signed 64-bit integers.
  ///
  /// If [index] is aligned on a 8-byte boundary, a View of
  /// [_bytes] is returned, and the data is not copied; however,
  /// if [index] is unaligned the data must be copied.
  Int64List getInt64View(int index, int length) {
    if (length == 0) return emptyInt64List;
    if (_checkReadIndexAligned(index, length, 8)) {
      return _bytes.buffer.asInt64List(index, length);
    } else {
      return _getInt64List(index, length);
    }
  }

  /// Reads and Returns an [Int64List] view of signed 64-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Int64List readInt64View(int length) {
    var list = getInt64View(_readIndex, length);
    _readIndex += length * 8;
    return list;
  }

  //*** Uint64 get, Read Methods **

  /// Returns an unsigned 64-bit integer.
  int getUint64(int index) {
    _checkReadIndex(index, 8);
    return _bd.getUint64(index, endianness);
  }

  /// Returns an unsigned 64-bit integer.
  int readUint64() {
    var v = getUint64(_readIndex);
    _readIndex += 8;
    return v;
  }

  final Uint64List emptyUint64List = new Uint64List(0);

  /// _Internal_: Returns an [Uint64List] of unsigned 64-bit integers.
  Uint64List _getUint64List(int index, int length) {
    if (length == 0) return emptyUint64List;
    var list = new Uint64List(length);
    for (int i = 0; i < length; i++, index += 8) list[i] = getUint64(index);
    return list;
  }

  /// Returns an [Uint64List] of unsigned 64-bit integers.
  /// [length] is the number of elements in the returned list.
  Uint64List getUint64List(int index, int length) {
    _checkReadIndex(index, length * 8);
    return _getUint64List(index, length);
  }

  /// Reads and Returns an [Uint64List] of unsigned 64-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Uint64List readUint64List(int length) {
    var list = getUint64List(_readIndex, length);
    _readIndex += length * 8;
    return list;
  }

  /// Returns an [Uint64List] view of unsigned 64-bit integers.
  ///
  /// If [index] is aligned on a 8-byte boundary, a View of
  /// [_bytes] is returned, and the data is not copied; however,
  /// if [index] is unaligned the data must be copied.
  Uint64List getUint64View(int index, int length) {
    if (length == 0) return emptyUint64List;
    if (_checkReadIndexAligned(index, length, 8)) {
      _checkReadIndex(index, length * 8);
      return _bytes.buffer.asUint64List(index, length);
    } else {
      return _getUint64List(index, length);
    }
  }

  /// Reads and Returns an [Uint64List] view of unsigned 64-bit integers,
  /// and advances the [readIndex] by the number of byte read.
  Uint64List readUint64View(int length) {
    var list = getUint64View(_readIndex, length);
    _readIndex += length * 8;
    return list;
  }

  //*** Float32 get, Read Methods **

  /// Returns an signed 32-bit floating point number.
  double getFloat32(int index) {
    _checkReadIndex(index, 4);
    return _bd.getFloat32(index, endianness);
  }

  /// Returns an signed 32-bit floating point number.
  double readFloat32() {
    var v = getFloat32(_readIndex);
    _readIndex += 4;
    return v;
  }

  final Float32List emptyFloat32List = new Float32List(0);

  /// _Internal_: Returns an [Float32List] of signed 32-bit floating point numbers.
  Float32List _getFloat32List(int index, int length) {
    if (length == 0) return emptyFloat32List;
    _checkReadIndex(index, length * 4);
    log.debug('0: getFloat32List as Copy($readIndex) length($length)');
    Float32List list = new Float32List(length);
    for (int i = 0; i < length; i++, index += 4) list[i] = getFloat32(index);
    log.debug('1: getFloat32List as Copy($readIndex) $list');
    return list;
  }

  /// Returns an [Float32List] of signed 32-bit floating point numbers.
  /// [length] is the number of elements in the returned list.
  Float32List getFloat32List(int index, int length) {
    _checkReadIndex(index, length * 4);
    return _getFloat32List(index, length);
  }

  /// Reads and Returns an [Float32List] of signed 32-bit floating point numbers,
  /// and advances the [readIndex] by the number of byte read.
  Float32List readFloat32List(int length) {
    log.info0('readFloat32List0($readIndex)');
    Float32List list = getFloat32List(_readIndex, length);
    log.info0('readFloat32List1($readIndex) $list');
    _readIndex += length * 4;
    return list;
  }

  /// Returns an [Float32List] view of signed 32-bit floating point numbers.
  ///
  /// If [index] is aligned on a 4-byte boundary, a View of
  /// [_bytes] is returned, and the data is not copied; however,
  /// if [index] is unaligned the data must be copied.
  Float32List getFloat32View(int index, int length) {
    if (length == 0) return emptyFloat32List;
    if (_checkReadIndexAligned(index, length, 4)) {
      return _bytes.buffer.asFloat32List(index, length);
    } else {
      return _getFloat32List(index, length);
    }
  }

  /// Reads and Returns an [Float32List] view of signed 32-bit floating point numbers,
  /// and advances the [readIndex] by the number of byte read.
  Float32List readFloat32View(int length) {
    log.debug('readIndex($_readIndex');
    var list = getFloat32View(_readIndex, length);
    _readIndex += length * 4;
    return list;
  }

  //*** Float64 get, Read Methods **

  /// Returns an signed 64-bit floating point number.
  double getFloat64(int index) {
    _checkReadIndex(index, 8);
    return _bd.getFloat64(index, endianness);
  }

  /// Returns an signed 64-bit floating point number.
  double readFloat64() {
    var v = getFloat64(_readIndex);
    _readIndex += 8;
    return v;
  }

  final Float64List emptyFloat64List = new Float64List(0);

  Float64List _getFloat64List(int index, int length) {
    if (length == 0) return emptyFloat64List;
    Float64List list = new Float64List(length);
    for (int i = 0; i < length; i++, index += 8) list[i] = getFloat64(index);
    return list;
  }

  /// Returns an [Float64List] of signed 64-bit floating point numbers.
  /// [length] is the number of elements in the returned list.
  Float64List getFloat64List(int index, int length) {
    _checkReadIndex(index, length * 8);
    return _getFloat64List(index, length);
  }

  /// Reads and Returns an [Float64List] of signed 64-bit floating point numbers,
  /// and advances the [readIndex] by the number of byte read.
  Float64List readFloat64List(int length) {
    var list = getFloat64List(_readIndex, length);
    _readIndex += length * 8;
    return list;
  }

  /// Returns an [Float64List] view of signed 64-bit floating point numbers.
  ///
  /// If [index] is aligned on a 8-byte boundary, a View of
  /// [_bytes] is returned, and the data is not copied; however,
  /// if [index] is unaligned the data must be copied.
  Float64List getFloat64View(int index, int length) {
    if (length == 0) return emptyFloat64List;
    if (_checkReadIndexAligned(index, length, 8)) {
      return _bytes.buffer.asFloat64List(index, length);
    } else {
      return _getFloat64List(index, length);
    }
  }

  /// Reads and Returns an [Float64List] view of signed 64-bit floating point numbers,
  /// and advances the [readIndex] by the number of byte read.
  Float64List readFloat64View(int length) {
    var list = getFloat64View(_readIndex, length);
    _readIndex += length * 8;
    return list;
  }

  //*** Strings
  //TODO: add a [Charset charset = UTF8] argument to String methods.
  //      See dart encode encoding.

  String getAsciiString(int index, int length) {
    if (length == 0) return "";
    return ASCII.decode(getStringBytes(index, length), allowInvalid: true);
  }

  String readAsciiString(int length) {
    var s = getAsciiString(_readIndex, length);
    _readIndex += length;
    return s;
  }

  String getUtf8String(int index, int length) {
    if (length == 0) return "";
    return UTF8.decode(getStringBytes(index, length), allowMalformed: true);
  }

  String readUtf8String(int length) {
    var s = getUtf8String(_readIndex, length);
    _readIndex += length;
    return s;
  }

  /// Returns an unsigned [int] by decoding the bytes from [index]
  /// to [length] as a UTF-8 string.
  Uint8List getStringBytes(int index, int length) {
    _checkReadIndex(index, length);
    return getUint8List(index, length);
  }

  /// Returns a [String] by decoding the bytes from [readIndex]
  /// to [length] as a UTF-8 string, and advances the [readIndex] by [length].
  String readString(int length) => readUtf8String(length);

  /// A canonical value for empty (zero length) StringBytes.
  static final _emptyStringBytes = new Uint8List(0);

  /// Returns a [String] by decoding the bytes from [index]
  /// to [length] as a UTF-8 string.
  Uint8List getStringBytesView(int index, int length) {
    if (length == 0) return _emptyStringBytes;
    _checkReadIndex(index, length);
    return _getUint8List(index, length);
  }

  /// Returns a [String] by decoding the bytes from [readIndex]
  /// to [length] as a UTF-8 string, and advances the [readIndex] by [length].
  Uint8List readStringBytesView(int length) {
    var s = getStringBytesView(_readIndex, length);
    _readIndex += length;
    return s;
  }

  //TODO: rename
  final List<String> emptyStringList = const <String>[];

  /// Returns an [List] of [String] by decoding the bytes from [index]
  /// to [length] as a UTF-8 string, and then uses [delimiter] to
  /// separated the [String] into a [List].
  List<String> getStringList(int index, int length, [String delimiter = r"\"]) {
    if (length == 0) return emptyStringList;
    _checkReadIndex(index, length);
    String s = UTF8.decode(getUint8List(index, length));
    return s.split(delimiter);
  }

  /// Returns an [List] of [String] by decoding the bytes from [readIndex]
  /// to [length] as a UTF-8 string, and then uses [delimiter] to
  /// separated the [String] into a [List]. Finally, the [readIndex] is
  /// advanced by [length].
  List<String> readStringList(int length, [String delimiter = r"\"]) {
    var list = getStringList(_readIndex, length, delimiter);
    _readIndex += length;
    return list;
  }

  //*** Bytes set, write

  /// Stores a 8-bit integer at [index].
  ByteBuf setByte(int index, int value) => setUint8(index, value);

  /// Stores a 8-bit integer at [readIndex] and advances [readIndex] by 1.
  ByteBuf writeByte(int value) => writeUint8(value);

  //*** Write Boolean

  /// Stores a [bool] value at [index] as byte (Uint8),
  /// where 0 = [false], and any other value = [true].
  ByteBuf setBoolean(int index, bool value) {
    setUint8(index, value ? 1 : 0);
    return this;
  }

  /// Stores a [bool] value at [index] as byte (Uint8),
  /// where 0 = [false], and any other value = [true].
  ByteBuf writeBoolean(int index, bool value) {
    setUint8(_writeIndex, value ? 1 : 0);
    _writeIndex++;
    return this;
  }

  /// Stores a [List] of [bool] values from [index] as byte (Uint8),
  /// where 0 = [false], and any other value = [true].
  ByteBuf setBooleanList(int index, List<int> list) {
    _checkWriteIndex(index, list.length);
    for (int i = 0; i < list.length; i++) setInt8(index, list[i]);
    return this;
  }

  /// Stores a [List] of [bool] values from [writeIndex] as byte (Uint8),
  /// where 0 = [false], and any other value = [true].
  ByteBuf writeBooleanList(List<int> list) {
    setBooleanList(_writeIndex, list);
    _writeIndex += list.length;
    return this;
  }

  //*** Write Int8

  /// Stores a Int8 value at [index].
  ByteBuf setInt8(int index, int value) {
    _checkWriteIndex(index, 1);
    _bd.setInt8(index, value);
    return this;
  }

  /// Stores a Int8 value at [writeIndex], and advances
  /// [writeIndex] by 1.
  ByteBuf writeInt8(int value) {
    setInt8(_writeIndex, value);
    _writeIndex++;
    return this;
  }

  /// Stores a [List] of Uint8 [int] values at [index].
  ByteBuf setInt8List(int index, List<int> list) {
    _checkWriteIndex(index, list.length);
    for (int i = 0; i < list.length; i++) {
      setInt8(index, list[i]);
      index += 1;
    }
    return this;
  }

  /// Stores a [List] of Uint8 [int] values at [writeIndex], and advances
  /// [writeIndex] by [List] [length]
  ByteBuf writeInt8List(List<int> list) {
    setInt8List(_writeIndex, list);
    _writeIndex += list.length;
    return this;
  }

  //*** Uint8 set, write

  /// Stores a Uint8 value at [index].
  ByteBuf setUint8(int index, int value) {
    _checkWriteIndex(index, 1);
    Uint8.guard(value);
    _bd.setUint8(index, value);
    return this;
  }

  /// Stores a Uint8 value at [writeIndex], and advances [writeIndex] by 1.
  ByteBuf writeUint8(int value) {
    setUint8(_writeIndex, value);
    _writeIndex++;
    return this;
  }

  /// Stores a [List] of Uint8 values at [index].
  ByteBuf setUint8List(int index, Uint8List list) {
    _checkWriteIndex(index, list.length);
    for (int i = 0; i < list.length; i++) setUint8(index + i, list[i]);
    return this;
  }

  /// Stores a [List] of Uint8 values at [writeIndex],
  /// and advances [writeIndex] by [List] [length].
  ByteBuf writeUint8List(Uint8List list) {
    setUint8List(_writeIndex, list);
    _writeIndex += list.lengthInBytes;
    return this;
  }

  //*** Int16 set, write

  /// Stores an Int16 value at [index].
  ByteBuf setInt16(int index, int value) {
    _checkWriteIndex(index, 2);
    _bd.setInt16(index, value, endianness);
    return this;
  }

  /// Stores an Int16 value at [writeIndex], and advances [writeIndex] by 2.
  ByteBuf writeInt16(int value) {
    setInt16(_writeIndex, value);
    _writeIndex += 2;
    return this;
  }

  /// Stores a [List] of Int16 values at [index].
  ByteBuf setInt16List(int index, List<int> list) {
    _checkWriteIndex(index, list.length * 2);
    for (int i = 0; i < list.length; i++) {
      setInt16(index, list[i]);
      index += 2;
    }
    return this;
  }

  /// Stores a [List] of Int16 values at [writeIndex],
  /// and advances [writeIndex] by ([list] [length] * 2).
  ByteBuf writeInt16List(List<int> list) {
    setInt16List(_writeIndex, list);
    _writeIndex += (list.length * 2);
    return this;
  }

  //*** Uint16 set, write litte Endian

  /// Stores a Uint16 value at [index],
  ByteBuf setUint16(int index, int value) {
    _checkWriteIndex(index, 2);
    _bd.setInt16(index, value, endianness);
    return this;
  }

  /// Stores a Uint16 value at [writeIndex],
  /// and advances [writeIndex] by 2.
  ByteBuf writeUint16(int value) {
    setUint16(_writeIndex, value);
    _writeIndex += 2;
    return this;
  }

  /// Stores a [List] of Uint16 values at [index].
  ByteBuf setUint16List(int index, List<int> list) {
    _checkWriteIndex(index, list.length * 2);
    for (int i = 0; i < list.length; i++) {
      setUint16(index, list[i]);
      index += 2;
    }
    return this;
  }

  /// Stores a [List] of Uint16 values at [writeIndex],
  /// and advances [writeIndex] by ([list] [length] * 2).
  ByteBuf writeUint16List(Uint16List list) {
    setUint16List(_writeIndex, list);
    _writeIndex += (list.length * 2);
    return this;
  }

  //*** Int32 set, write ***

  /// Stores an Int32 value at [index].
  ByteBuf setInt32(int index, int value) {
    _checkWriteIndex(index, 4);
    _bd.setInt32(index, value, endianness);
    return this;
  }

  /// Stores an Int32 value at [writeIndex],
  /// and advances [writeIndex] by 4.
  ByteBuf writeInt32(int value) {
    setInt32(_writeIndex, value);
    _writeIndex += 4;
    return this;
  }

  /// Stores a [List] of Int32 values at [index],
  ByteBuf setInt32List(int index, Int32List list) {
    _checkWriteIndex(index, list.length * 4);
    for (int i = 0; i < list.length; i++) {
      setInt32(index, list[i]);
      index += 4;
    }
    return this;
  }

  /// Stores a [List] of Int32 values at [writeIndex],
  /// and advances [writeIndex] by ([list] [length] * 4).
  ByteBuf writeInt32List(Int32List list) {
    setInt32List(_writeIndex, list);
    _writeIndex += (list.length * 4);
    return this;
  }

  //*** Uint32 set, write

  /// Stores a Uint32 value at [index].
  ByteBuf setUint32(int index, int value) {
    _checkWriteIndex(index, 4);
    _bd.setUint32(index, value, endianness);
    return this;
  }

  /// Stores a Uint32 value at [writeIndex],
  /// and advances [writeIndex] by 4.
  ByteBuf writeUint32(int value) {
    setUint32(_writeIndex, value);
    _writeIndex += 4;
    return this;
  }

  /// Stores a [List] of Uint32 values at [index].
  ByteBuf setUint32List(int index, List<int> list) {
    _checkWriteIndex(index, list.length * 4);
    for (int i = 0; i < list.length; i++) {
      setUint32(index, list[i]);
      index += 4;
    }
    return this;
  }

  /// Stores a [List] of Uint32 values at [writeIndex],
  /// and advances [writeIndex] by ([list] [length] * 4).
  ByteBuf writeUint32List(List<int> list) {
    setUint32List(_writeIndex, list);
    _writeIndex += (list.length * 4);
    return this;
  }

  //*** Int64 set, write

  /// Stores an Int64 values at [index].
  ByteBuf setInt64(int index, int value) {
    _checkWriteIndex(index, 8);
    _bd.setInt64(index, value, endianness);
    return this;
  }

  /// Stores an Int64 values at [writeIndex],
  /// and advances [writeIndex] by 8.
  ByteBuf writeInt64(int value) {
    setInt64(_writeIndex, value);
    _writeIndex += 8;
    return this;
  }

  /// Stores a [List] of Int64 values at [index].
  ByteBuf setInt64List(int index, List<int> list) {
    _checkWriteIndex(index, list.length * 8);
    for (int i = 0; i < list.length; i++) {
      setInt64(index, list[i]);
      index += 8;
    }
    return this;
  }

  /// Stores a [List] of Int64 values at [writeIndex],
  /// and advances [writeIndex] by ([list] [length] * 8).
  ByteBuf writeInt64List(List<int> list) {
    setInt64List(_writeIndex, list);
    _writeIndex += (list.length * 8);
    return this;
  }

  //*** Uint64 set, write

  /// Stores a Uint64 value at [index].
  ByteBuf setUint64(int index, int value) {
    _checkWriteIndex(index, 8);
    _bd.setUint64(index, value, endianness);
    return this;
  }

  /// Stores a Uint64 value at [writeIndex],
  /// and advances [writeIndex] by 8.
  ByteBuf writeUint64(int value) {
    setUint64(_writeIndex, value);
    _writeIndex += 8;
    return this;
  }

  /// Stores a [List] of Uint64 values at [index].
  ByteBuf setUint64List(int index, List<int> list) {
    _checkWriteIndex(index, list.length * 8);
    for (int i = 0; i < list.length; i++) {
      setUint64(index, list[i]);
      index += 8;
    }
    return this;
  }

  /// Stores a [List] of Uint64 values at [writeIndex],
  /// and advances [writeIndex] by ([list] [length] * 8).
  ByteBuf writeUint64List(List<int> list) {
    setUint64List(_writeIndex, list);
    _writeIndex += (list.length * 8);
    return this;
  }

  //*** Float32 set, write

  ByteBuf _setFloat32(int index, double value) {
    _bd.setFloat32(index, value, endianness);
    return this;
  }

  /// Stores a Float32 value at [index].
  ByteBuf setFloat32(int index, double value) {
    _checkWriteIndex(index, 4);
    _setFloat32(index, value);
    return this;
  }

  /// Stores a Float32 value at [writeIndex],
  /// and advances [writeIndex] by 4.
  ByteBuf writeFloat32(double value) {
    setFloat32(_writeIndex, value);
    _writeIndex += 4;
    return this;
  }

  /// Stores a [List] of Float32 values at [index].
  ByteBuf setFloat32List(int index, Float32List list) {
    _checkWriteIndex(index, list.lengthInBytes);
    for (int i = 0; i < list.length; i++) {
      _setFloat32(index, list[i]);
      index += 4;
    }
    return this;
  }

  /// Stores a [List] of Float32 values at [writeIndex],
  /// and advances [writeIndex] by ([list] [length] * 4).
  ByteBuf writeFloat32List(Float32List list) {
    log.debug('0: writeFloat32List($writeIndex) $list');
    setFloat32List(_writeIndex, list);
    _writeIndex += (list.lengthInBytes);
    log.debug('0: writeFloat32List($writeIndex)');
    return this;
  }

  //*** Float64 set, write

  /// Stores a Float64 value at [index],
  ByteBuf setFloat64(int index, double value) {
    _checkWriteIndex(index, 8);
    _bd.setFloat64(index, value, endianness);
    return this;
  }

  /// Stores a Float64 value at [writeIndex],
  /// and advances [writeIndex] by 8.
  ByteBuf writeFloat64(double value) {
    setFloat64(_writeIndex, value);
    _writeIndex += 8;
    return this;
  }

  /// Stores a [List] of Float64 values at [index].
  ByteBuf setFloat64List(int index, List<double> list) {
    _checkWriteIndex(index, list.length * 8);
    for (int i = 0; i < list.length; i++) {
      setFloat64(index, list[i]);
      index += 8;
    }

    return this;
  }

  /// Stores a [List] of Float64 values at [writeIndex],
  /// and advances [writeIndex] by ([list] [length] * 8).
  ByteBuf writeFloat64List(List<double> list) {
    setFloat64List(_writeIndex, list);
    _writeIndex += (list.length * 8);
    return this;
  }

  //*** String set, write
  //TODO: add Charset parameter

  /// Internal: Store the [String] [value] at [index] in this [ByteBuf].
  int _setString(int index, String value) {
    Uint8List list = UTF8.encode(value);
    _checkWriteIndex(index, list.length);
    for (int i = 0; i < list.length; i++) _bytes[index + i] = list[i];
    return list.length;
  }

  /// Store the [String] [value] at [index].
  ByteBuf setString(int index, String value) {
    _setString(index, value);
    return this;
  }

  /// Store the [String] [value] at [writeIndex].
  /// and advance [writeIndex] by the [length] of the decoded string.
  ByteBuf writeString(String value) {
    var length = _setString(_writeIndex, value);
    _writeIndex += length;
    return this;
  }

  /* Flush
  int _stringListLength(List<String> list) {
    int length = 0;
    for (int i = 0; i < list.length; i++) {
      length += list[i].length;
      length++;
    }
    return length;
  }
  */
  /// Converts the [List] of [String] into a single [String] separated
  /// by [delimiter], encodes that string into UTF-8, and store the
  /// UTF-8 string at [index].
  ByteBuf setStringList(int index, List<String> list,
      [String delimiter = r"\"]) {
    String s = list.join(delimiter);
    _checkWriteIndex(index, s.length);
    _setString(index, s);
    return this;
  }

  /// Converts the [List] of [String] into a single [String] separated
  /// by [delimiter], encodes that string into UTF-8, and stores the UTF-8
  /// string at [writeIndex]. Finally, it advances [writeIndex]
  /// by the [length] of the encoded string.
  ByteBuf writeStringList(List<String> list, [String delimiter = r"\"]) {
    String s = list.join(delimiter);
    var length = _setString(_writeIndex, s);
    _writeIndex += length;
    return this;
  }

  //*** Index moving operations

  /// Moves the [readIndex] backward in the readable part of [this].
  ByteBuf unreadBytes(int length) {
    _checkReadIndex(_readIndex, -length);
    _readIndex -= length;
    return this;
  }

  /// Moves the [readIndex] forwar , if negative backward, in the read buffer.
  ByteBuf skipReadBytes(int length) {
    _checkReadIndex(_readIndex, length);
    readIndex = readIndex + length;
    return this;
  }

  /// Moves the [writeIndex] backward in the writable part of [this] [ByteBuf].
  ByteBuf unWriteBytes(int length) {
    _checkWriteIndex(_writeIndex, -length);
    _writeIndex -= length;
    return this;
  }

  /// Moves the [writeIndex] forward or, if negative backward, in the Write buffer.
  ByteBuf skipWriteBytes(int length) {
    _checkWriteIndex(_writeIndex, length);
    _writeIndex = _writeIndex + length;
    return this;
  }

  /// Compares the content of [this] to the content
  /// of [other].  Comparison is performed in a similar
  /// manner to the [String.compareTo] method.
  //TODO: should this also compare write capacity?
  int compareTo(ByteBuf other) {
    if (this == other) return 0;
    final int len = readCapacity;
    final int oLen = other.readCapacity;
    final int minLength = math.min(len, oLen);

    int aIndex = readIndex;
    int bIndex = other.readIndex;
    for (int i = 0; i < minLength; i++) {
      if (this[aIndex] > other[bIndex]) return 1;
      if (this[aIndex] < other[bIndex]) return -1;
    }
    // The buffers are == upto minLength, so...
    return len - oLen;
  }

  // Auxiliary used for debugging
  String toHex(int start, int end, [int pos]) {
    String hex(int n) => n.toRadixString(16).padLeft(2, "0");

    log.debug('$rrr toHex: start($start), end($end), pos($pos');
    if (pos == null) pos = start;
    if (start >= writeIndex) return "";
    if (pos >= writeIndex) pos = writeIndex;

    log.debug('$rrr toHex: start($start), end($end), pos($pos');
    var s = "";
    for (int i = start; i < pos; i++) s += ' ' + hex(_bytes[i]);

    s += "|";
    s += hex(_bytes[pos]);
    s += "|";

    if (end >= writeIndex) end = writeIndex;
    for (int i = pos + 1; i < end; i++) s += ' ' + hex(_bytes[i]);
    return s;
  }

  // Auxiliary used for debugging
  String toAscii(int start, int end, [int pos]) {
    String vChar(int c) =>
        (isVisibleChar(c)) ? '_' + new String.fromCharCode(c) : '__';

    log.debug('$rrr toHex: start($start), end($end), pos($pos');
    if (pos == null) pos = start;
    if (start >= writeIndex) return "";
    if (pos >= writeIndex) pos = writeIndex;

    log.debug('$rrr toHex: start($start), end($end), pos($pos');
    String s = "";
    for (int i = start; i < pos; i++) s += ' ' + vChar(_bytes[i]);
    s += "|";
    s += vChar(_bytes[pos]);
    s += "|";
    if (end >= writeIndex) end = writeIndex;
    for (int i = pos + 1; i < end; i++) s += ' ' + vChar(_bytes[i]);
    return '$s';
  }

  String get info => """
  ByteBuf $hashCode
    rdIdx: $_readIndex,
    bytes: '${toHex(_readIndex, _writeIndex)}'
    string:'${_bytes.sublist(_readIndex, _writeIndex).toString()}'
    wrIdx: $_writeIndex,
    remaining: ${lengthInBytes - _writeIndex }
    cap: $lengthInBytes,
    maxCap: $lengthInBytes
  """;

  @override
  String toString() => '$runtimeType: (rdIdx: $_readIndex, wrIdx: '
      '$_writeIndex, cap: $lengthInBytes, maxCap: $lengthInBytes)';

  /// Checks that the [readIndex] is valid;
  void _checkReadIndex(int index, int elementSize) {
    log.debug('index($index), elementSize($elementSize)');
    if ((index + elementSize) > writeIndex)
      _readIndexOutOfBounds(index, elementSize);
  }

  /// Checks that the [readIndex] is valid;
  bool _checkReadIndexAligned(int index, int length, int elementSize) {
    if ((index + (length * elementSize)) > writeIndex)
      _readIndexOutOfBounds(index, lengthInBytes);
    int remainder = (index % elementSize);
    return remainder == 0;
  }

  /// Checks that the [writeIndex] is valid;
  void _checkWriteIndex(int index, int lengthInBytes) {
    if (((index < _writeIndex) ||
        (index + lengthInBytes) > _bytes.lengthInBytes))
      _writeIndexOutOfBounds(index + lengthInBytes);
  }

  /// Checks that there are at least [lengthInBytes] available.
  void _checkReadableBytes(int lengthInBytes) {
    if (_readIndex > (_writeIndex - lengthInBytes)) {
      var s =
          "readIndex($readIndex) + length($lengthInBytes) exceeds writeIndex($writeIndex): #this";
      log.debug(s);
      throw new RangeError(s);
    }
  }

  /// Checks that there are at least [minimumWritableBytes] available.
  void _checkWritableBytes(int minimumWritableBytes) {
    if ((_writeIndex + minimumWritableBytes) > lengthInBytes) {
      var s =
          "writeIndex($writeIndex) + minimumWritableBytes($minimumWritableBytes) exceeds lengthInBytes($lengthInBytes): $this";
      log.debug(s);
      throw new RangeError(s);
    }
  }

  //*** Error Methods ***

  //TODO: make this two different methods
  void _readIndexOutOfBounds(int index, int lengthInBytes) {
    String s =
        "Read Index Out Of Bounds: read($_readIndex) <= index($index) "
        "< write($_writeIndex) lengthInBytes($lengthInBytes";
    log.error(s);
    throw new RangeError(s);
  }

  void _writeIndexOutOfBounds(int index) {
    String s =
        "Invalid Write Index($index): $index \nto ByteBuf($this) with $lengthInBytes";
    log.error(s);
    throw new RangeError(s);
  }
}

//**** Auxiliary Functions

Uint8List _copyBytes(Uint8List bytes,
    [int index = 0, int lengthInBytes, int maxCapacity = 1 * kGB]) {
  lengthInBytes = _validateLengthIB(bytes.length, lengthInBytes, maxCapacity);
  return bytes.sublist(index, lengthInBytes);
}

Uint8List _getBytes([int lengthInBytes = kKB]) {
  lengthInBytes = _validateLengthIB(lengthInBytes, lengthInBytes);
  return new Uint8List(lengthInBytes);
}

Uint8List _getByteView(Uint8List bytes,
    [int rIndex = 0, int wIndex, int lengthIB]) {
  lengthIB = _validateLengthIB(bytes.lengthInBytes, lengthIB);
  wIndex = _validateWriteIndex(rIndex, wIndex, lengthIB);
  return bytes.buffer.asUint8List(rIndex, lengthIB);
}

ByteBuf _getByteBuf(
    [int readIndex = 0,
    int writeIndex,
    int lengthInBytes = kKB,
    int maxCapacity = kGB]) {
  lengthInBytes = _validateLengthIB(lengthInBytes, lengthInBytes, maxCapacity);
  var _bytes = new Uint8List(lengthInBytes);
  return new ByteBuf._(_bytes, readIndex, writeIndex);
}

ByteBuf _getBufView(Uint8List bytes,
    [int rIndex = 0, int wIndex, int lengthIB]) {
  lengthIB = _validateLengthIB(bytes.lengthInBytes, lengthIB);
  wIndex = _validateWriteIndex(rIndex, wIndex, lengthIB);
  var _bytes = bytes.buffer.asUint8List(rIndex, lengthIB);
  return new ByteBuf._(_bytes, rIndex, wIndex);
}

/// Returns a valid [lengthInBytes] or throws an [ArgumentError].
///
/// [bytesLength] is the max [lengthInBytes] of an allocated [Uint8List].
/// [lengthInBytes] is the desired length of the allocated [Uint8List].
int _validateLengthIB(int bytesLength,
    [int lengthInBytes, int maxCapacity = kMaxCapacity]) {
  if (lengthInBytes == null) return bytesLength;
  if (lengthInBytes < 0 || maxCapacity < lengthInBytes) {
    throw new ArgumentError(
        'Invalid value: 0 < lengthInBytes($lengthInBytes) <= maxCapacity($maxCapacity)');
  } else if (bytesLength < lengthInBytes) {
    throw new ArgumentError(
        'Invalid value: lengthInBytes($lengthInBytes) > bytes.lengthInBytes($bytesLength');
  }
  return lengthInBytes;
}

// 0 <= readIndex <= writeIndex <= lengthInBytes;
int _validateWriteIndex(int rIndex, int wIndex, int lengthIB) {
  if (wIndex == null) return lengthIB;
  if (rIndex < 0 || wIndex < rIndex || wIndex > lengthIB) {
    throw new ArgumentError('Invalid Index: '
        '0 <= readIndex($rIndex) <= writeIndex($wIndex) <= lengthInBytes($lengthIB)');
  }
  return wIndex;
}
