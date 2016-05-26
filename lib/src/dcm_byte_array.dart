// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.
library odw.sdk.dicom.convert.dcm_byte_array;

import 'dart:typed_data';

import 'package:ascii/ascii.dart';
import 'package:attribute/attribute.dart';
import 'package:dataset/dataset.dart';
//import 'package:date_time/date_time.dart';
//import 'package:uid/uid.dart';

import 'byte_array.dart';

typedef Attribute AReader(tag, vr);

typedef List VFReader(int tag, int length);

enum Trim {left, right, both, none}

//TODO: fix comment
/// A library for parsing [Uint8List], aka [DcmByteArray]
///
/// Supports parsing both BIG_ENDIAN and LITTLE_ENDIAN byte arrays. The default
/// Endianness is the endianness of the host [this] is running on, aka HOST_ENDIAN.
/// All read* methods advance the [position] by the number of bytes read.
class DcmByteArray extends ByteArray {
  //AReader reader;
  final List<String> warnings = [];
  bool breakOnError = true;

  DcmByteArray(Uint8List bytes, [int start = 0, int length])
      : super(bytes, start, length);

  DcmByteArray.ofLength([start = 0, int length])
      : super(new Uint8List(length), start, length);

  DcmByteArray.fromBuffer(ByteBuffer buffer, [int start = 0, int length])
      : super(buffer.asUint8List(), start, length);

  DcmByteArray.view(DcmByteArray buf, [int start = 0, int length])
      : super(buf.bytes, start, length);

  DcmByteArray slice(int start, [int length]) {
    if (length == null) length = end;
    return new DcmByteArray(bytes, start, end);
  }

