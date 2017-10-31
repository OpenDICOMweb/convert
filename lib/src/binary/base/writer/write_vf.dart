// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

typedef void EvrVFWriter(TypedData vfBytes);

void _writeValueField(TypedData vfBytes, int vrIndex) {
	_evrVFWriters[vrIndex](vfBytes);
}

final _evrVFWriters = <EvrVFWriter>[
	_sqError, // stop reformat
	// Maybe Undefined Lengths
	OBWriteVF, OWWriteVF, UNWriteVF,

	// EVR Long
	ODWriteVF, OFWriteVF, OLWriteVF,
	UCWriteVF, URWriteVF, UTWriteVF,

	// EVR Short
	AEWriteVF, ASWriteVF, ATWriteVF,
	CSWriteVF, DAWriteVF, DSWriteVF,
	DTWriteVF, FDWriteVF, FLWriteVF,
	ISWriteVF, LOWriteVF, LTWriteVF,
	PNWriteVF, SHWriteVF, SLWriteVF,
	SSWriteVF, STWriteVF, TMWriteVF,
	UIWriteVF, ULWriteVF, USWriteVF,
];

/// Writes a 16-bit unsigned integer (Uint16) value to the output [rootBD].
void _writeUint16(int value) {
	assert(value >= 0 && value <= 0xFFFF, 'Value out of range: $value');
	_maybeGrow(2);
	_rootBD.setUint16(_wIndex, value, Endianness.HOST_ENDIAN);
	_wIndex += 2;
}

/// Writes a 32-bit unsigned integer (Uint32) value to the output [rootBD].
void _writeUint32(int value) {
	assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
	_maybeGrow(4);
	_rootBD.setUint32(_wIndex, value, Endianness.HOST_ENDIAN);
	_wIndex += 4;
}

/// Writes a 64-bit unsigned integer (Uint32) value to the output [rootBD].
void _writeUint64(int value) {
	assert(value >= 0 && value <= 0xFFFFFFFF, 'Value out if range: $value');
	_maybeGrow(8);
	_rootBD.setUint64(_wIndex, value, Endianness.HOST_ENDIAN);
	_wIndex += 8;
}
/// Writes [bytes] to the output [rootBD].
void _writeBytes(Uint8List bytes) => __writeBytes(bytes);

void __writeBytes(Uint8List bytes) {
	final length = bytes.lengthInBytes;
	_maybeGrow(length);
	for (var i = 0, j = _wIndex; i < length; i++, j++) rootBD.setUint8(j, bytes[i]);
	_wIndex = _wIndex + length;
}

/// Writes [bytes], which contains Code Units to the output [rootBD],
/// ensuring that an even number of bytes are written, by adding
/// a padding character if necessary.
void _writeStringBytes(Uint8List bytes, [int padChar = kSpace]) {
	//TODO: doFixPaddingErrors
	_writeBytes(bytes);
	if (bytes.length.isOdd) {
		rootBD.setUint8(_wIndex, padChar);
		_wIndex++;
	}
}

//TODO: doFixPaddingErrors
/// Writes an [ASCII] [String] to the output [rootBD].
void _writeAsciiString(String s, [int offset = 0, int limit, int padChar = kSpace]) =>
		_writeStringBytes(ASCII.encode(s), padChar);

/// Writes an [UTF8] [String] to the output [rootBD].
void writeUtf8String(String s, [int offset = 0, int limit]) =>
		_writeStringBytes(UTF8.encode(s), kSpace);


/// Ensures that [rootBD] is at least [index] + [remaining] long,
/// and grows the buffer if necessary, preserving existing data.
void ensureRemaining(int index, int remaining) => ensureCapacity(index + remaining);

/// Ensures that [rootBD] is at least [capacity] long, and grows
/// the buffer if necessary, preserving existing data.
void ensureCapacity(int capacity) => (capacity > rootBD.lengthInBytes) ? _grow() : null;

/// Grow the buffer if the index is at, or beyond, the end of the current
/// buffer.
void _maybeGrow([int size = 1]) {
	if (_wIndex + size >= rootBD.lengthInBytes) _grow();
}

/// Creates a new buffer at least double the size of the current buffer,
/// and copies the contents of the current buffer into it.
///
/// If [capacity] is null the new buffer will be twice the size of the
/// current buffer. If [capacity] is not null, the new buffer will be at
/// least that size. It will always have at least have double the
/// capacity of the current buffer.
void _grow([int capacity]) {
	final oldLength = rootBD.lengthInBytes;
	var newLength = oldLength * 2;
	if (capacity != null && capacity > newLength) newLength = capacity;

	_isValidBufferLength(newLength);
	if (newLength < oldLength) return;
	final newBuffer = new ByteData(newLength);
	for (var i = 0; i < oldLength; i++) newBuffer.setUint8(i, rootBD.getUint8(i));
	rootBD = newBuffer;
}
