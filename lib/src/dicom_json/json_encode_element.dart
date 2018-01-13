// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:logger/logger.dart';

import 'package:core/core.dart';
import 'package:core/core.dart';
import 'json_type.dart';

//TODO:
//  1. Move all [String] trimming and validation to the Element.  The reader
//     and writer should write the values as given.
//  3. Add a mode that will write with/without [String]s padded to an even length
//  4. Need a mode where read followed by write will produce two byte for byte identical
//     byte streams.


typedef void VFWriter(Element a);

const kMB = 1024 * 1024;
/// A library for parsing [Uint8List] containing DICOM File Format [Dataset]s.
///
/// Supports parsing both BIG_ENDIAN and LITTLE_ENDIAN format in the
/// super class [ByteBuf]. The default
/// Endianness is the endianness of the host [this] is running on, aka
/// [Endianness.HOST_ENDIAN].
///   * All get* methods _DO NOT_ advance the [readIndex].
///   * All read* methods advance the [readIndex] by the number of bytes written.
///   * All set* methods _DO NOT_ advance the [writeIndex].
///   * All write* methods advance the [writeIndex] by the number of bytes written.
///
/// _Notes_:
///   1. In all cases DcmBuf writes the Value Fields as they are without modification, except
///   possibly padding strings to an even length.  This is so they can be written out byte for
///   byte as they were read, and a bytewise comparator will find them to be equal.
///   2. All String manipulation should be handled in the attribute itself.
///   3. All VRWriters allow the Value Field to be empty.
class JsonEncodeBuffer {
    static const defaultLengthInBytes = 1 * kM;
    static final Logger log = new Logger("JsonEncodeBuffer");

    bool breakOnError = true;
    final JsonType type;
    final Formatter fmt;
    String _out;

    //*** Constructors ***
    //TODO: what should the default length be

    /// Creates a new [DcmEncoderByteBuf] of [maxCapacity], where
    ///  [readIndex] = [encodeIndex] = 0.
    JsonEncodeBuffer(this.type, [String out = "", this.fmt]);

    String addSlice(String s, [int offset= 0, int length]) {
      length = ((length == null) || (length > s.length)) ? s.length : length;
      return _out += s.substring(offset, length);
    }


    //****  Core Dataset methods  ****

