// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dcm_convert/src/bytebuf/bytebuf.dart';
import 'package:dictionary/dictionary.dart';

import 'package:dcm_convert/src/bytebuf/bytebuf.dart';

//TODO:
//  1. Move all [String] trimming and validation to the Element.  The reader
//     and writer should write the values as given.
//  3. Add a mode that will write with/without [String]s padded to an even length
//  4. Need a mode where read followed by write will produce two byte for byte identical
//     byte streams.

//TODO: flush all print and any unnecessary log.* statements.
//TODO: change all the "a" (Attribute) variables to "e" (Element) variables.
//TODO: add Type Parameter to Element once Dataset has a typedef paramter for elements.

/// The type of Value Field Writers.
typedef dynamic VFWriter<E>(TagElement<E> e);

/// A library for parsing [Uint8List] containing DICOM File Format [Dataset]s.
///
/// Supports parsing both BIG_ENDIAN and LITTLE_ENDIAN format in the
/// super class [ByteBuf]. The default
/// Endianness is the endianness of the host [this] is running on, aka
/// [Endianness.HOST_ENDIAN].
///   * All get* methods _DO NOT_ advance the [readIndex].
///   * All read* methods advance the [readIndex] by the number of bytes
///     written.
///   * All set* methods _DO NOT_ advance the [writeIndex].
///   * All write* methods advance the [writeIndex] by the number of bytes
///     written.
///
/// _Notes_:
///   1. In all cases DcmBuf writes the Value Fields as they are without
///      modification, except possibly padding strings to an even length.
///      This is so they can be  written out byte for byte as they were read,
///      and a byte-wise comparator will find them  to be equal.
///   2. All String manipulation should be handled in the [Element] itself.
///   3. All VFWriters allow the Value Field to be empty.
class DcmTagWriter  {
  /// The log for debug output.
  static final Logger log = new Logger("DcmWriter", watermark: Severity.debug);
  static const int defaultBufferLength = 2 * kMB;
//  static ByteData _reuse;
  //TODO: make the buffer grow and shrink adaptively.

  /// The [ByteData] being read.
  final ByteData bd;

  /// The source of the [Uint8List] being read.
  final String path;
  final bool fmiOnly;

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  /// If [true] and [FMI] is not present, abort reading.
  final bool reUseBD;

  /// The index where reading should stop.
  final int endOfBD;

  /// if [true] [Dataset]s will be allowed to be written in IVRLE.
  final bool allowImplicitLittleEndian;

  /// If [true], a DICOM File Prefix (PS3.10) will be written even
  /// if it wasn't present when read.
  final bool addMissingPrefix;

  /// If [true], a DICOM File Meta Information (PS3.10) will be written
  /// even if it wasn't present when read.
  final bool addMissingFMI;

  final bool removeUndefinedLengths;

  /// The [TransferSyntax] for the output.
  final TransferSyntax outputTS;

  /// The root Dataset for the object being read.
  final RootTagDataset rootDS;

  final bool isEVR;

  /// The current dataset.  This changes as Sequences are read and
  /// [Items]s are pushed on and off the [dsStack].
  ByteDataset currentDS;

  TransferSyntax _transferSyntax;
  bool  _isEncapsulated;

  /// The current write index.
  int _wIndex = 0;
  bool get _isWritable => _wIndex < endOfBD;

  /// The root Dataset for the object being read.
 // RootTDataset _rootDS;


  //*** Constructors ***
  //TODO: what should the default length be

  /// Creates a new [DcmTagWriter], where [readIndex] = [writeIndex] = 0.
  DcmTagWriter(this.rootDS,
      {this.path = "",
        this.outputTS,
        endianness = Endianness.LITTLE_ENDIAN,
        this.throwOnError = true,
        this.allowImplicitLittleEndian = true,
        this.addMissingPrefix = false,
        this.addMissingFMI = false,
        this.removeUndefinedLengths = false,
        this.reUseBD = true})
      : _wIndex = 0,
        bd = (reUseBD)
            ? _reuseBD(rootDS.lengthInBytes + 1024)
            : new ByteData(defaultBufferLength);

/*      {int lengthInBytes = defaultBufferLength,
      isEVR = true,
      this.throwOnError = true})
      : super.writer(lengthInBytes); */