  //****  Core Dataset methods  ****
  /// Peek at next tag - doesn't move the [ByteArray.position]
  int peekTag() {
    int group = getUint16(position);
    int attribute = getUint16(position + 2);
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


  /// Read a 16 bit length field and skip the following 16 bits
  int readShortLength(int maxLength) {
    int length = readUint16();
    if (length > maxLength)
      InvalidValueFieldLengthError("Value Field with length > $maxLength");
    return length;
  }


  /// Skips 2-bytes and then reads and returns a 32-bit length field.
  /// Note: This should only be used for VRs of // OD, OF, OL, UC, UR, UT.
  /// It should not be used for VRs that can have an Undefined Length (-1).
  int readLongLength(int maxLength) {
    seek(2);
    int length = readUint32();
    //TODO: should this be handled here or by the Attribute reader?
    if (length > maxLength) {
      InvalidValueFieldLengthError("Value Field with length > $maxLength");
    }
    return length;
  }

  void InvalidValueFieldLengthError(String msg) {
    //log.error(msg);
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
    if (length == Dicom.kMinusOneAsUint32)
      return _getUndefinedLength(delimiter);
    return length;
  }

  /// Returns the [length] of an [Item] with undefined length.
  /// The [length] does not include the [kItemDelimitationItem] or the
  /// [kItemDelimitationItem] [length] field, which should be zero.
  int _getUndefinedLength(int delimiter) {
    int start = position;
    while (position < end) {
      int groupNumber = readUint16();
      if (groupNumber == kDelimitationItemFirst16Bits) {
        int elementNumber = readUint16();
        if (elementNumber == delimiter) {
          int length = (position - 4) - start;
          int itemDelimiterLength = readUint32();
          // Should be 0
          if (itemDelimiterLength != 0) {
            warning('encountered non zero length following item delimeter'
                        'at position ${position} in [_readUndefinedItemLength]');
          }
          print('foundLength: len=$length');
          return length;
        }
      }
    }
    // This code should not be executed - if we're here there's a problem
    //TODO should this throw an Error?
    // No item delimitation item found - issue a warning, silently set the position
    // to the buffer limit and return the length from the offset to the end of the buffer.
    warning('encountered end of buffer while looking for ItemDelimiterItem');
    position = limit;
    return limit - start;
  }

  //**** String Methods ****

  int _checkStringLength(String s, int min, int max) {
    var length = s.length;
    if ((length < min) || (length > max))
      throw 'Invalid length: min= $min, max=$max, "$s" has length ${s.length}';
    return length;
  }

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

  // Returns a [String] without trailing pad character
  String getString(int offset, int length) {
    if (length.isOdd) throw "Odd length error";
    if (bytes[offset + length - 1] == kSpace) length = length - 1;
    return bytes.sublist(offset, length).toString();
  }

  String readString(int length) => getString(position, length);

  // Returns a [String] without trailing pad character
  String getShortString(int offset, maxLength) {
    int length = readShortLength(maxLength);
    if (length.isOdd) throw "Odd length error";
    if (bytes[offset + length - 1] == kSpace) length = length - 1;
    return bytes.sublist(offset, length).toString();
  }

  String readShortString(int maxLength) => getShortString(position, maxLength);

  // Returns a [String] without trailing pad character
  String getLongString(int offset, maxLength) {
    int length = readLongLength(maxLength);
    if (length.isOdd) throw "Odd length error";
    if (bytes[offset + length - 1] == kSpace) length = length - 1;
    return bytes.sublist(offset, length).toString();
  }

  String readLongString(int maxLength) => getLongString(position, maxLength);



  // Returns a [String] without trailing pad character
  getUidString(int offset, int length) {
    if (length.isOdd) throw "Odd length error";
    if (bytes[offset + length - 1] == kNull) length = length - 1;
    return bytes.sublist(offset, length).toString();
  }

  readUidString(int length) => getUidString(position, length);

  List<String> getStringList(int offset, int length) {
    var s = getString(offset, length);
    return s.split('\\');
  }

  List<String> readStringList(int length) => getStringList(position, length);

  /*
  List<String> readStringListChecking(int length, [int min = 0, int max]) {
    var sList = getStringList(position, length);
    _checkStrings(sList, pred, min, max);
    for(int i = 0; i < sList.length; i++) {
      var s = sList[i];
      if (max != null) _checkStringLength(s, min, max);
      sList[i] = s.trim();
    }
    return sList;
  }

  List<String> readStringListTrim(int length, [int min = 0, int max]) {
    var sList = readStringList(length);
    for(int i = 0; i < sList.length; i++) {
      var s = sList[i];
      if (max != null) _checkStringLength(s, min, max);
      sList[i] = s.trim();
    }
    return sList;
  }

  checkStringList(List<String> sList, int min, int max, CharPredicate pred) {
    for (int i = 0; i < sList.length; i++) {
      var s = sList[i];
      if (max != null) _checkStringLength(s, min, max);
      sList[i] = s.trim();
    }
    return sList;
  }
 List<String> StringListTrim(List<String> sList) {
   for(int i = 0; i < sList.length; i++)
     sList[i] = sList[i].trim();
   return sList;
 }

  List<String> readStringListTrimRight(int length, [int min = 0, int max]) {
    var sList = readStringList(length);
    for(int i = 0; i < sList.length; i++) {
      var s = sList[i];
      if (max != null) _checkStringLength(s, min, max);
      sList[i] = s.trimRIght();
    }
    return sList;
  }

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


  String getStringTrimRight(int offset, int length, int minLength, int maxLength) =>
      bytes.sublist(offset, length).toString().trimRight();


  String readStringTrim(int length, [int min = 0, int max]) {

    if (max != null) _checkLength()
    var s = getStringTrim(position, length);
    _checkStringLength(s, minLength, maxLength);
    position += length;
    return s;
  }

  List attibuteClasses = [
    AE, AS, AT, AS
  ];

  Attribute readExplicitAttribute(DcmByteArray buf) {
    int tag = buf.readTag();
    int vr = buf.readVR();
    int vrIndex = VR.indexOf(vr);
    return attibuteClasses[vrIndex].read(tag, vr, buf);
  }



  List readValues(tag, vr) {
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
    return vrReaders[vr](tag, vr);
  }


  List<String> readAS(int tag, VR vr) {
    var length = readShortLength();
    if (length != 4) throw "Invalid Length: $length";
    //TODO: create an age object
    return new AS(tag, vr, [readString(length)]);
  }

  List<int> readAT(int length) {
    if ((length % 4) != 0) throw "Invalid length error: $length";
    int len = length ~/ 4;
    Uint32List list = new Uint32List(len);
    for (int i = 0; i < len; i++)
      list[i] = readTag();
    return list;
  }

  // List<String> readBR(int tag, int length) => readStringListTrim(4, 4,length);
  List<String> readCS(int length) => readStringListTrim(1, 16, length);

  List<Date> readDA(int length) {
    List<String> slist = readStringList(length);
    List<Date> dates = new List(slist.length);
    for (int i = 0; i < slist.length; i++)
      dates[i] = Date.parse(slist[i]);
    return dates;
  }

  List<double> readDS(int length) {
    List<String> strings = readStringListTrimRight(length, 1, 16);
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

  List<String> readLT(int length) => _readText(length, 1, 10240);

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

  SQ readSQ(int length) => _readSequence(length);

  Int16List readSS(int length) => readInt16List(length);

  List<String> readST(int length) => _readText(length, 1, 1024);

  List<Time> readTM(int length) {
    var slist = readStringListTrimRight(length, 2, 14);
    var times = new List<Time>(slist.length);
    for (int i = 0; i < slist.length; i++)
      times[i] = Time.parse(slist[i]);
    return times;
  }

  List<String> readUC(int length) => readStringListTrimRight(1, Dicom.kMaxLongLength, length);

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

  List<String> readUT(int length) => _readText(length, 1, Dicom.kMaxLongLength);
*/
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




  int getSequenceLength(int endTag) {
    int length = readUint32();
    if (length == Dicom.kMinusOneAsUint32) {
      length = _getUndefinedLength(kSequenceDelimitationItemLast16Bits);
    }
    return length;
  }

  //TODO: decide on the recursive structure:
  //    1) should we create the parent then set the object, or
  //    2) should we create and return the object without
  //       the parent and have the parent set it them self
  // lets add the parent after we create the object, i.e. on the
  // way back up from the recursion.
  /// Read a [Sequence] with *Known Length*.
  SQ _readSequence(int tag) {
    bool hadUndefinedLength = false;
    int length = readUint32();
    if (length == Dicom.kUndefinedLength) {
      length = _getUndefinedLength(kSequenceDelimitationItemLast16Bits);
      hadUndefinedLength = true;
    }
    List<Item> items = <Item>[];
    while (position < (position + length))
      items.add(_readItem(tag));
    var sq = new SQ(tag, vr, items, hadUndefinedLength);
    //Fix or remove
    // for (Item item in items)
    //   item.sequence = sq;
    return sq;
  }

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit & readAttributeExplicit
  Item _readItem(int seqTag) {
    bool hadUndefinedLength = false;
    int length = readUint32();
    if (length == Dicom.kUndefinedLength) {
      length = _getUndefinedLength(kItemDelimitationItemLast16Bits);
      hadUndefinedLength = true;
    }
    Map<int, Attribute> attributes = {};
    while (position < (position + length)) {
      var attribute = reader(seqTag, null);
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
    var s = getDcmText(position, length);
    position += length;
    return s;
  }
*/


  /// Add a warning string to the [List<String>] of [warnings] associated with the [Dataset].
  void warning(String s) {
    print(s);
    warnings.add(s);
  }

  String bytesToString(Uint8List bytes, [int start = 0, int end]) {
    end = (end == null) ? bytes.length : end;
    assert((end - start).isOdd);
    if (bytes[end - 1] == kSpace) end = end - 1;
    return bytes.sublist(start, end).toString();
  }
}




