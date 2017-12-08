import 'dart:typed_data';

class ByteDataBuffer {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.
  ByteData _bd;

  ByteDataBuffer([int length = defaultLength])
      : this._bd = new ByteData(_checkLength(length));

  factory ByteDataBuffer.view(ByteDataBuffer bd, [int start = 0, int end]) {
    if (start < 0 || start >= bd.lengthInBytes)
      throw new RangeError.index(start, bd);
     end ??= bd.lengthInBytes;
    if (end < 0 || end >= bd.lengthInBytes) throw new RangeError.index(end, bd);
    return new ByteDataBuffer._(
        bd.buffer.asByteData(bd.offsetInBytes + start, bd.offsetInBytes + end));
  }

  ByteDataBuffer._(ByteData buffer) : this._bd = buffer;

  // TypedData interface.

  int get elementSizeInBytes => _bd.elementSizeInBytes;

  int get offsetInBytes => _bd.offsetInBytes;

  int get lengthInBytes => _bd.lengthInBytes;

  /// Returns the underlying [ByteBuffer].
  ///
  /// The returned buffer may be replaced by operations that change the length
  /// of this list.
  ///
  /// The buffer may be larger than [lengthInBytes] bytes, but never smaller.
  ByteBuffer get buffer => _bd.buffer;

  // The Getters and Setters

  int getInt8(int index) => _bd.getInt8(_checkIndex(index));

  void setInt8(int index, int value) {
    _maybeGrow(index);
    _bd.setInt8(index, value);
  }

  /// Ensures that [_bd] is at least [index] + [remaining] long,
  /// and grows the buffer if necessary, preserving existing data.
  void ensureRemaining(int index, int remaining) =>
      _maybeGrow(index + remaining);

  /// Ensures that [_bd] is at least [capacity] long, and grows
  /// the buffer if necessary, preserving existing data.
  void ensureCapacity(int capacity) => _maybeGrow(capacity);

  // Internal methods
  int _checkIndex(int index) => (index >= _bd.lengthInBytes)
      ? throw new RangeError.index(index, this)
      : index;

  /// Grow the buffer if the index is at, or beyond, the end of the current
  /// buffer.
  int _maybeGrow(int index) {
    if (index >= _bd.lengthInBytes) _grow();
    return index;
  }

  /// Creates a new buffer at least double the size of the current buffer,
  /// and copies the contents of the current buffer into it.
  ///
  /// If [capacity] is null the new buffer will be twice the size of the
  /// current buffer. If [capacity] is not null, the new buffer will be at
  /// least that size. It will always have at least have double the
  /// capacity of the current buffer.
  void _grow([int capacity]) {
	  final oldLength = _bd.lengthInBytes;
	  var newLength = oldLength * 2;
    if (capacity != null && capacity > newLength) newLength = capacity;
    if (newLength < oldLength) return;
	  final newBuffer = new ByteData(newLength);
    for (var i = 0; i < oldLength; i++)
      newBuffer.setUint8(i, _bd.getUint8(i));
    _bd = newBuffer;
  }
}

const int defaultLength = 16;
const int k1GB = 1024 * 1024 * 1024;

int _checkLength(int length) {
  if (length == null || length < 1 || length > k1GB)
    throw new RangeError.range(length, 1, k1GB);
  return length;
}

