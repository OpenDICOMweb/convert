// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.
library odw.sdk.convert.dcm_bytebuf.dcm_bytebuf;

import 'dart:typed_data';

import 'package:ascii/ascii.dart';
import 'package:logger/server_logger.dart';
import 'package:bytebuf/bytebuf.dart';

import 'package:odwsdk/attribute.dart';
import 'package:odwsdk/dataset_sop.dart';
import 'package:odwsdk/src/date_time/date_time.dart';
import 'package:odwsdk/src/person/person.dart';
import 'package:odwsdk/src/vr/vr_class.dart';
import 'package:odwsdk/src/uid/uid.dart';


typedef List VFReader(int tag, int length);

enum Trim {left, right, both, none}

/// This is the value of a DICOM Undefined Length from a 32-bit Value Field Length.
const kDicomUndefinedLength = 0xFFFFFFFF;

//DICOM constant
const kMaxUint8LongLength = 0xFFFFFFFF - 1;

const _MB = 1024 * 1024;
const _GB = 1024 * 1024 * 1024;

Logger log = new Logger("ByteBuf.DcmByteBuf");




//TODO: fix comment
/// A library for parsing [Uint8List], aka [DcmByteBuf]
///
/// Supports parsing both BIG_ENDIAN and LITTLE_ENDIAN byte arrays. The default
/// Endianness is the endianness of the host [this] is running on, aka HOST_ENDIAN.
/// All read* methods advance the [position] by the number of bytes read.
class DcmByteBuf extends ByteBuf {
  //AReader reader;
  //TODO: flush? final List<String> warnings = [];
  bool breakOnError = true;


//*** Constructors ***

  /// Creates a new [DcmByteBuf] of [maxCapacity], where
  ///  [readIndex] = [writeIndex] = 0.
  factory DcmByteBuf([int lengthInBytes = ByteBuf.defaultLengthInBytes]) {
    if (lengthInBytes == null)
      lengthInBytes = ByteBuf.defaultLengthInBytes;
    if ((lengthInBytes < 0) || (lengthInBytes > ByteBuf.maxMaxCapacity))
      ByteBuf.invalidLength(lengthInBytes);
    return new DcmByteBuf._(new Uint8List(lengthInBytes), 0, 0, lengthInBytes);
  }

  /// Creates a new readable [DcmByteBuf] from the [Uint8List] [bytes].
  factory DcmByteBuf.fromByteBuf(DcmByteBuf buf, [int offset = 0, int length]) {
    length = (length == null) ? buf.bytes.length : length;
    if ((length < 0) || ((offset < 0) || ((buf.bytes.length - offset) < length)))
      ByteBuf.invalidOffsetOrLength(offset, length, buf.bytes);
    return new DcmByteBuf._(buf.bytes, offset, length, length);
  }

  /// Creates a new readable [DcmByteBuf] from the [Uint8List] [bytes].
  factory DcmByteBuf.fromUint8List(Uint8List bytes, [int offset = 0, int length]) {
    length = (length == null) ? bytes.length : length;
    if ((length < 0) || ((offset < 0) || ((bytes.length - offset) < length)))
      ByteBuf.invalidOffsetOrLength(offset, length, bytes);
    return new DcmByteBuf._(bytes, offset, length, length);
  }

  /// Creates a [Uint8List] with the same length as the elements in [list],
  /// and copies over the elements.  Values are truncated to fit in the list
  /// when they are copied, the same way storing values truncates them.
  factory DcmByteBuf.fromList(List<int> list) =>
      new DcmByteBuf._(new Uint8List.fromList(list), 0, list.length, list.length);

  factory DcmByteBuf.view(ByteBuf buf, [int offset = 0, int length]) {
    length = (length == null) ? buf.bytes.length : length;
    if ((length < 0) || ((offset < 0) || ((buf.bytes.length - offset) < length)))
      ByteBuf.invalidOffsetOrLength(offset, length, buf.bytes);
    Uint8List bytes = buf.bytes.buffer.asUint8List(offset, length);
    return new DcmByteBuf._(bytes, offset, length, length);
  }

  /// Internal Constructor: Returns a [._slice from [bytes].
  DcmByteBuf._(Uint8List bytes, int readIndex, int writeIndex, int length)
      : super.internal(bytes, readIndex, writeIndex, length);

  //**** Methods that Return new [ByteBuf]s.  ****
//TODO: these next three don't do error checking
  /// Creates a new [ByteBuf] that is a view of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  @override
  DcmByteBuf readSlice(int offset, int length) =>
      new DcmByteBuf._(bytes, offset, length, length);

