// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.
library odw.sdk.convert.dcm.dcm_decoder_bytebuf;

import 'dart:typed_data';

import 'package:ascii/ascii.dart';
import 'package:logger/server.dart';
import 'package:bytebuf/bytebuf.dart';

import 'package:odwsdk/attribute.dart';
import 'package:odwsdk/constants.dart';
import 'package:odwsdk/dataset_sop.dart';
import 'package:odwsdk/tag.dart';
import 'package:odwsdk/vr.dart';

//TODO:
//  1. Move all [String] trimming and validation to the Attribute.  The reader
//     and writer should write the values as given.
//  2. Add a mode that will read with/without [String]s padded to an even length
//  3. Add a mode that will write with/without [String]s padded to an even length
//  4. Need a mode where read followed by write will produce two byte for byte identical
//     byte streams.


/// The type of the different Value Field readers.  Each Value Field Reader
/// reads the Value Field Length and the Value Field for a particular Value
/// Representation.
typedef Attribute VFReader(int tag, [VR vr]);


/// A library for parsing [Uint8List] containing DICOM File Format [Dataset]s.
///
/// Supports parsing both [BIG_ENDIAN] and [LITTLE_ENDIAN] format in the
/// super class [ByteBuf]. The default
/// Endianness is the endianness of the host [this] is running on, aka
/// [Endianness.HOST_ENDIAN].
///   * All get* methods _DO NOT_ advance the [readIndex].
///   * All read* methods advance the [readIndex] by the number of bytes read.
///   * All set* methods _DO NOT_ advance the [writeIndex].
///   * All write* methods advance the [writeIndex] by the number of bytes written.
///
/// _Notes_:
///   1. In all cases DcmBuf reads and returns the Value Fields as they, for exampl DcmBuf does
///   not trim whitespace from strings.  This is so they can be written out byte for byte as
///   they were read. and a bytewise comparitor will find them to be equal.
///   2. All String minipulation should be handled in the attribute itself.
///   3. All VFReaders allow the Value Field to be empty.  The [String] [VFReaders] return "",
///   and the Integer, FLoat [VFReaders] return new [null].
class DcmDecoderByteBuf extends ByteBuf {
  static final Logger log = new Logger("DcmDecoderByteBuf", level: Level.debug);

  bool breakOnError = true;

//*** Constructors ***

  /// Creates a new [DcmDecoderByteBuf] of [maxCapacity], where
  ///  [readIndex] = [writeIndex] = 0.
  factory DcmDecoderByteBuf([int lengthInBytes = ByteBuf.defaultLengthInBytes]) {
    if (lengthInBytes == null)
      lengthInBytes = ByteBuf.defaultLengthInBytes;
    if ((lengthInBytes < 0) || (lengthInBytes > ByteBuf.maxMaxCapacity))
      ByteBuf.invalidLength(lengthInBytes);
    return new DcmDecoderByteBuf.internal(new Uint8List(lengthInBytes), 0, 0, lengthInBytes);
  }

  /// Creates a new readable [DcmDecoderByteBuf] from the [Uint8List] [bytes].
  factory DcmDecoderByteBuf.fromByteBuf(DcmDecoderByteBuf buf, [int offset = 0, int length]) {
    length = (length == null) ? buf.bytes.length : length;
    if ((length < 0) || ((offset < 0) || ((buf.bytes.length - offset) < length)))
      ByteBuf.invalidOffsetOrLength(offset, length, buf.bytes);
    return new DcmDecoderByteBuf.internal(buf.bytes, offset, length, length);
  }

  /// Creates a new readable [DcmDecoderByteBuf] from the [Uint8List] [bytes].
  factory DcmDecoderByteBuf.fromUint8List(Uint8List bytes, [int offset = 0, int length]) {
    length = (length == null) ? bytes.length : length;
    if ((length < 0) || ((offset < 0) || ((bytes.length - offset) < length)))
      ByteBuf.invalidOffsetOrLength(offset, length, bytes);
    return new DcmDecoderByteBuf.internal(bytes, offset, length, length);
  }

