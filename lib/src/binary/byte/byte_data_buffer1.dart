import 'dart:typed_data';

class ByteDataBuffer {
  /// The underlying data buffer.
  ///
  /// This is always both a List<E> and a TypedData, which we don't have a type
  /// for here. For example, for a `Uint8Buffer`, this is a `Uint8List`.
  ByteData _buffer;

  ByteDataBuffer([int length = defaultLength])
      : this._buffer = new ByteData(_checkLength(length));

  factory ByteDataBuffer.view(ByteDataBuffer bd, [int start = 0, int end]) {
    if (start < 0 || start >= bd.lengthInBytes)
      throw new RangeError.index(start, bd);
     end ??= bd.lengthInBytes;
    if (end < 0 || end >= bd.lengthInBytes) throw new RangeError.index(end, bd);
    return new ByteDataBuffer._(
        bd.buffer.asByteData(bd.offsetInBytes + start, bd.offsetInBytes + end));
  }

  ByteDataBuffer._(ByteData buffer) : this._buffer = buffer;

  // TypedData interface.

  int get elementSizeInBytes => _buffer.elementSizeInBytes;

  int get offsetInBytes => _buffer.offsetInBytes;

  int get lengthInBytes => _buffer.lengthInBytes;

  /// Returns the underlying [ByteBuffer].
  ///
  /// The returned buffer may be replaced by operations that change the length
  /// of this list.
  ///
  /// The buffer may be larger than [lengthInBytes] bytes, but never smaller.
  ByteBuffer get buffer => _buffer.buffer;

  // The Getters and Setters

  int getInt8(int index) => _buffer.getInt8(_checkIndex(index));

  void setInt8(int index, int value) {
    _maybeGrow(index);
    _buffer.setInt8(index, value);
  }

  /// Ensures that [_buffer] is at least [index] + [remaining] long,
  /// and grows the buffer if necessary, preserving existing data.
  void ensureRemaining(int index, int remaining) =>
      _maybeGrow(index + remaining);

  /// Ensures that [_buffer] is at least [capacity] long, and grows
  /// the buffer if necessary, preserving existing data.
  void ensureCapacity(int capacity) => _maybeGrow(capacity);

  // Internal methods
  int _checkIndex(int index) => (index >= _buffer.lengthInBytes)
      ? throw new RangeError.index(index, this)
      : index;

  /// Grow the buffer if the index is at, or beyond, the end of the current
  /// buffer.
  int _maybeGrow(int index) {
    if (index >= _buffer.lengthInBytes) _grow();
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
	  final oldLength = _buffer.lengthInBytes;
	  var newLength = oldLength * 2;
    if (capacity != null && capacity > newLength) newLength = capacity;
    if (newLength < oldLength) return;
	  final newBuffer = new ByteData(newLength);
    for (var i = 0; i < oldLength; i++)
      newBuffer.setUint8(i, _buffer.getUint8(i));
    _buffer = newBuffer;
  }
}

const int defaultLength = 16;
const int k1GB = 1024 * 1024 * 1024;

int _checkLength(int length) {
  if (length == null || length < 1 || length > k1GB)
    throw new RangeError.range(length, 1, k1GB);
  return length;
}