  //TODO: explain use case for this.
  /// Creates a new writable [DcmTagWriter] from the [Uint8List] [bytes].
  //DcmWriter.from(DcmWriter buf, [int offset = 0, int length])
  //    : super.from(buf, offset, length);

  // Flush or Fix
  /// Creates a [Uint8List] with the same length as the elements in [List],
  /// and copies over the elements.  Values are truncated to fit in the list
  /// when they are copied, the same way storing values truncates them.
  //DcmWriter.fromList(List<int> list) : super.fromList(list);

  /// Create a view of [this].
  //DcmWriter.view(ByteBuf buf, [int offset = 0, int length])
  //    : super.view(buf, offset, length);

  //**** Methods that Return new [ByteBuf]s.  ****
  //TODO: these next three don't do error checking and they should
  /// Creates a new [ByteBuf] that is a view of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  // @override
  // DcmWriter writeSlice(int offset, int length)  => super.writeSlice(offset, length);

  //Flush?
  /// Creates a new [ByteBuf] that is a view of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  //@override
  //DcmWriteBuf writeSlice(int offset, int length) =>
  //    new DcmWriteBuf.internal(bytes, offset, offset, length);

  /// Creates a new [ByteBuf] that is a [sublist] of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  //@override
  // DcmWriter sublist(int start, int end) =>
  //     new DcmWriter.internal(bytes, start, end - start, end - start);

  /// Write a [RootDataset].
  void writeRootDataset(RootTDataset rootDS) {
    log.down;
    log.debug('$wbb writeRootDataset: $rootDS');

    _writePreambleAndPrefix();
    log.debug('$rmm isExplicitVR($_rootDS.isExplicitVR)');
    writeDataset(rootDS);
    log.debug('$ree writeRootDataset.end');
    log.up;
    return;
  }

  void writeDataset(TDataset ds, [bool isExplicitVR = true]) {
    log.down;
    log.debug('$wbb writeDataset: $ds');
    for (TElement e in ds.elements) _writeElement(e, isExplicitVR);
    log.debug('$wee writeDataset.end');
    log.up;
    return;
  }

  /// This is the top-level entry point for writing an [Element].
  void _writeElement(TElement e, [bool isExplicitVR = true]) {
    log.down;
    log.debug('$wbb _writeElement: ${e.info}');
    (isExplicitVR) ? _writeExplicit(e) : _writeImplicit(e);
    log.debug('$wee _writeElement: ${e.info}');
    log.up;
  }

  //Enhancement: if the file has a non-zero prefix,
  // have the ability to write it out if desired.

  /// Write the 128-byte, all zero, preamble for the DICOM File Format,
  /// then write the DICOM Prefix "DICM".  The Prefix is equivalent to
  /// a magic number that specifies the DICOM File Format. See PS3.10.
  void _writePreambleAndPrefix() {
    writeUint8List(new Uint8List(128));
    const String prefix = "DICM";
    Uint8List bytes = UTF8.encode(prefix);
    writeUint8List(bytes);
  }

  void _writeFmi(RootTDataset ds) {
    //TODO
  }

  void _writeExplicit(TElement e) {
    ByteBuf _writeVR(TElement e) => writeUint16(e.vr.code);
    void _writeVFLength(TElement e) {
      int lengthIB = _getVFLength(e);
      log.debug('$wmm _writeVFLength($lengthIB): ${e.info}');
      (e.vr.hasShortVF) ? writeUint16(lengthIB) : _writeLongLength(lengthIB);
    }
    log.debugDown('$wbb _writeExplicit: ${e.info}');
    TElement e0 = _maybeGetElement(e);
    if (e0 is SQ) {
     // SQ sq = e0;
      _writeSQ(e0);
    } else {
      _writeTag(e0);
      _writeVR(e0);
      _writeVFLength(e0);
      _writeVF(e0);
      log.debugUp('$wee  _writeExplicit');
    }
  }