  /// Creates a new [ByteBuf] that is a view of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  @override
  DcmByteBuf writeSlice(int offset, int length) =>
      new DcmByteBuf._(bytes, offset, offset, length);

  /// Creates a new [ByteBuf] that is a [sublist] of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  @override
  DcmByteBuf sublist(int start, int end) =>
      new DcmByteBuf._(bytes, start, end - start, end - start);

  //TODO: move to ByteBuf - done
  //TODO: remove when ByteBuf tested
  //bool get isReadable => readIndex >= writeIndex;
  //bool get isNotReadable => !isReadable;
  //bool get isWritable => writeIndex >= bytes.lengthInBytes;
  //bool get isNotWritable => writeIndex >= bytes.lengthInBytes;

  //****  Core Dataset methods  ****
  /// Peek at next tag - doesn't move the [ByteArray.position]
  int peekTag() {
    int group = getUint16(readIndex);
    int attribute = getUint16(readIndex + 2);
    //print('grp=$group, elt=$attribute');
    return (group << 16) + attribute;
  }

  ///TODO: this is expensive! Is there a better way?
  /// Read the DICOM Attribute Tag
  int readTag() {
    int group = readUint16();
    int attribute = readUint16();
    return (group << 16) + attribute;
  }

  /// Read the VR as a 16-bit unsigned integer.
  /// Note: The characters are reversed because of Little Endian,
  /// that is, "AE" will have a 16-bit value equivalent to "EA".
  int readVR() => readUint16();


  static const int kMaxShortLengthInBytes = 0xFFFF;
  /// Read a 16 bit length field and skip the following 16 bits
  int readShortLength([int maxLengthInBytes = kMaxShortLengthInBytes]) {
    int lengthInBytes = readUint16();
    if (lengthInBytes > maxLengthInBytes)
      invalidValueFieldLengthError("Value Field with length > $maxLengthInBytes");
    return lengthInBytes;
  }

  static const int kMaxLongLengthInBytes = (1 << 32) - 1;

  /// Skips 2-bytes and then reads and returns a 32-bit length field.
  /// Note: This should only be used for VRs of // OD, OF, OL, UC, UR, UT.
  /// It should not be used for VRs that can have an Undefined Length (-1).
  int readLongLength([int maxLengthInBytes = kMaxLongLengthInBytes]) {
    skipReadBytes(2);
    int lengthInBytes = readUint32();
    //TODO: should this be handled here or by the Attribute reader?
    if (lengthInBytes > maxLengthInBytes) {
      invalidValueFieldLengthError("Value Field with length > $maxLengthInBytes");
    }
    return lengthInBytes;
  }

  void invalidValueFieldLengthError(String msg) {
    log.error(msg);
    if (breakOnError) throw msg;
  }

  // Read an Value Field Length for an Attribute that
  // might have an Undefined Length. OB, OW, UN, SQ, or Item
  int readOBLength() => _readLongOrUndefinedLength(kSequenceDelimitationItemLast16Bits);

  int readOWLength() => _readLongOrUndefinedLength(kSequenceDelimitationItemLast16Bits);

  int readUNLength() => _readLongOrUndefinedLength(kItemDelimitationItemLast16Bits);

  int readSequenceLength() => _readLongOrUndefinedLength(kSequenceDelimitationItemLast16Bits);

  int readItemLength() => _readLongOrUndefinedLength(kItemDelimitationItemLast16Bits);


  //TODO: Document
  static const kDelimitationItemFirst16Bits = 0xFFFE;
  static const kSequenceDelimitationItemLast16Bits = 0xE0DD;
  static const kItemDelimitationItemLast16Bits = 0xE00D;

  int _readLongOrUndefinedLength(int delimiter) {
    int length = readUint32();
    if (length == kDicomUndefinedLength)
      return _getUndefinedLength(delimiter);
    return length;
  }