  /// Creates a [Uint8List] with the same length as the elements in [list],
  /// and copies over the elements.  Values are truncated to fit in the list
  /// when they are copied, the same way storing values truncates them.
  factory DcmDecoderByteBuf.fromList(List<int> list) =>
      new DcmDecoderByteBuf.internal(new Uint8List.fromList(list), 0, list.length, list.length);

  factory DcmDecoderByteBuf.view(ByteBuf buf, [int offset = 0, int length]) {
    length = (length == null) ? buf.bytes.length : length;
    if ((length < 0) || ((offset < 0) || ((buf.bytes.length - offset) < length)))
      ByteBuf.invalidOffsetOrLength(offset, length, buf.bytes);
    Uint8List bytes = buf.bytes.buffer.asUint8List(offset, length);
    return new DcmDecoderByteBuf.internal(bytes, offset, length, length);
  }

  /// Internal Constructor: Returns a [._slice from [bytes].
  DcmDecoderByteBuf.internal(Uint8List bytes, int readIndex, int writeIndex, int length)
      : super.internal(bytes, readIndex, writeIndex, length);

  //**** Methods that Return new [ByteBuf]s.  ****
//TODO: these next three don't do error checking and they should
  /// Creates a new [ByteBuf] that is a view of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  @override
  DcmDecoderByteBuf readSlice(int offset, int length) =>
      new DcmDecoderByteBuf.internal(bytes, offset, length, length);

  /// Creates a new [ByteBuf] that is a view of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  @override
  DcmDecoderByteBuf writeSlice(int offset, int length) =>
      new DcmDecoderByteBuf.internal(bytes, offset, offset, length);

  /// Creates a new [ByteBuf] that is a [sublist] of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  @override
  DcmDecoderByteBuf sublist(int start, int end) =>
      new DcmDecoderByteBuf.internal(bytes, start, end - start, end - start);

  //****  Core Dataset methods  ****

  /// Returns [true] if the next attribute is a File Meta Information tag; otherwise false.
  /// Peeks at the Group part of the next [tag] - doesn't move the [ByteArray.readIndex].
  bool isFmiTag() {
    int group = getUint16(readIndex);
    return group == 0x0002;
  }

  /// Returns [true] if the next attribute is private; otherwise false.
  /// Peeks at the Group part of the next [tag] - doesn't move the [ByteArray.readIndex].
  bool isPrivateTag() {
    int group = getUint16(readIndex);
    return group.isOdd;
  }

  /// Peek at next tag - doesn't move the [ByteArray.position]
  int peekTag() {
    int group = getUint16(readIndex);
    int element = getUint16(readIndex + 2);
    int tag = (group << 16) + element;
    log.finest('peekTag: ${toHexString(tag, 8)}');
    return tag;
  }

  //**** Attribute Reader and Auxillary Methods  ****

  ///TODO: this is expensive! Is there a better way?
  /// Read the DICOM Attribute Tag
  int readTag() {
    int group = readUint16();
    log.finest('\treadTag: group(${toHexString(group, 4)})');
    int element = readUint16();
    log.finest('\treadTag: group(${toHexString(element, 4)})');
    int tag = (group << 16) + element;
    log.finest('\treadTag: ${toHexString(tag, 8)}');
    return tag;
  }

  /// Read the VR as a 16-bit unsigned integer.
  /// Note: The characters are reversed because of Little Endian,
  /// that is, "AE" will have a 16-bit value equivalent to "EA".
  //int readVR() => readUint16();
  int readVR() {
    int a = readUint8();
    int b = readUint8();
    //log.finest("readVR: a=${toHexString(a, 2)}, b=${toHexString(b, 2)}");
    int c = (a << 8) + b;
    log.finest("readVR: c=${toHexString(c, 4)}");
    return c;
  }

  //TODO: implement this for speed - later!
  int readVRInverted() {
    int a = readUint16();
    log.finest("readVR: a=${toHexString(a, 2)}");
    return a;
  }


  /// Read a 16 bit length field and skip the following 16 bits
  int readShortLength() => readUint16();

  void invalidValueFieldLengthError(String msg) {
    log.error(msg);
    if (breakOnError) throw msg;
  }