  /// If [e] is a [MetaElement] returns e.element; otherwise, returns e.
  TElement _maybeGetElement(TElement e) {
    if (isNotWritable) _debugWriter(e, "End of buffer error: $this");
    if (e is MetaElement) {
      MetaElement meta = e;
      log.down;
      TElement element = meta.element;
      log.debug('$wbb _maybeGetElement: ${e.info}');
      log.up;
      return element;
    }
    return e;
  }

  int _getVFLength(TElement e) =>
      (e.hadUndefinedLength) ? kUndefinedLength : e.vfBytes.lengthInBytes;

  void _writeImplicit(TElement e) {
    log.down;
    log.debug('$wbb _writeImplicit: ${e.info}');
    TElement e0 = _maybeGetElement(e);
    _writeTag(e0);
    writeUint32(_getVFLength(e0));
    _writeVF(e0);
    log.debug('$wee _writeImplicit-end');
    log.up;
  }

  ///TODO: this is expensive! Is there a better way?
  /// write the DICOM Element Tag
  void _writeTag(TElement e) {
    writeUint16(e.tag.group);
    writeUint16(e.tag.elt);
  }

  /// Skips 2-bytes and then writes and returns a 32-bit length field.
  /// Note: This should only be used for VRs of // OD, OF, OL, UC, UR, UT.
  /// It should not be used for VRs that can have an Undefined Length (-1).
  void _writeLongLength(int lengthInBytes) {
    writeUint16(0);
    writeUint32(lengthInBytes);
  }

  /// Write the Value Field for this [TagElement].
  void _writeVF(TagElement e) {
    /// The order of the VRs in this [List] MUST correspond to the [VR.index]
    /// in the definitions of [VR].  Note: the [VR.index]es start at 1, so
    /// in this [List] the 0th function is [_debugWriter].
    /*
    final List<Function> _writers = <Function>[
      _debugWriter,
      _writeSQ, _writeSS, _writeSL, _writeOB, _writeUN, _writeOW,
      _writeUS, _writeUL, _writeAT, _writeOL, _writeFD, _writeFL,
      _writeOD, _writeOF, _writeIS, _writeDS, _writeAE, _writeCS,
      _writeLO, _writeSH, _writeUC, _writeST, _writeLT, _writeUT,
      _writeDA, _writeDT, _writeTM, _writePN, _writeUI, _writeUR,
      _writeAS, _debugWriter // VR.kBR is not implemented.
      // preserve formatting
    ];
    */
    final List<Function> _writers = <Function>[
      _debugWriter,
      _writeAE, _writeAS, _writeAT, _debugWriter, _writeCS,
      _writeDA, _writeDS, _writeDT, _writeFD, _writeFL,
      _writeIS, _writeLO, _writeLT, _writeOB, _writeOD,
      _writeOF, _writeOL, _writeOW, _writePN, _writeSH,
      _writeSL, _writeSQ, _writeSS, _writeST, _writeTM,
      _writeUC, _writeUI, _writeUL, _writeUN, _writeUR,
      _writeUS, _writeUT // stop reformat
    ];

    log.down;
    log.debug('$wbb writer: ${e.info}');
    Function writer = _writers[e.vr.index];
    if (writer == null) {
      String msg = "Invalid vrIndex(${Int16.hex(e.vr.code)})";
      log.fatal(msg);
    }
    log.debug('$wmm writer($writer)');
    writer(e);
    log.debug('$wee writer-end');
    log.up;
  }

  //**** VR writers ****
  bool _writeAE(AE e) => _writeDcmAsciiString(e);
  bool _writeAS(AS e) => _writeDcmAsciiString(e);
  bool _writeCS(CS e) => _writeDcmAsciiString(e);
  bool _writeDA(DA e) => _writeDcmAsciiString(e);
  bool _writeDS(DS e) => _writeDcmAsciiString(e);
  bool _writeDT(DT e) => _writeDcmAsciiString(e);
  bool _writeIS(IS e) => _writeDcmAsciiString(e);
  bool _writeLO(LO e) => _writeDcmUtf8String(e);
  bool _writeLT(LT e) => _writeDcmUtf8String(e);
  bool _writePN(PN e) => _writeDcmUtf8String(e);
  bool _writeSH(SH e) => _writeDcmUtf8String(e);
  bool _writeST(ST e) => _writeDcmUtf8String(e);
  bool _writeTM(TM e) => _writeDcmAsciiString(e);
  bool _writeUC(UC e) => _writeDcmUtf8String(e);
  bool _writeUI(UI e) => _writeDcmAsciiString(e, "\u0000"); // null for UID
  bool _writeUR(UR e) => _writeDcmUtf8String(e);
  bool _writeUT(UT e) => _writeDcmUtf8String(e);