  /// Returns the [length] of an [Item] with undefined length.
  /// The [length] does not include the [kItemDelimitationItem] or the
  /// [kItemDelimitationItem] [length] field, which should be zero.
  int _getUndefinedLength(int delimiter) {
    int start = readIndex;
    while (readIndex < writeIndex) {
      int groupNumber = readUint16();
      if (groupNumber == kDelimitationItemFirst16Bits) {
        int elementNumber = readUint16();
        if (elementNumber == delimiter) {
          int length = (readIndex - 4) - start;
          int itemDelimiterLength = readUint32();
          // Should be 0
          if (itemDelimiterLength != 0) {
            log.warning('encountered non zero length following item delimeter'
                        'at readIndex $readIndex in [_readUndefinedItemLength]');
          }
          print('foundLength: len=$length');
          return length;
        }
      }
    }
    // This code should not be executed - if we're here there's a problem
    //TODO should this throw an Error?
    // No item delimitation item found - issue a warning, silently set the readIndex
    // to the buffer limit and return the length from the offset to the end of the buffer.
    log.warning('encountered end of buffer while looking for ItemDelimiterItem');
    readIndex = writeIndex;
    return writeIndex - start;
  }

  //**** String Methods ****

  //TODO: flush?: not used
  int _checkStringLength(String s, int min, int max) {
    var length = s.length;
    if ((length < min) || (length > max))
      throw 'Invalid length: min= $min, max=$max, "$s" has length ${s.length}';
    return length;
  }

  //TODO: flush?: not used
  void _checkString(List<String> sList, int min, int max, CharPredicate pred) {
    for (String s in sList) {
      if ((s.length < min) || (s.length > max))
        throw "Invalid Length: $s ($min <= s <= $max)";
      for(int i = 0; i < s.length; i++) {
        int char = s.codeUnitAt(i);
        if (!pred(char))
          throw 'Invalid Character ${s[i]} in "$s"';
      }
    }
  }

  /*
  List<String> StringListTrim(List<String> sList) {
    for (int i = 0; i < sList.length; i++)
      sList[i] = sList[i].trim();
  }
  */

  //TODO: is this needed? it is similar to bytebuf
  // Returns a [String] without trailing pad character
  @override
  String getString(int index, int length) {
    if (length.isOdd) throw "Odd length error";
    if (bytes[index + length - 1] == kSpace) length = length - 1;
    return super.getString(index, length);
    //return bytes.sublist(offset, length).toString();
  }

  //TODO: do we need this or is the one in ByteBuf enough?
  @override
  String readString(int length) => getString(readIndex, length);

  // Returns a [String] without trailing pad character
  String getShortString(int offset, [int maxLengthInBytes = kMaxShortLengthInBytes]) {
    int lengthInBytes = readShortLength(maxLengthInBytes);
    if (lengthInBytes.isOdd) throw "Odd length error";
    if (bytes[offset + lengthInBytes - 1] == kSpace) lengthInBytes = lengthInBytes - 1;
    return bytes.sublist(offset, lengthInBytes).toString();
  }

  String readShortString(int lengthInBytes) =>
      getShortString(readIndex, lengthInBytes);

  // Returns a [String] without trailing pad character
  String getLongString(int offset, [int maxLengthInBytes = kMaxLongLengthInBytes]) {
    int lengthInBytes = readLongLength(maxLengthInBytes);
    if (lengthInBytes.isOdd) throw "Odd length error";
    if (bytes[offset + lengthInBytes - 1] == kSpace)
      lengthInBytes = lengthInBytes - 1;
    return bytes.sublist(offset, lengthInBytes).toString();
  }

  String readLongString(int maxLength) => getLongString(readIndex, maxLength);


  //TODO: should this be reading a list or a String
  /// Returns a [Uid} [String] without trailing pad character
  String getUidString(int offset, int length) {
    if (length.isOdd) throw "Odd length error";
    if (bytes[offset + length - 1] == kNull) length = length - 1;
    //return super.readStringList(offset, length);
    return super.getString(offset, length);
    //flush: was returning slice.
    //return bytes.sublist(offset, length).toString();
  }

  String readUidString(int length) => getUidString(readIndex, length);


  //TODO: flush?
  /*
  List<String> readStringListChecking(int length, [int min = 0, int max]) {
    var sList = getStringList(readIndex, length);
    checkStringList(sList, min, max, pred);
    for(int i = 0; i < sList.length; i++) {
      var s = sList[i];
      if (max != null) _checkStringLength(s, min, max);
      sList[i] = s.trim();
    }
    return sList;
  }
  */

  //TODO: flush?
  List<String> readStringListTrim(int length, [int min = 0, int max]) {
    var sList = readStringList(length);
    for(int i = 0; i < sList.length; i++) {
      var s = sList[i];
      if (max != null) _checkStringLength(s, min, max);
      sList[i] = s.trim();
    }
    return sList;
  }