  /// Converts [lengthInBytes] into element [length].
  int toElementLength(int lengthInBytes, int bytesPerElement) {
    if ((lengthInBytes % bytesPerElement) != 0)
      throw "Invalid LengthInBytes($lengthInBytes) for elementSizeInBytes($bytesPerElement)"
          "the lengthInBytes must be evenly divisible by elementSizeInBytes";
    return lengthInBytes ~/ bytesPerElement;
  }

  /// Skips 2-bytes and then reads and returns a 32-bit length field.
  /// Note: This should only be used for VRs of // OD, OF, OL, UC, UR, UT.
  /// It should not be used for VRs that can have an Undefined Length (-1).
  int readLongLength() {
    skipReadBytes(2);
    return readUint32();
  }

  /// Reads a 32-bit length field that might have an Undefined Length value (0xFFFFFFFF).
  /// If the value is the Undefined Length value, then it searches for the matching
  /// Undefined Length delimiter, and returns the length between them.
  int readLongOrUndefinedLength([int delimiter = kSequenceDelimiterLast16Bits]) {
    int lengthInBytes = readLongLength();
    if (lengthInBytes == kUndefinedLength) {
      lengthInBytes = _getUndefinedLength(delimiter);
      log.finest('hasUndefinedLength: length=$lengthInBytes');
      return lengthInBytes;
    }
    log.debug('readLongOrUndefinedLength: $lengthInBytes');
    return lengthInBytes;
  }

  /// Returns the [length] of an [Item] with undefined length.
  /// The [length] does not include the [kItemDelimitationItem] or the
  /// [kItemDelimitationItem] [length] field, which should be zero.
  int _getUndefinedLength(int delimiter) {
    //Use SetMark mechanism
    int start = readIndex;
    log.finest('_getUndefinedLength: start($start)');
    while (readIndex < writeIndex) {
      int groupNumber = readUint16();
      if (groupNumber == kDelimiterFirst16Bits) {
        int elementNumber = readUint16();
        if (elementNumber == delimiter) {
          int length = (readIndex - 4) - start;
          int itemDelimiterLength = readUint32();
          // Should be 0
          if (itemDelimiterLength != 0) {
            log.warning('encountered non zero length following item delimeter'
                            'at readIndex $readIndex in [_readUndefinedItemLength]');
          }
          log.fine('foundLength: len=$length');
          readIndex = start;
          return length;
        }
      }
      log.fine('_getUndefinedLength: end readIndex($readIndex)');
    }
    // This code should _NOT_ be executed - if we're here there's a problem
    // No [delimiter] item found - issue a warning, silently set the readIndex
    // to the buffer limit and return the length from the offset to the end of the buffer.
    log.warning('encountered end of buffer while looking for ItemDelimiterItem');
    readIndex = writeIndex;
    if (breakOnError) throw "Bad Undefined Length";
    return writeIndex - start;
  }

  //TODO: Move next three to constants
  /// This corresponds to the first 16-bits of [kSequenceDelimitationItem]
  /// and [kItemDelimitationItem] which are the same value.
  static const kDelimiterFirst16Bits = 0xFFFE;

  /// This corresponds to the last 16-bits of [kSequenceDelimitationItem].
  static const kSequenceDelimiterLast16Bits = 0xE0DD;

  /// This corresponds to the last 16-bits of [kItemDelimitationItem].
  static const kItemDelimiterLast16bits = 0xE00D;

  /// This is the top-level entry point for reading an [Attributes].
  Attribute readAttribute() => (isPrivateTag()) ? readPrivateGroup() : _readInternal();