  bool _writeDcmAsciiString(StringBase e, [String padChar = " "]) {
    if (e.values.length == 0) return false;
    String s = _toDcmString(e, padChar);
    writeUint8List(ASCII.encode(s));
    return true;
  }

  bool _writeDcmUtf8String(StringBase e, [String padChar = " "]) {
    String s = _toDcmString(e, padChar);
    writeUint8List(UTF8.encode(s));
    return true;
  }

  /// Convert a [List] of [String]s into [Uint8List] with trailing pad character if
  /// necessary, then writes the Value Length Field followed by the Value Field.
  String _toDcmString(StringBase e, String padChar) {
    String s = e.values.join('\\');
    if (s.length.isOdd) s += padChar;
    return s;
  }

  //**** Writers for 2-byte [TagElement]s.
  ByteBuf _writeSS(SS e) => writeInt16List(e.values);
  ByteBuf _writeUS(US e) => writeUint16List(e.values);

  //**** Writers for 4-byte [TagElement]s.
  ByteBuf _writeSL(SL e) => writeInt32List(e.values);
  ByteBuf _writeAT(AT e) => writeUint32List(e.values);
  ByteBuf _writeFL(FL e) => writeFloat32List(e.values);
  ByteBuf _writeOF(OF e) => writeFloat32List(e.values);
  ByteBuf _writeOL(OL e) => writeUint32List(e.values);
  ByteBuf _writeUL(UL e) => writeUint32List(e.values);

  //**** Writers for 8-byte [TagElement]s.

  ByteBuf _writeFD(FD e) => writeFloat64List(e.values);
  ByteBuf _writeOD(OD e) => writeFloat64List(e.values);

  /* bool _writeBR(BR e) {     throw "Unimplemented";  */

  //**** Sequences and Items

  void _writeSQ(TagElement e) {
    if (e is SQ) {
      log.down;
      log.debug('$wbb writeSequence:${e.info}');
      if (e.hadUndefinedLength) {
        log.down;
        log.debug('$wmm writeSQ undefined)');
        _writeLongLength(0xFFFFFFFF);
        _writeItems(e.items);
        _writeSequenceDelimiter();
        log.debug('$wmm writeSQ-end');
        log.up;
      } else {
        _writeLongLength(e.vfLength);
        _writeItems(e.items);
      }
      log.debug('$wee writeSequence-end');
      log.up;
    } else {
      throw 'TagElement $e is not an SQ (Sequence)';
    }
  }

  /// writes a 32-bit length field that has an Undefined Length value (0xFFFFFFFF).
  void _writeUndefinedLength() => _writeLongLength(kUndefinedLength);

  /// Writes a  32-bit [kSequenceDelimitationItem] value, followed by a 32-bit 0 length.
  void _writeSequenceDelimiter() =>
      _writeDelimiter(kSequenceDelimiterLast16Bits);

  /// Writes a 32-bit [kItem] value, followed by a 32-bit length.
  void _writeItemHeader(int lengthInBytes) =>
      _writeDelimiter(kItemLast16bits, lengthInBytes);

  /// Writes a 32-bit [kItemDelimitationItem] value, followed by a 32-bit 0 length.
  void _writeItemDelimiter() => _writeDelimiter(kItemDelimiterLast16bits);

  void _writeDelimiter(int last16Bits, [int lengthInBytes = 0]) {
    writeUint16(kDelimiterFirst16Bits);
    writeUint16(last16Bits);
    writeUint32(lengthInBytes);
  }

  /// Writes a [List] of [Item]s to [bytes].
  void _writeItems(List<TItem> items) {
    log.down;
    log.debug('$wbb writeItems:${items.length} Items');
    for (TItem item in items) _writeItem(item);
    log.debug('$wee writeItems-end');
    log.up;
  }