  //TODO: flush?
  checkStringList(List<String> sList, int min, int max, CharPredicate pred) {
    for (int i = 0; i < sList.length; i++) {
      var s = sList[i];
      if (max != null) _checkStringLength(s, min, max);
      sList[i] = s.trim();
    }
    return sList;
  }

  //TODO: flush?
 List<String> StringListTrim(List<String> sList) {
   for (int i = 0; i < sList.length; i++)
     sList[i] = sList[i].trim();
   return sList;
 }

  //TODO: flush?
  List<String> readStringListTrimRight(int length, [int min = 0, int max]) {
    var sList = readStringList(length);
    for(int i = 0; i < sList.length; i++) {
      var s = sList[i];
      if (max != null) _checkStringLength(s, min, max);
      sList[i] = s.trimRight();
    }
    return sList;
  }

  //TODO: flush?
  List<String> getStringListTrimRight(int offset, int length, [int min = 0, int max]) {
    var s = getString(offset, length);
    var sList = s.split('\\');
    for(int i = 0; i < sList.length; i++) {
      var ss = sList[i];
      if (max != null) _checkStringLength(ss, min, max);
      sList[i] = ss.trim();
    }
    return sList;
  }

  //TODO: flush?
  String getStringTrimRight(int offset, int length, int minLength, int maxLength) =>
      bytes.sublist(offset, length).toString().trimRight();

  //TODO: flush?
  /*
  String readStringTrim(int length, [int min = 0, int max]) {
    if (max != null) _checkStringLength();
    var s = getStringTrim(readIndex, length);
    _checkStringLength(s, minLength, maxLength);
    readIndex += length;
    return s;
  }
  */
  List attibuteClasses = [
    AE, AS, AT, AS
  ];

  Attribute readExplicitAttribute(DcmByteBuf buf) {
    int tag = buf.readTag();
    int vr = buf.readVR();
    int vrIndex = VR.indexOf(vr);
    return attibuteClasses[vrIndex].read(tag, vr, buf);
  }

  List readValues(tag) {
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
    return vrReaders[vr](tag);
  }

  int _readUint16Length() {
    var lengthInBytes = readShortLength();
    if (lengthInBytes != 4) throw "Invalid Length: $lengthInBytes";
    return lengthInBytes;
  }

  //TODO: merge with readShortLength
  int validShortLength(int elementSizeInBytes) {
    int lengthInBytes = readShortLength();
    if ((lengthInBytes % elementSizeInBytes) != 0) throw "Invalid length error: $lengthInBytes";
    return lengthInBytes ~/ elementSizeInBytes;
  }
  AS readAS(int tag) {
    var lengthInBytes = readShortLength();
    if (lengthInBytes != 4) throw "Invalid Length: $lengthInBytes";
    var age = readString(lengthInBytes);
    //TODO: create an age object
    return new AS(tag, [age]);
  }

  AT readAT(int tag) {
    int length = validShortLength(4);
    Uint32List list = new Uint32List(length);
    for (int i = 0; i < length; i++)
      list[i] = readTag();
    return new AT(tag, list);;
  }

  // List<String> readBR(int tag, int length) => readStringListTrim(4, 4,length);
  List<String> readCS(int tag, int length) => readStringListTrim(1, 16, length);

  List<Date> readDA(int tag) {
    int lengthInBytes = validShortLength(1);
    List<String> slist = readStringList(lengthInBytes);
    List<Date> dates = new List(slist.length);
    for (int i = 0; i < slist.length; i++)
      dates[i] = Date.parse(slist[i]);
    return dates;
  }

  List<double> readDS(int length) {
    int lengthInBytes = validShortLength(1);
    List<String> strings = readStringListTrimRight(lengthInBytes, 1, 16);
    List<double> doubles = [];
    for (String s in strings) {
      if ((s.length < 1) || (s.length > 16))
        throw "Invalid DS Length: ${s.length}";
      doubles.add(double.parse(s));
    }
    return doubles;
  }

  List<DcmDateTime> readDT(int length) {
    List<String> slist = readStringListTrim(length, 0, 16);
    List<DcmDateTime> dts = new List<DcmDateTime>(slist.length);
    for (int i = 0; i < slist.length; i++)
      dts[i] = DcmDateTime.parse(slist[i]);
    return dts;
  }

  List<double> readFD(int length) => readFloat64List(length);

  List<double> readFL(int length) => readFloat32List(length);

  List<String> readIS(int length) => readStringListTrim(1, 12, length);