  /// Reads the next [Attribute] in the [ByteBuf]
  Attribute _readInternal() {
    // Attribute Readers
    Map<int, VFReader> vrReaders = {
      0x4145: readAE,
      0x4153: readAS,
      0x4154: readAT,
      // 0x4252: readBR,
      0x4353: readCS,
      0x4441: readDA,
      0x4453: readDS,
      0x4454: readDT,
      0x4644: readFD,
      0x464c: readFL,
      0x4953: readIS,
      0x4c4f: readLO,
      0x4c54: readLT,
      0x4f42: readOB,
      0x4f44: readOD,
      0x4f46: readOF,
      0x4f57: readOW,
      0x504e: readPN,
      0x5348: readSH,
      0x534c: readSL,
      0x5351: readSQ,
      0x5353: readSS,
      0x5354: readST,
      0x544d: readTM,
      0x5543: readUC,
      0x5549: readUI,
      0x554c: readUL,
      0x554e: readUN,
      0x5552: readUR,
      0x5553: readUS,
      0x5554: readUT
    };

    log.level = Level.info;
    int tag = readTag();
    int vrCode = readVR();
    VR vr = VR.map[vrCode];
    VFReader reader = vrReaders[vrCode];

    print('reader: ${reader.runtimeType}, '
                 'tag: ${toHexString(tag, 8)}, '
                 'vrCode: ${toHexString(vrCode, 4)}, '
                 'VR: $vr, '
                 'readIndex: $readIndex');

    if (reader == null) {
      var msg = "Invalid vrCode(${toHexString(vrCode, 4)})";
      log.error(msg);
      throw msg;
    }
    return reader(tag, vr);

  }


  //**** VR Readers ****

  AE readAE(int tag, [VR vr]) {
    assert(vr == VR.kAE);
    return AE.validateValueField(tag, readShortString());
  }

  /*
  AS readAS(int tag, [VR vr]) {
    assert(vr == VR.kAS);
    return AS.validateValueField(tag, readShortString());
  }
  */
  AS readAS(int tag, [VR vr]) {
    assert(vr == VR.kAS);
    var s = readShortString();
    return AS.validateValueField(tag, s);
  }

  AT readAT(int tag, [VR vr]) {
    assert(vr == VR.kAT);
    //Special case becasue [tag]s have to be read specially
    int lengthInBytes = readShortLength();
    int length = toElementLength(lengthInBytes, AT.bytesPerElement);
    Uint32List list = new Uint32List(length);
    for (int i = 0; i < length; i++)
      list[i] = readTag();
    return new AT(tag, list);
  }

  BR readBR(int tag, [VR vr]) {
    assert(vr == VR.kBR);
    throw "Unimplemented";
  }

  CS readCS(int tag, [VR vr]) {
    assert(vr == VR.kCS);
    return CS.validateValueField(tag, readShortString());
  }

  DA readDA(int tag, [VR vr]) {
    return DA.validateValueField(tag, readShortString());
  }

  DS readDS(int tag, [VR vr]) {
    assert(vr == VR.kDS);
    return DS.validateValueField(tag, readShortString());
  }

  DT readDT(int tag, [VR vr]) {
    assert(vr == VR.kDT);
    return DT.validateValueField(tag, readShortString());
  }

  FD readFD(int tag, [VR vr]) {
    assert(vr == VR.kFD);
    int lengthInBytes = readShortLength();
    int length = toElementLength(lengthInBytes, FD.bytesPerElement);
    List<double> doubles = readFloat64List(length);
    return new FD(tag, doubles);
  }

  FL readFL(int tag, [VR vr]) {
    assert(vr == VR.kFD);
    int lengthInBytes = readShortLength();
    int length = toElementLength(lengthInBytes, FL.bytesPerElement);
    List<double> doubles = readFloat32List(length);
    return new FL(tag, doubles);
  }

  IS readIS(int tag, [VR vr]) {
    assert(vr == VR.kIS);
    return IS.validateValueField(tag, readShortString());
  }


  LO readLO(int tag, [VR vr]) {
    assert(vr == VR.kLO);
    return LO.validateValueField(tag, readShortString());
  }

  LT readLT(int tag, [VR vr]) {
    assert(vr == VR.kLT);
    return LT.validateValueField(tag, readShortString());
  }

