// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import 'package:convert/src/buffer/write_buffer.dart';
import 'package:convert/src/utilities/encoding_parameters.dart';

/// A library for encoding [Dataset]s in the DICOM File Format.
///
/// Supports encoding all LITTLE ENDIAN [TransferSyntax]es.
/// Does not currently support BIG ENDIAN which is retired.
///
/// _Notes_:
///   1. In all cases [DicomWriteBuffer] writes the Value Fields as they
///   are in the data; thus, all Value Fields should have an even length.
///   2. All String manipulation should be handled in the attribute itself.
// Note: There are four [Element]s that might have an Undefined Length value
// (0xFFFFFFFF), [SQ], [OB], [OW], [UN].
abstract class DicomWriteBuffer extends WriteBuffer {

  DicomWriteBuffer(
      [int length = kDefaultInitialLength, Endian endian = kDefaultEndian,
        int limit = kDefaultLimit])
      : super.ofSize(length, endian, limit);

  DicomWriteBuffer.fromByteData(ByteData bd,
       [int offset = 0,
       int length,
       Endian endian = kDefaultEndian,
       int limit = kDefaultLimit])
      : super.fromTypedData(bd, offset, length, endian, limit);

  DicomWriteBuffer.fromUint8List(Uint8List bytes,
    [int offset = 0,
    int length,
    Endian endian = kDefaultEndian,
    int limit = kDefaultLimit])
      : super.fromTypedData(bytes, offset, length, endian, limit);

  // **** Interface ****

  RootDataset get rds;
  int get minLength;
//  ByteData get fmiBD;
  EncodingParameters get eParams;
  bool get reUseBD;
  Dataset get cds;
  set cds(Dataset ds);
  void writeElement(Element e);

  // **** End Interface ****


  /// Write a DICOM Tag Code to _this_.
  void writeCode(int code) {
    const kItem = 0xfffee000;
    assert(code >= 0 && code < kItem, 'Value out of range: $code');
    assert(wIndex_.isEven && wHasRemaining(4));
    _maybeGrow(4);
    bd..setUint16(wIndex_, code >> 16)..setUint16(wIndex_ + 2, code & 0xFFFF);
    wIndex_ += 4;
  }

  /// Grow the buffer if the [wIndex] is at, or beyond, the end of the current buffer.
  bool _maybeGrow([int size = 1]) =>
      ((wIndex_ + size) < bd.lengthInBytes) ? false : growBuffer(wIndex_ + size);

  bool get isEvr => rds.isEvr;

  /// Returns a [Uint8List] view of the [ByteData] buffer at the current time
  Uint8List get asUint8List => uint8View(0, wIndex_);

  /// Return's the current position of the write index ([wIndex]).
//  int get wIndex => wIndex_;

  /// The root Dataset being encoded.
  //  RootDataset get rds;

  TransferSyntax get ts => rds.transferSyntax;

  /// The current dataset.  This changes as Sequences and Items are encoded.
  //  Dataset cds;

  /// The current [length] in bytes of this [DicomWriteBuffer].
//  int get lengthInBytes => wIndex_;

  /// The current [length] in bytes of this [DicomWriteBuffer].
//  int get length => lengthInBytes;

  bool get removeUndefinedLengths => eParams.doConvertUndefinedLengths;

  String get info => '$runtimeType: rds: ${rds.info}, cds: ${cds.info}';

  bool get isFmiWritten => _isFmiWritten;

  // ignore: prefer_final_fields
  bool _isFmiWritten = false;
  set isFmiWritten(bool v) => _isFmiWritten ??= true;

  /// Writes (encodes) the root [Dataset] in 'application/dicom' media type,
  /// writes it to a Uint8List, and returns the [Uint8List].
  Uint8List writeRootDataset(RootDataset rds) {
    _writeDataset(rds);
    return uint8View(0, wIndex_);
  }

  void _writeDataset(Dataset ds) {
    // ignore: prefer_forEach
    for (var e in ds.elements)
      writeElement(e);
  }

  /// Write all [Item]s in [items].
  void writeItems(List<Item> items) {
    for (var item in items) {
      final parentDS = cds;
      cds = item;
      writeItem(item);
      cds = parentDS;
    }
  }

  /// Write one [Item].
  void writeItem(Item item) =>
      ((item.hasULength && !eParams.doConvertUndefinedLengths))
      ? _writeUndefinedLengthItem(item)
      : _writeDefinedLengthItem(item);

  void writeDefinedLengthItem(Item item) => _writeDefinedLengthItem(item);
  void writeUndefinedLengthItem(Item item) => _writeUndefinedLengthItem(item);

  /// Writes a [Dataset] to the buffer.
  void _writeDefinedLengthItem(Item item) {
    writeUint32(kItem32BitLE);
    writeUint32(item.vfLength);
    _writeDataset(item);
  }