    //TODO: move to better place tag_utils? fmiUtils?
    /// Returns [true] if the next attribute is a File Meta Information tag; otherwise false.
    /// Peeks at the Group part of the next [tag] - doesn't move the [ByteArray.readIndex].
    bool isFmiTag(Element e) {
        int group = tagGroup(e.tag);
        return group == 0x0002;

    //**** Element writer and Auxillary Methods  ****

    ///TODO: this is expensive! Is there a better way?
    /// write the DICOM Element Tag
    void writeTag(int tag) {
      String s = tagToJson(tag)

    }

    /// write the VR as a 16-bit unsigned integer.
    /// Note: The characters are reversed because of Little Endian,
    /// that is, "AE" will have a 16-bit value equivalent to "EA".
    //int writeVR() => writeUint16();
    void writeVR(int vrCode) {
        int a = vrCode >> 8;
        writeUint8(a);
        int b = vrCode & 0xFF;
        writeUint8(b);
        //log.finest("writeVR: a=${toHexString(a, 2)}, b=${toHexString(b, 2)}");
    }

    //TODO: implement this for speed - later!
    void writeVRInverted(int code) {
        writeUint16(code);
        log.finest("writeVR: code=${toHexString(code, 2)}");
    }

    static const int kMaxShortLengthInBytes = 0xFFFF;

    void writeLength(int lengthInBytes, bool isShort) {
        if (isShort) {
            writeShortLength(lengthInBytes);
        } else {
            writeLongLength(lengthInBytes);
        }
    }

    /// write a 16 bit length field and skip the following 16 bits
    void writeShortLength(int lengthInBytes) {
        writeUint16(lengthInBytes);
    }

    //TODO: move to constants
    static const int kMaxLongLengthInBytes = (1 << 32) - 1;

    /// Skips 2-bytes and then writes and returns a 32-bit length field.
    /// Note: This should only be used for VRs of // OD, OF, OL, UC, UR, UT.
    /// It should not be used for VRs that can have an Undefined Length (-1).
    void writeLongLength(int lengthInBytes) {
        writeUint16(0);
        writeUint32(lengthInBytes);
    }

    /// writes a 32-bit length field that might have an Undefined Length value (0xFFFFFFFF).
    /// If the value is the Undefined Length value, then it searches for the matching
    /// Undefined Length delimiter, and returns the length between them.
    JsonEncodeBuffer writeUndefinedLength() => writeUint32(0xFFFFFFFF);

    JsonEncodeBuffer writeSequenceDelimiter() => writeUint32(kSequenceDelimitationItem);

    JsonEncodeBuffer writeItemDelimiter() => writeUint32(kItemDelimitationItem);

    /* flush?
  int writeValueWithUndefinedLength(Uint8List bytes, [int delimiter = kSequenceDelimitationItem]) {
    int lengthInBytes = writeLongLength();
    if (lengthInBytes == kDicomUndefinedLength) {
      lengthInBytes = _getUndefinedLength(delimiter);
      log.finest('hasUndefinedLength: length=$lengthInBytes');
      return lengthInBytes;
    }
    return lengthInBytes;
  }
  */


    /// Returns the [length] of an [Item] with undefined length.
    /// The [length] does not include the [kItemDelimitationItem] or the
    /// [kItemDelimitationItem] [length] field, which should be zero.
    /*
  int _getUndefinedLength(int delimiter) {
    int start = readIndex;
    log.finest('_getUndefinedLength: start($start)');
    while (readIndex < writeIndex) {
      writeUint16(tagGroup(tag));
      writeUint16(tagElement(tag));
        if (elementNumber == delimiter) {
          int length = (readIndex - 4) - start;
          int itemDelimiterLength = readUint32();
          // Should be 0
          if (itemDelimiterLength != 0) {
            log.warning('encountered non zero length following item delimeter'
                            'at readIndex $readIndex in [_readUndefinedItemLength]');
          }
          log.fine('foundLength: len=$length');
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
  */
    //TODO: Move next three to constants
    //Flush
    /// This corresponds to the first 16-bits of [kSequenceDelimitationItem]
    /// and [kItemDelimitationItem] which are the same value.
    static const kDelimiterFirst16Bits = 0xFFFE;

    /// This corresponds to the last 16-bits of [kSequenceDelimitationItem].
    static const kSequenceDelimiterLast16Bits = 0xE0DD;

    /// This corresponds to the last 16-bits of [kItemDelimitationItem].
    static const kItemDelimiterLast16bits = 0xE00D;

    /// Returns an [Element] or [null].
    ///
    /// This is the top-level entry point for writeing a [Dataset].
    void writeDataset(Map<int, Element> aMap) {
        final Logger log = new Logger("Write Dataset");
        for (Element a in aMap.values) {
            if (isNotWritable)
                throw "End of buffer error: $this";
            if (a.tag == kPixelData) {
                log.info('PixelData: ${tagToHex(a.tag)}, ${a.vr}, length= ${a.values.length}');
                writePixelData(a);
            } else {
                encodeElement(a);
            }
        }
        log.info('DcmWriteBuf: $this');
    }

    /// This is the top-level entry point for writing an [Elements].
    void encodeElement(Element a) {
        //TODO: private group should be handled the same. this if shouldn't be needed.
        if (a is PrivateGroup) {
            writePrivateGroup(a);
        } else {
            _writeInternal(a);
        }
        //print('before: $a');
        //a = (a is PGData) ? a.data : a;
        //print('after: $a');

        print(a.debug());
    }


    /// writes the next [Element] in the [ByteBuf]
    void _writeInternal(Element a) {
        // Element writers
        Map<int, VFWriter> vfWriter = {
            0x4145: writeAE,
            0x4153: writeAS,
            0x4154: writeAT,
            // 0x4252: writeBR,
            0x4353: writeCS,
            0x4441: writeDA,
            0x4453: writeDS,
            0x4454: writeDT,
            0x4644: writeFD,
            0x464c: writeFL,
            0x4953: writeIS,
            0x4c4f: writeLO,
            0x4c54: writeLT,
            0x4f42: writeOB,
            0x4f44: writeOD,
            0x4f46: writeOF,
            0x4f57: writeOW,
            0x504e: writePN,
            0x5348: writeSH,
            0x534c: writeSL,
            0x5351: writeSQ,
            0x5353: writeSS,
            0x5354: writeST,
            0x544d: writeTM,
            0x5543: writeUC,
            0x5549: writeUI,
            0x554c: writeUL,
            0x554e: writeUN,
            0x5552: writeUR,
            0x5553: writeUS,
            0x5554: writeUT
        };
        if (isNotWritable) {
            var msg = "Write Buffer empty: readIndex($readIndex), writeIndex($writeIndex)";
            log.error(msg);
            throw msg;
        }

        //print('_writeInteral: $a');
        writeTag(a.tag);
        int vrCode = a.vr.code;
        writeVR(vrCode);
        log.debug('write: $a');
        VFWriter writer = vfWriter[vrCode];

        var values = a.values;
        bool shouldPrint = true;
        if (shouldPrint) {
            print('writer: ${writer.runtimeType}, '
                      'tag: ${toHexString(a.tag, 8)}, '
                      'vrCode: ${toHexString(vrCode, 4)}, '
                      'VR: ${a.vr}, '
                      'values: $values. '
                  // 'length: ${values.length}, '
                      'writeIndex: $writeIndex');
            print('values: ${a.values}');
        }
        if (writer == null) {
            var msg = "Invalid vrCode(${toHexString(vrCode, 4)})";
            log.error(msg);
            throw msg;
        }
        writer(a);
    }


    //**** VR writers ****

    void writeAE(AE a) {
        assert(a.vr == VR.kAE);
        if (a is AE) writeShortDcmString(a);
    }

    void writeAS(AS a) {
        assert(a.vr == VR.kAS);
        writeShortDcmString(a);
    }

    void writeAT(AT a) {
        assert(a.vr == VR.kAT);
        writeDcmUint32List(a.values);
    }

    void writeBR(BR a) {
        assert(a.vr == VR.kBR);
        throw "Unimplemented";
    }

    void writeCS(CS a) {
        assert(a.vr == VR.kCS);
        writeShortDcmString(a);
    }

    void writeDA(DA a) {
        writeShortDcmString(a);
    }

    void writeDS(DS a) {
        assert(a.vr == VR.kDS);
        writeShortDcmString(a);
    }

    void writeDT(DT a) {
        assert(a.vr == VR.kDT);
        writeShortDcmString(a);
    }

    void writeFD(FD a) {
        assert(a.vr == VR.kFD);
        writeDcmFloat64List(a.values, isShort: true);
    }

    void writeFL(FL a) {
        assert(a.vr == VR.kFD);
        writeDcmFloat32List(a.values, isShort: true);
    }

    void writeIS(IS a) {
        assert(a.vr == VR.kIS);
        writeShortDcmString(a);
    }

    void writeLO(LO a) {
        assert(a.vr == VR.kLO);
        writeShortDcmString(a);
    }

    void writeLT(LT a) {
        assert(a.vr == VR.kLT);
        writeShortDcmString(a);
    }

    //TODO: need transfer syntax to do this correctly
    void writeOB(OB a) {
        assert(a.vr == VR.kOB);
        if (a.hadUndefinedLength) {
            writeLongLength(kUndefinedLength);
            writeUint8List(a.values);
            writeUint32(kSequenceDelimitationItem);
        }
        writeDcmUint8List(a.values, isShort: false);
    }

    void writeOD(OD a) {
        assert(a.vr == VR.kOD);
        writeDcmFloat64List(a.values, isShort: false);
    }

    void writeOF(OF a) {
        assert(a.vr == VR.kOF);
        writeDcmFloat32List(a.values, isShort: false);
    }

    //TODO: need transfer syntax to do this correctly
    void writeOL(OL a) {
        assert(a.vr == VR.kOL);
        writeDcmUint32List(a.values, isShort: false);
    }

    // depends on Transfer Syntax
    //TODO: need transfer syntax to do this correctly
    void writeOW(OW a) {
        assert(a.vr == VR.kOW);
        writeDcmUint16List(a.values, isShort: false);
    }

    void writePN(PN a) {
        assert(a.vr == VR.kPN);
        writeShortDcmString(a);
    }

    void writeSH(SH a) {
        assert(a.vr == VR.kSH);
        writeShortDcmString(a);
    }

    void writeSL(SL a) {
        assert(a.vr == VR.kSL);
        writeDcmInt32List(a.values, isShort: true);
    }

    void writeSQ(SQ sq) {
        assert(sq.vr == VR.kSQ);
        writeSequence(sq);
    }

    void writeSS(SS a) {
        assert(a.vr == VR.kSS);
        writeDcmInt16List(a.values, isShort: true);
    }

    void writeST(ST a) {
        assert(a.vr == VR.kST);
        writeShortDcmString(a);
    }

    void writeTM(TM a) {
        assert(a.vr == VR.kTM);
        writeShortDcmString(a);
    }

    void writeUC(UC a) {
        assert(a.vr == VR.kUC);
        writeLongDcmString(a);
    }

    //TODO: move to encode Dcm/ constants
    static const String uidPaddingChar = "\x00";

    void writeUI(UI a) {
        assert(a.vr == VR.kUI);
        writeShortDcmString(a, padChar: uidPaddingChar);
    }

    void writeUL(UL a) {
        assert(a.vr == VR.kUL);
        print('UL: ${a.values}');
        writeDcmUint32List(a.values);
    }

    void writeUN(UN a) {
        assert(a.vr == VR.kUN);
        writeDcmUint8List(a.values, isShort: false);
    }

    void writeUR(UR a) {
        assert(a.vr == VR.kUR);
        writeLongDcmString(a);
    }

    void writeUS(US a) {
        assert(a.vr == VR.kUS);
        writeDcmUint8List(a.values, isShort: true);
    }

    /// Unlimited Text (UT) Value Representation
    void writeUT(UT a) {
        assert(a.vr == VR.kUT);
        writeLongDcmString(a);
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
    /// write a [Sequence][SQ]
    //int _getSequenceLength() => _getUndefinedLength(kSequenceDelimiterLast16Bits);

    //int writeSequenceLength() => writeLongOrUndefinedLength(kSequenceDelimiterLast16Bits);

    void writeLengthInBytes(int length, bool isShort, int bytesPerElement, int maxLongLength) {
        if (isShort) {
            int lengthInBytes = _validFieldLength(length, bytesPerElement, kMaxShortLengthInBytes);
            writeShortLength(lengthInBytes);
        } else {
            int lengthInBytes = _validFieldLength(length, bytesPerElement, maxLongLength);
            writeLongLength(lengthInBytes);
        }
    }

    ///
    int _validFieldLength(int length, int bytesPerElement, int maxLengthInBytes) {
        int lengthInBytes = length * bytesPerElement;
        if (lengthInBytes > maxLengthInBytes)
            _invalidValueFieldLengthError("length($length) = lengthInBytes($lengthInBytes) "
                                              "exceeds maxLengthInBytes($maxLengthInBytes);elementSizeInBytes");
        return lengthInBytes;
    }

    //Flush?
    void _invalidValueFieldLengthError(String msg) {
        log.error(msg);
        if (breakOnError) throw msg;
    }


    void writeDcmInt32List(List<int> list, {isShort: true}) {
        writeLengthInBytes(list.length, isShort, 4, Int32.maxLongLength);
        if (list.length > 0 ) {
            Int32List bytes = new Int32List.fromList(list);
            writeInt32List(bytes);
        }
    }

    void writeDcmUint32List(List<int> values, {isShort: true}) {
        print('writeDcm: $values');
        writeLengthInBytes(values.length, isShort, 4, Uint32.maxLongLength);
        if (values.length > 0 ) {
            Uint32List bytes = new Uint32List.fromList(values);
            writeUint32List(bytes);
        }
    }

    void writeDcmInt16List(List<int> list, {isShort: true}) {
        writeLengthInBytes(list.length, isShort,  2, Int16.maxLongLength);
        if (list.length > 0 ) {
            Int16List bytes = new Int16List.fromList(list);
            writeInt16List(bytes);
        }
    }

    void writeDcmUint16List(List<int> list, {isShort: true}) {
        writeLengthInBytes(list.length, isShort,  2, Uint16.maxLongLength);
        if (list.length > 0 ) {
            Uint16List bytes = new Uint16List.fromList(list);
            writeUint16List(bytes);
        }
    }

    void writeDcmInt8List(List<int> list, {isShort: true}) {
        writeLengthInBytes(list.length, isShort, 1, Int8.maxLongLength);
        if (list.length > 0 ) {
            Int8List bytes = new Int8List.fromList(list);
            writeInt8List(bytes);
        }
    }

    void writeDcmUint8List(List<int> list, {isShort: true}) {
        writeLengthInBytes(list.length, isShort, 1, Uint8.maxLongLength);
        if (list.length > 0 ) {
            Uint8List bytes = new Uint8List.fromList(list);
            writeUint8List(bytes);
        }
    }

    void writeDcmFloat64List(List<double> list, {isShort: true}) {
        writeLengthInBytes(list.length, isShort, 8, Float64.maxLongLength);
        if (list.length > 0 ) {
            Float64List bytes = new Float64List.fromList(list);
            writeFloat64List(bytes);
        }
    }

    void writeDcmFloat32List(List<double> list, {isShort: true}) {
        writeLengthInBytes(list.length, isShort, 4, Float32.maxLongLength);
        if (list.length > 0 ) {
            Float32List bytes = new Float32List.fromList(list);
            writeFloat32List(bytes);
        }
    }

    //**** String Methods ****

    void writeShortDcmString(StringBase a, {String padChar: " "}) =>
        writeDcmString(a.toDcmString(), isShort: true, padChar: padChar);

    void writeLongDcmString(StringBase a, {String padChar: " "}) =>
        writeDcmString(a.toDcmString(), isShort: false);

    /// Convert a [List] of [String]s into [Uint8List] with trailing pad character if
    /// necessary, then writes the Value Length Field followed by the Value Field.
    void writeDcmString(String s, {bool isShort: true, String padChar: " "}) {
        Uint8List bytes;
        if (s.length.isOdd) s += padChar;
        int lengthInBytes = s.length;
        //if (lengthInBytes > 0) print('WrDcm: [${s.length}]"$s"');
        if (lengthInBytes > 0) {
            bytes = UTF8.encode(s);
            lengthInBytes = bytes.length;
        }
        if (isShort) {
            if (lengthInBytes > kMaxShortLengthInBytes) {
                var msg = "Short Length($lengthInBytes) exceeds maximum.";
                log.error(msg);
                throw msg;
            }
            writeShortLength(lengthInBytes);
        } else {
            if (lengthInBytes > kMaxLongLengthInBytes) {
                var msg = "Long Length($lengthInBytes) exceeds maximum.";
                log.error(msg);
                throw msg;
            }
            writeLongLength(lengthInBytes);
        }
        if (s.length > 0)
            writeUint8List(bytes);
    }

    //**** Sequences and Items

    void writeSequence(SQ sq) {
        if (sq.hadUndefinedLength) {
            writeLongLength(0xFFFFFFFF);
            writeItems(sq.items);
            writeUint32(kSequenceDelimitationItem);
        } else {
            writeLongLength(sq.lengthInBytes);
            writeItems(sq.items);
        }
    }

    /// Writes a [List] of [Item]s to [bytes].
    void writeItems(List<Item> items) {
        for (Item item in items) {
            if (item.hadUndefinedLength) {
                _writeUndefinedLengthItem(item);
            } else {
                assert(item.hadUndefinedLength == false);
                log.debug('writeItem: $item');
                writeTag(kItem);
                writeUint32(item.lengthInBytes);
                for(var a in item.eMap.values) {
                    //print('${fmtTag(a.tag)}, len=${a.length}');
                    encodeElement(a);
                }
            }
        }
    }

    /*
  void _writeItem(Item item) {
    assert(item.hadUndefinedLength == false);
    log.debug('writeItem: $item');
    writeUint32(kItem);
    writeUint32(item.lengthInBytes);
    for (int i = 0; i < item.lengthInBytes; i++)
      writeElement(item[i]);
  }
*/
    void _writeUndefinedLengthItem(Item item) {
        assert(item.hadUndefinedLength == true);
        writeTag(kItem);
        writeLongLength(0xFFFFFFFF);
        for(Element a in item.elements)
            encodeElement(a);
        writeTag(kItemDelimitationItem);
    }

    ///Writes Pixel Data (7FFF,0010) based on the Transfer Syntax.
    void writePixelData(Element a) {
        // print('pixelData: $a');
        _writeInternal(a);
    }

    /// Writes a Private Group of Private Elements.
    void writePrivateGroup(PrivateGroup pg) {
        for (int i = 0; i < pg.creators.length; i++) {
            print('${pg.creators[i]}');
            _writeInternal(pg.creators[i]);
        }
        for (int i = 0; i < pg.values.length; i++) {
            print('${pg.values[i]}');
            _writeInternal(pg.values[i]);
        }
    }

}