  // Read an Value Field Length for an Attribute that
  // might have an Undefined Length. OB, OW, UN, SQ, or Item
  OB readOB(int tag, [VR vr]) {
    assert(vr == VR.kOB);
    bool hadUndefinedLength = false;
    int lengthInBytes = readLongLength();
    //print('readOB: tag: ${fmtTag(tag)}, length= $lengthInBytes(${toHexString(lengthInBytes, 8)
    // })');
    if (lengthInBytes == kUndefinedLength) {
      //print('readIndex: $readIndex, lengthInBytes: $lengthInBytes');
      lengthInBytes = _getUndefinedLength(kSequenceDelimiterLast16Bits);
      hadUndefinedLength = true;
      //print('readOW: hadUndefinedLength: readeIndex($readIndex), lengthInBytes($lengthInBytes)');;
    }
    //TODO: use the ByteBuf setMark mechanism
    //setReadIndexMark;
    var values = readUint8List(lengthInBytes);
    //TODO: need hadUndefined Length
    return new OB(tag, values, lengthInBytes, hadUndefinedLength);
  }

  OD readOD(int tag, [VR vr]) {
    assert(vr == VR.kOD);
    int lengthInBytes = readLongLength();
    int length = toElementLength(lengthInBytes, OD.bytesPerElement);
    var values = readFloat64List(length);
    return new OD(tag, values);
  }

  OF readOF(int tag, [VR vr]) {
    assert(vr == VR.kOF);
    int lengthInBytes = readLongLength();
    int length = toElementLength(lengthInBytes, OF.bytesPerElement);
    var values = readFloat32List(length);
    return new OF(tag, values);
  }

  OL readOL(int tag, [VR vr]) {
    assert(vr == VR.kOL);
    int lengthInBytes = readLongLength();
    int length = toElementLength(lengthInBytes, OL.bytesPerElement);
    var values = readUint32List(length);
    return new OL(tag, values);
  }

  // depends on Transfer Syntax
  OW readOW(int tag, [VR vr]) {
    assert(vr == VR.kOW);
    var hadUndefinedLength = false;
    int lengthInBytes = readLongLength();
    //print('readOW: tag: ${fmtTag(tag)}, length= $lengthInBytes(${toHexString(lengthInBytes, 8)
    // })');
    if (lengthInBytes == kUndefinedLength) {
      //print('readIndex: $readIndex, lengthInBytes: $lengthInBytes');
      lengthInBytes = _getUndefinedLength(kSequenceDelimiterLast16Bits);
      hadUndefinedLength = true;
      //print('readOW: hadUndefinedLength: readeIndex($readIndex), lengthInBytes($lengthInBytes)');
    }
    //print('readIndex: $readIndex, lengthInBytes: $lengthInBytes');
    int length = toElementLength(lengthInBytes, OW.bytesPerElement);
    DcmDecoderByteBuf.log.debug('OW: readIndex: $readIndex, writeIndex: $writeIndex');
    DcmDecoderByteBuf.log.debug('OW: length: $length, lengthInBytes: $lengthInBytes');
    //TODO: use the ByteBuf setMark mechanism
    //setReadIndexMark;
    var values = readUint16List(length);
    if (hadUndefinedLength) readIndex += 8;
    return new OW(tag, values, lengthInBytes, hadUndefinedLength);
  }

  PN readPN(int tag, [VR vr]) {
    assert(vr == VR.kPN);
    return PN.validateValueField(tag, readShortString());
  }

  SH readSH(int tag, [VR vr]) {
    assert(vr == VR.kSH);
    return SH.validateValueField(tag, readShortString());
  }

  SL readSL(int tag, [VR vr]) {
    assert(vr == VR.kSL);
    int lengthInBytes = readShortLength();
    int length = toElementLength(lengthInBytes, SL.bytesPerElement);
    Int32List list = readInt32List(length);
    log.fine('SL<int32>: $list');
    return new SL(tag, list);
  }

  SQ readSQ(int tag, [VR vr]) {
    assert(vr == VR.kSQ);
    return readSequence(tag);
  }

  SS readSS(int tag, [VR vr]) {
    assert(vr == VR.kSS);
    int lengthInBytes = readShortLength();
    int length = toElementLength(lengthInBytes, SS.bytesPerElement);
    Int16List list = readInt16List(length);
    log.finest('SS<int16>: $list');
    return new SS(tag, list);
  }

  ST readST(int tag, [VR vr]) {
    assert(vr == VR.kST);
    return ST.validateValueField(tag, readShortString());
  }

  TM readTM(int tag, [VR vr]) {
    assert(vr == VR.kTM);
    return TM.validateValueField(tag, readShortString());
  }