  void _writeUndefinedLengthItem(Item item) {
    writeUint32(kItem32BitLE);
    writeUint32(kUndefinedLength);
    _writeDataset(item);
    writeUint32(kItemDelimitationItem32BitLE);
    writeUint32(0);
  }

  void writeEncapsulatedPixelData(Element e) {
    assert(e.vfLengthField == kUndefinedLength);
    for (final fragment in e.fragments.fragments) {
      print('fragment(${fragment.lengthInBytes})');
      writeUint32(kItem32BitLE);
      writeUint32(fragment.lengthInBytes);
      write(fragment);
      // If odd length write padding byte
      if (fragment.length.isOdd) {
        log.warn('Odd length(${fragment.lengthInBytes}) fragment');
        writeUint8(0);
      }
    }
    //  wb..uint32(kSequenceDelimitationItem32BitLE)..uint32(0);
    print('End of pixelData: $wIndex_');
  }

  // **** Logging Interface ****
  void logStartWrite(Element e, String name) {}

  void logEndWrite(int eStart, Element e, String name, {bool ok}) {}

  void logStartSQWrite(Element e, String name) {}

  void logEndSQWrite(int eStart, Element e, String name, {bool ok}) {}

  /// Returns the [outputTS] for the encoded output.
  static TransferSyntax getOutputTS(RootDataset rds, TransferSyntax outputTS) {
    if (outputTS == null) {
      return (rds.transferSyntax == null)
             ? system.defaultTransferSyntax
             : rds.transferSyntax;
    } else {
      return outputTS;
    }
  }

  static int paddingChar(int vrIndex) => kPaddingByVRIndex[vrIndex];
}

const List<int> kPaddingByVRIndex = const <int>[
  // Sequence == 0
  -1,
  // EVR Long maybe undefined
  -1, -1, -1,
  // EVR Long
  -1, -1, -1, kSpace, kSpace, kSpace,
  // EVR Short
  kSpace, kSpace, -1, kSpace, kSpace, kSpace, kSpace,
  -1, -1, kSpace, kSpace, kSpace, kSpace, kSpace,
  -1, -1, kSpace, kSpace, kNull, -1, -1,
  // EVR Special
  -1, -1, -1, -1
];



/// The default [ByteData] buffer length, if none is provided.
//const int kDefaultWriteBufferLength = k1MB; //200 * k1MB;

/// A reusable  [WriteBuffer] is stored here.
WriteBuffer _reUseBuffer;

WriteBuffer getWriteBuffer({int length, bool reUseBD = false}) {
  length ??= BufferMixin.kDefaultInitialLength;

  if (!reUseBD || _reUseBuffer == null) return _reUseBuffer = new WriteBuffer(length);

  if (length > _reUseBuffer.lengthInBytes) {
    _reUseBuffer = new WriteBuffer(length + 1024);
    log.warn('**** DicomWriteBuffer creating new Reuse BD of Size: ${_reUseBuffer
    .lengthInBytes}');
  }
  _reUseBuffer.reset;
  return _reUseBuffer;
}

/*
//TODO: make this work for [async] == true and make that the default.
/// Writes [bytes] to [file].
void writeFile(Uint8List bytes, File file) {
  if (file == null) throw new ArgumentError('$file is not a File');
  file.writeAsBytesSync(bytes.buffer.asUint8List());
//    log.debug('Wrote ${bytes.lengthInBytes} bytes to "${file.path}"');
}
*/

/*
//TODO: make this work for [async] == true and make that the default.
/// Writes [bd] to [file] if it is not null or empty.
void _writeFileSync(ByteData bd, File file) {
	final bytes = bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);
	file.writeAsBytesSync(bytes);
}
*/

/*
void _writePathSync(ByteData bd, String path) {
  assert(path != null && path.isNotEmpty);
  if (path.isNotEmpty) _writeFileSync(bd, new File(path));
}
*/


class LoggingDicomWriteBuffer extends DicomWriteBuffer, LoggingWriterMixin {
  LoggingDicomWriteBuffer(
      [int length = kDefaultLength,
        Endian endian = kDefaultEndian,
        int limit = kDefaultLimit])
      : super._(length, endian, limit);

  LoggingDicomWriteBuffer.fromByteData(ByteData bd,
                                       [int offset = 0, int length, Endian endian = kDefaultEndian, int limit])
      : super.fromTypedData(bd, offset, length, endian, limit);

  LoggingDicomWriteBuffer.fromUint8List(Uint8List bytes,
                                        [int offset = 0, int length, Endian endian = kDefaultEndian, int limit])
      : super.fromTypedData(bytes, offset, length, endian, limit);
}