  List<String> readLO(int length) => readStringListTrim(length, 1, 64);

  List<String> readLT(int length) => readText(length, 1, 10240);

  Uint8List readOB(int length) => readUint8List(length);

  Float64List readOD(int length) => readFloat64List(length);

  Float32List readOF(int length) => readFloat32List(length);

  Uint32List readOL(int length) => readUint32List(length);

  // depends on Transfer Syntax
  Uint16List readOW(int length) => readUint16List(length);

  // depends on Transfer Syntax
  List<PersonName> readPN(int length) => readPersonNameList(length);

  List<String> readSH(int length) => readStringListTrim(1, 16, length);

  Int32List readSL(int length) => readInt32List(length);

  SQ readSQ(int length) => readSequence(length);

  Int16List readSS(int length) => readInt16List(length);

  List<String> readST(int length) => readText(length, 1, 1024);

  List<Time> readTM(int length) {
    var slist = readStringListTrimRight(length, 2, 14);
    var times = new List<Time>(slist.length);
    for (int i = 0; i < slist.length; i++)
      times[i] = Time.parse(slist[i]);
    return times;
  }

  List<String> readUC(int length) => readStringListTrimRight(1, kMaxUint8LongLength, length);

  List<Uid> readUI(int length) {
    var list = readStringList(length);
    List<Uid> uids = [];
    for (String s in list) {
      if ((s.length < 6) || (s.length > 64))
        throw "Invalid Length for UID: ${s.length}";
      uids.add(Uid.parse(s));
    }
    return uids;
  }

  Uint32List readUL(int length) => readUint32List(length);

  Uint8List readUN(int length) => readUint8List(length);

  Uri readUR(int length) {
    var s = readString(length);
    if (s[s.length - 1] == 0) s = s.substring(0, length - 1);
    return Uri.parse(s);
  }

  List<int> readUS(int length) => readUint16List(length);

  List<String> readUT(int length) => readText(length, 1, kMaxUint8LongLength);

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

  int _getSequenceLength() => _getUndefinedLength(kSequenceDelimitationItemLast16Bits);

  //TODO: decide on the recursive structure:
  //    1) should we create the parent then set the object, or
  //    2) should we create and return the object without
  //       the parent and have the parent set it them self
  // lets add the parent after we create the object, i.e. on the
  // way back up from the recursion.
  /// Read a [Sequence] with *Known Length*.
  SQ readSequence(int tag) {
    bool hadUndefinedLength = true;

    int getSequenceLength() {
      int length = readUint32();
      if (length == kDicomUndefinedLength) {
        hadUndefinedLength = true;
        length = _getSequenceLength();
      }
      return length;
    }

    int length = getSequenceLength();
    List<Item> items = <Item>[];
    while (readIndex < (readIndex + length))
      items.add(readItem(tag));
    SQ sq = new SQ(tag, items, hadUndefinedLength);
    for (Item item in items)
      item.sequence = sq;
    return sq;
  }

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit & readAttributeExplicit
  Item readItem(int seqTag) {
    bool hadUndefinedLength = false;
    int length = readUint32();
    if (length == kDicomUndefinedLength) {
      length = _getUndefinedLength(kItemDelimitationItemLast16Bits);
      hadUndefinedLength = true;
    }
    Map<int, Attribute> attributes = {};
    while (readIndex < (readIndex + length)) {
      var attribute = readAttribute(seqTag, null);
      attributes[attribute.tag] = attribute;
    }
    Item item = new Item(attributes, seqTag, hadUndefinedLength);
    print('readItem: $item($seqTag, $attributes, $hadUndefinedLength)');
    return item;
  }



/*
  /// Returns a [String] with the leading spaces preserved and trailing spaces removed.
  /// Use this function to access the value for attributes with VRs of type UT, ST and LT

  /// Returns a [String] with the leading spaces preserved and trailing spaces removed.
  /// Use this function to access the value for attributes with VRs of type UT, ST and LT
  String getDcmText(int offset, int length) {
    var s = readStringTrimRight(length);
    return ((s != null) && (s != "")) ? s : null;
  }

  String readDcmText(int length) {
    var s = getDcmText(readIndex, length);
    readIndex += length;
    return s;
  }
*/


  String bytesToString(Uint8List bytes, [int start = 0, int end]) {
    end = (end == null) ? bytes.length : end;
    assert((end - start).isOdd);
    if (bytes[end - 1] == kSpace) end = end - 1;
    return bytes.sublist(start, end).toString();
  }
}