  UC readUC(int tag, [VR vr]) {
    assert(vr == VR.kUC);
    return UC.validateValueField(tag, readLongString());
  }

  UI readUI(int tag, [VR vr]) {
    assert(vr == VR.kUI);
    return UI.validateValueField(tag, readShortString(kUidPaddingChar));
  }

  UL readUL(int tag, [VR vr]) {
    assert(vr == VR.kUL);
    int lengthInBytes = readShortLength();
    print('length: $lengthInBytes');
    int length = toElementLength(lengthInBytes, UL.bytesPerElement);
    print('elementLength: $length');
    Uint32List list = readUint32List(length);
    print('list: $list');
    log.debug('UL<Uint32>: $list');
    return new UL(tag, list);
  }

  UN readUN(int tag, [VR vr]) {
    assert(vr == VR.kUN);
    bool hadUndefinedLength = false;
    int lengthInBytes = readLongLength();
    //print('readOB: tag: ${fmtTag(tag)}, length= $lengthInBytes(${toHexString(lengthInBytes, 8)
    // })');
    if (lengthInBytes == kUndefinedLength) {
      //print('readIndex: $readIndex, lengthInBytes: $lengthInBytes');
      lengthInBytes = _getUndefinedLength(kSequenceDelimiterLast16Bits);
      hadUndefinedLength = true;
      //print('readOW: hadUndefinedLength: readeIndex($readIndex), lengthInBytes($lengthInBytes)');;
    }
    //TODO: use the ByteBuf setMark mechanism
    //setReadIndexMark;
    Uint8List list = readUint8List(lengthInBytes);
    log.finest('UN<Uint8>: $list');
    return new UN(tag, list, lengthInBytes, hadUndefinedLength);
  }

  UR readUR(int tag, [VR vr]) {
    assert(vr == VR.kUR);
    return UR.validateValueField(tag, readLongString());
  }

  US readUS(int tag, [VR vr]) {
    assert(vr == VR.kUS);
    int lengthInBytes = readShortLength();
    int length = toElementLength(lengthInBytes, US.bytesPerElement);
    Uint16List list = readUint16List(length);
    log.finest('US<Uint16>: $list');
    return new US(tag, list);
  }

  /// Unlimited Text (UT) Value Representation
  UT readUT(int tag, [VR vr]) {
    assert(vr == VR.kUT);
    return UT.validateValueField(tag, readLongString());
  }

  /// Returns the [attribute]'s value as a [String].  If [_index] is provided,
  /// the attribute is assumed to be multi-valued and will return the value
  /// specified by index.  [null] is returned if
  ///     1. the attribute does not exist,
  ///     2. there is no component with the specified [index], or
  ///     3. it is zero length.
  ///
  /// Use this function for VRs of type AE, CS, SH and LO
  /// The returned [String] has leading and trailing spaces removed.
  //TODO make the comment correspond to the method
  // VRs AE, CS, DS, IS, LO, PN, SH, UR remove leading and training
  // VRs DT, LT,  ST, TM, UT training only


  //TODO: decide on the recursive structure:
  //    1) should we create the parent then set the object, or
  //    2) should we create and return the object without
  //       the parent and have the parent set it them self
  // lets add the parent after we create the object, i.e. on the
  // way back up from the recursion.
  /// Read a [Sequence][SQ]
  //int _getSequenceLength() => _getUndefinedLength(kSequenceDelimiterLast16Bits);

  //int readSequenceLength() => readLongOrUndefinedLength(kSequenceDelimiterLast16Bits);

  SQ readSequence(int tag) {
    bool hadUndefinedLength = false;
    int lengthInBytes = readLongLength();
    log.debug('readSequence: tag: ${fmtTag(tag)}, '
                  'length= $lengthInBytes(${toHexString(lengthInBytes, 8)})');
    if (lengthInBytes == kUndefinedLength) {
      lengthInBytes = _getUndefinedLength(kSequenceDelimiterLast16Bits);
      hadUndefinedLength = true;
      log.debug('Sequence: hadUndefinedLength: lengthInBytes($lengthInBytes)');
    }

    List<Item> items = <Item>[];
    //TODO: use the ByteBuf setMark mechanism
    //setReadIndexMark;
    int end = readIndex + lengthInBytes;
    while (readIndex < end)
      items.add(readItem(tag));
    SQ sq = new SQ(tag, items, lengthInBytes, hadUndefinedLength);
    for (Item item in items)
      item.sequence = sq;
    return sq;
  }