  void _writeItem(TItem item) {
    log.down;
    log.debug('$wbb writeItem ${item.info} for ${item.sq.info} ');
    if (item.hadUndefinedLength) {
      log.down;
      log.debug('$wbb Item hadUndefinedLength');
      // Can't use _writeLongLength here!
      _writeItemHeader(kUndefinedLength);
      for (TagElement e in item.elements) _writeElement(e);
      _writeItemDelimiter();
      log.debug('$wbb Item hadUndefinedLength-end');
      log.up;
    } else {
      log.debug('$wbb write-end');
      _writeItemHeader(item.vfLength);
      log.debug(
          '$wbb writeItem vfLength(${item.vfLength}, ${Int.hex(item.vfLength)}');
      for (TagElement e in item.elements) _writeElement(e);
    }
    log.debug('$wee writeItem-end');
    log.up;
  }

  void _writeOB(OB e) {
    log.down;
    log.debug('$wbb writeOB: ${e.info}');
    if (e.hadUndefinedLength) {
      log.debug('$wmm writeOB Undefined Length');
      _writeUndefinedLength();
      writeUint8List(e.values);
      _writeSequenceDelimiter();
    } else {
      log.debug('$wmm WriteOB: ${e.info}');
      writeUint8List(e.values);
    }
    log.debug('$wee writeOB, lengthInBytes(${e.vfBytes.lengthInBytes})');
    log.up;
  }

  // depends on Transfer Syntax
  //TODO: need transfer syntax to do this correctly
  void _writeOW(OW e) {
    log.down;
    log.debug('$wbb writeOW: ${e.info}');
    if (e.hadUndefinedLength) {
      //log.debug('$mmm $writeIndex: writing OW with Undefined Length');
      _writeUndefinedLength();
      // log.debug('$mmm $writeIndex: writing OW values');
      writeUint16List(e.values);
      // log.debug('$mmm $writeIndex: Wrote ${a.length} values, ${a.lengthInBytes} bytes');
      _writeSequenceDelimiter();
      // log.debug('$mmm $writeIndex: wrote Sequence Delimter');
    } else {
      writeUint16List(e.values);
      log.debug('$wee writeOW: Length(${e.values.length}), LengthInBytes(${e
              .vfBytes.lengthInBytes})');
    }
    log.up;
  }

  void _writeUN(UN e) {
    log.down;
    log.debug('$wee writeUN: ${e.info}');
    log.debug(
        '$wmm writeUN: $writeIndex < LengthInBytes(${e.values.length}) < ${bytes.lengthInBytes})');
    if (e.hadUndefinedLength) {
      log.down;
      log.debug('$wbb Writing Undefined Length start');
      _writeUndefinedLength();
      writeUint8List(e.values);
      _writeSequenceDelimiter();
      log.debug('$wee Writing Undefined Length end');
      log.up;
    } else {
      writeUint8List(e.values);
    }
    log.debug('$wee writeUN: LengthInBytes(${e.vfBytes.lengthInBytes}))');
    log.up;
  }

  void _debugWriter(TagElement e, String msg) {
    //TODO:
  }

  // External Interface for Testing
// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// read successfully.
  void xWriteFmi(RootTDataset rootDS, [bool checkForPrefix = true]) {
    if (!rootDS.hasValidTransferSyntax) return null;
    _writeFmi(rootDS);
  }

  void xWritePublicElement(TagElement e, [bool isExplicitVR = true]) =>
      _writeElement(e, isExplicitVR);

  // External Interface for testing
  void xWritePGLength(TagElement e, [bool isExplicitVR = true]) =>
      _writeElement(e, isExplicitVR);

  // External Interface for testing
  void xWritePrivateIllegal(TagElement e, [bool isExplicitVR = true]) =>
      _writeElement(e, isExplicitVR);

  // External Interface for testing
  void xWritePrivateCreator(TagElement e, [bool isExplicitVR = true]) =>
      _writeElement(e, isExplicitVR);

  // External Interface for testing
  void xWritePrivateData(TagElement e, [bool isExplicitVR = true]) =>
      _writeElement(e, isExplicitVR);
}