  int readItemLength() => readLongOrUndefinedLength(kItemDelimiterLast16bits);

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit & readAttributeExplicit
  Item readItem(int sqTag) {
    int tag = readTag();
    if (tag != kItem)
      throw "Bad Item Tag: $tag";
    bool hadUndefinedLength = false;
    // Can't use [readLongLength] because there is no [VR].
    int lengthInBytes = readUint32();
    //TODO have readLongOrUndefinedLength be negaive if it was undefined
    //int lengthInBytes = readLongOrUndefinedLength();
    log.debug('Item: readIndex($readIndex): Item Length: '
                  '$lengthInBytes(${toHexString(lengthInBytes, 8)})');
    if (lengthInBytes == kUndefinedLength) {
      lengthInBytes = _getUndefinedLength(kItemDelimiterLast16bits);
      hadUndefinedLength = true;
      log.debug('Item: hadUndefinedLength: true: found Length:$lengthInBytes');
    }
    Map<int, Attribute> attributes = {};
    //TODO: use the ByteBuf setMark mechanism
    //setReadIndexMark;
    int endOfBytes = readIndex + lengthInBytes;
    while (readIndex < endOfBytes) {
      var a = readAttribute();
      log.debug('readItem: $a');
      attributes[a.tag] = a;
    }
    Item item = new Item(sqTag, attributes, lengthInBytes, hadUndefinedLength);
    log.debug('readItem: item(${fmtTag(sqTag)}, attributes(${attributes.length}), '
                  'Undefined Length: $hadUndefinedLength)');
    return item;
  }

  //**** String Methods ****


  /// Returns a [List] of {String]s with leading and trailing whitespace removed.
  List<String> stringListTrim(List<String> sList) {
    for (int i = 0; i < sList.length; i++)
      sList[i] = sList[i].trim();
    return sList;
  }

  // Returns a [String] without trailing pad character

  String readShortString([int padChar = kSpace]) {
    int lengthInBytes = readShortLength();
    return readDcmString(lengthInBytes, padChar);
  }

  String readLongString([int padChar = kSpace]) {
    int lengthInBytes = readLongLength();
    return readDcmString(lengthInBytes, padChar);
  }

  /// Returns a [String] without trailing padding character.
  /// This calls [getString] in [ByteBuf].
  static const String kSpaceString = " ";
  static final String kNullString = new String.fromCharCode(kNull);
  String readDcmString(int lengthInBytes, [int padChar = kSpace]) {
    if (lengthInBytes == 0) return "";
    if (lengthInBytes.isOdd) throw "Odd length error";
    String s = super.readString(lengthInBytes);
    int last = s.codeUnitAt(s.length - 1);
    if (last == padChar) {
      print('returning substring 1');
      return s.substring(0, s.length - 1);
    } else if ((last == kNull) && (padChar == kSpace)) {
      //TODO: Store this warning with the new attribute
      log.warning('Invalid Nul($last) padChar');
      print('returning substring 2');
      return s.substring(0, s.length - 1);
    } else {
      print('returning string 0');
      return s;
    }
  }

  //Note: private creators are for one group number are all generated before the group tags
  PrivateGroup readPrivateGroup() {
    var pgCreators = <PGCreator>[];
    var creatorTags = <int>[];
    while (isPrivateCreatorTag(peekTag())) {
      var creator = new PGCreator(_readInternal());
      pgCreators.add(creator);
      creatorTags.add(creator.tag);
      log.debug('creators = $pgCreators');
    }
    List<Attribute> pgData = [];
    while (isInPrivateGroup(creatorTags, peekTag())) {
      pgData.add(new PGData(_readInternal()));
      log.debug('data: $pgData');
    }
    return new PrivateGroup(pgCreators, pgData);
  }
}







