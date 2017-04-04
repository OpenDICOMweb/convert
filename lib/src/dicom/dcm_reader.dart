// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/dataset.dart';
import 'package:core/element.dart';
import 'package:dictionary/dictionary.dart';

import '../../src/dataset_stack.dart';
import '../bytebuf/bytebuf.dart';

//TODO:
//  1. Move all [String] trimming and validation to the Element.  The reader
//     and writer should write the values as given.
//  2. Add a mode that will read with/without [String]s padded to an even length
//  3. Add a mode that will write with/without [String]s padded to an even length
//  4. Need a mode where read followed by write will produce two byte for byte identical
//     byte streams.
//  5. optimize by turning all internal method to private '_'.
//  6. when fully debugged and performance improvements done. cleanup and document.

/// The type of the different Value Field readers.  Each Value Field Reader
/// reads the Value Field Length and the Value Field for a particular Value
/// Representation.
typedef Element<E> VFReader<E>(int tag, VR<E> vr, int vfLength);

/// A library for parsing [Uint8List] containing DICOM File Format [Dataset]s.
///
/// Supports parsing both BIG ENDIAN and LITTLE ENDIAN format in the
/// super class [ByteBuf]. The default
/// Endianness is the endianness of the host [this] is running on, aka
/// [Endianness.HOST_ENDIAN].
///   * All get* methods _DO NOT_ advance the [readIndex].
///   * All read* methods advance the [readIndex] by the number of bytes read.
///   * All set* methods _DO NOT_ advance the [writeIndex].
///   * All write* methods advance the [writeIndex] by the number of bytes written.
///
/// _Notes_:
///   1. In all cases DcmReader reads and returns the Value Fields as they
///   are in the data, for example DcmReader does not trim whitespace from
///   strings.  This is so they can be written out byte for byte as they were
///   read. and a byte-wise comparator will find them to be equal.
///   2. All String manipulation should be handled in the attribute itself.
///   3. All VFReaders allow the Value Field to be empty.  The [String] VFReaders return "",
///   and the Integer, FLoat VFReaders return new [null].
class DcmReader<E> extends ByteBuf {
  ///TODO: doc
  static final Logger log = new Logger("DcmReader", watermark: Severity.debug);

  /// The root Dataset for the object being read.
  final RootDataset rootDS;

  /// A stack of [Dataset]s.  Used to save parent [Dataset].
  DatasetStack dsStack = new DatasetStack();

  /// The current dataset.  This changes as Sequences are read and [Dataset]s are
  /// pushed on and off the [dsStack].
  Dataset currentDS;

  //*** Constructors ***

  /// Creates a new [DcmReader]  where [readIndex] = [writeIndex] = 0.
  DcmReader(DSSource source)
      : rootDS = new RootDataset(source),
        super.reader(source.bytes, 0, source.lengthInBytes) {
    currentDS = rootDS;
  }

  /// Creates a [Uint8List] with the same length as the elements in [list],
  /// and copies over the elements.  Values are truncated to fit in the list
  /// when they are copied, the same way storing values truncates them.
  DcmReader.fromList(List<int> list)
      : rootDS = new RootDataset(DSSource.kUnknown),
        super.fromList(list) {
    currentDS = rootDS;
  }

  //****  Core Dataset methods  ****

  /// Returns an [Map<int, Element] or [null].
  ///
  /// This is the top-level entry point for reading a [Dataset].
  //TODO: validate that [ds] is being handled correctly.
  //TODO: flush count argument when working
  Dataset readRootDataset([int count = 100000]) {
    if (!_hasPrefix()) return null;
    //  log.down;
    log.debug('$rbb readRootDataset: $rootDS');
    TransferSyntax ts = _readFmi();
    if (ts == null) throw "Unsupported Null TransferSyntax";
    log.debug('$rmm readRootDataset: transferSyntax(${rootDS.transferSyntax})');
    log.debug('$rmm readRootDataset: ${rootDS.hasValidTransferSyntax}');
    if (!rootDS.hasValidTransferSyntax) return rootDS;
    final bool isExplicitVR =
        rootDS.transferSyntax != TransferSyntax.kImplicitVRLittleEndian;
    log.debug('$rmm readRootDataset: isExplicitVR($isExplicitVR)');
    while (isReadable) {
      log.debug('$rmm buf: $this');
      readElement(isExplicitVR: isExplicitVR);
    }

    log.debug('$ree readRootDataset: $rootDS');
    //  log.up;
    return rootDS;
  }

  TransferSyntax readFmi([int count = 100000]) {
    if (!_hasPrefix()) return null;
    //  log.down;
    log.debug('$rbb readRootDataset: $rootDS');
    TransferSyntax ts = _readFmi();
    if (ts == null) throw "Unsupported Null TransferSyntax";
    log.debug('$rmm readRootDataset: transferSyntax(${rootDS.transferSyntax})');
    log.debug('$rmm readRootDataset: ${rootDS.hasValidTransferSyntax}');
    if (!rootDS.hasValidTransferSyntax) return ts;
    final bool isExplicitVR =
        rootDS.transferSyntax != TransferSyntax.kImplicitVRLittleEndian;
    log.debug('$rmm readRootDataset: isExplicitVR($isExplicitVR)');
    /*while (isReadable) {
      log.debug('$rmm buf: $this');
      readElement(isExplicitVR: isExplicitVR);
    }*/
    log.debug('$ree readRootDataset: $rootDS');
    //  log.up;
    return ts;
  }

  bool _hasPrefix() {
    skipReadBytes(128);
    final String prefix = readAsciiString(4);
    return (prefix == "DICM");
  }

  /// Reads File Meta Information ([Fmi]). If any [Fmi] [Element]s were present returns true.
  TransferSyntax _readFmi() {
    log.down;
    log.debug('$rbb readFmi($currentDS)');
    if (isReadable && currentDS is RootDataset) {
      for (int i = 0; i < 20; i++) {
        readElement(isExplicitVR: true);
        final int code = _peekTagCode();
        log.debug1('$rmm _peekTag(${Tag.toHex(code)})');
        if (code >= 0x00080000) {
          log.debug1('$rmm finished readFMI $currentDS');
          break;
        }
      }
    }
    log.debug('$ree readFmi: ${rootDS.transferSyntax}');
    log.up;
    return rootDS.transferSyntax;
  }

  /// Peek at next tag - doesn't move the [readIndex].
  int _peekTagCode() {
    //TODO: do we really want to make all local variables final? Doesn't it make it
    //      harder to read the code?
    final int group = getUint16(readIndex);
    final int element = getUint16(readIndex + 2);
    final int code = (group << 16) + element;
    return code;
  }

  ///TODO: this is expensive! Is there a better way?
  /// Read the DICOM Element Tag
  int _readTagCode() {
    int group = readUint16();
    int elt = readUint16();
    int code = (group << 16) + elt;
    log.debug('$rmm _readTagCode: group(${Group.hex(group)}), '
        'elt(${Elt.hex(elt)}), code(${Tag.toHex(code)})');
    return code;
  }

  VR _readExplicitVR() {
    //TODO: merge into one call _readExplicitVR()
    int vrCode = readUint16();
    log.debug('$rmm _readExplicitVR( ${Uint16.hex(vrCode)})');
    VR vr = VR.lookup(vrCode);
    log.debug('$rmm _readExplicitVR: $vr');
    //VR vr = VR.vrList[vrIndex];
    log.debug('$rmm _readExplicitVR: VR($vr)');
    if (vr == null)
      _debugReader(null, 'Invalid null VR: code(${Uint16.hex(vrCode)})');
    assert(vr != null);
    return vr;
  }

  //TODO: rewrite doc
  /// Reads a zero or more [Private Groups] and then read an returns
  /// a Public [Element].
  Element readElement({bool isExplicitVR: true}) {
    log.down;
    final int code = _readTagCode();
    log.debug('$rbb readElement: _peekTag${Tag.toDcm(code)}');
    Element e;
    if (Tag.isPublicCode(code)) {
      Tag tag = Tag.lookupPublicCode(code);
      log.down;
      log.debug('$rbb readPublicElement: isExplicitVR($isExplicitVR)');
      e = _readElement(tag, isExplicitVR);
      currentDS[e.tag.code] = e;
      log.debug('$ree readPublicElement: ${e.info}');
      log.up;
    } else if (Tag.isPrivateCode(code)) {
      log.down;
      log.debug('$rbb readPrivateGroup');
      // This should read the whole Private Group before returning.
      PrivateGroup pg = _readPrivateGroup(code, isExplicitVR: isExplicitVR);
      log.debug('$ree readPrivateGroup: $pg');
      log.up;
    } else {
      _debugReader(code, code);
      tagCodeError(code);
    }
    log.debug('$ree readElement');
    log.up;
    return e;
  }

  /// Reads an [Element], either Public or Private. Does not inspect
  /// [Tag]; rather, assumes it is correct, but reads [VR], if explicit,
  /// [vfLength] and Value Field;
  Element _readElement(Tag tag, bool isExplicitVR) {
    log.down;
    log.debug('$rbb _readElement: ${tag.info}');

    VR vr;
    int vfLength;
    if (isExplicitVR) {
      vr = _readExplicitVR();
      log.debug('$rmm _readElement: vr($vr), tag.vr(${tag.vr})');
      if (vr != tag.vr)
        log.warn('$rmm _readElement: *** vr($vr) !=  tag.vr(${tag.vr})');
      if (vr == VR.kUN) vr = tag.vr;
      if (tag == Tag.kPixelData &&
          (vr != VR.kOB && vr != VR.kOW) &&
          vr != VR.kUN) throw 'Bad VR($vr) != tag.vr(${tag.vr})';
      vfLength = (vr.hasShortVF) ? readUint16() : _readLongLength();
      log.debug('$rmm _readExplicitVR: ${tag.info} $vr, vfLength($vfLength})');
    } else {
      if (tag == Tag.kPixelData) {
        vr = VR.kUN;
      } else {
        vr = tag.vr;
        //  throw 'Bad VR($vr) != tag.vr(${tag.vr})';
      }
      vfLength = readUint32();
      log.debug('$rmm _readImplicitVR: $tag $vr, vfLength($vfLength})');
    }
    Element e = _readValueField(tag, vfLength, vr.index);
    log.debug('$ree _readElement: ${e.info}');
    log.up;
    return e;
  }

  // Interface for debugging
  Element readExplicitVRElement(Tag tag) => _readExplicitVRElement(tag);
  // Interface for debugging
  Element readImplicitVRElement(Tag tag) => _readImplicitVRElement(tag);

  /// Reads an [Element], either Public or Private. Does not inspect
  /// [Tag]; rather, assumes it is correct, but reads [VR], if explicit,
  /// [vfLength] and Value Field;
  Element _readExplicitVRElement(Tag tag) {
    log.down;
    log.debug('$rbb _readElement: ${tag.info}');
    VR vr = _readExplicitVR();
    log.debug('$rmm _readElement: vr($vr), tag.vr(${tag.vr})');
    if (vr != tag.vr)
        log.warn('$rmm _readElement: *** vr($vr) !=  tag.vr(${tag.vr})');
    int vfLength = (vr.hasShortVF) ? readUint16() : _readLongLength();
    log.debug('$rmm _readExplicitVR: ${tag.info} $vr, vfLength($vfLength})');
    Element e = _readValueField(tag, vfLength, vr.index);
    log.debug('$ree _readElement: ${e.info}');
    log.up;
    return e;
  }
  //TODO: redoc
  /// Reads an Implicit VR[Element], either Public or Private. Does not inspect
  /// [Tag]; rather, assumes it is correct, but reads [VR], if explicit,
  /// [vfLength] and Value Field;
  Element _readImplicitVRElement(Tag tag) {
    log.down;
    log.debug('$rbb _readElement: ${tag.info}');
    VR vr = VR.kUN;
    int vfLength = readUint32();
    log.debug('$rmm _readImplicitVR: $tag $vr, vfLength($vfLength})');
    Element e = _readValueField(tag, vfLength, vr.index);
    log.debug('$ree _readElement: ${e.info}');
    log.up;
    return e;
  }

  /// Read a 32-bit Value Field Length field.
  ///
  /// Skips 2-bytes and then reads and returns a 32-bit length field.
  /// Note: This should only be used for VRs of // OD, OF, OL, UC, UR, UT.
  /// It should not be used for VRs that can have an Undefined Length (-1).
  //TODO: consider inlining
  int _readLongLength() {
    skipReadBytes(2);
    return readUint32();
  }

  Element<E> _readValueField<E>(Tag tag, int vfLength, int index) {
    /// The order of the VRs in this [List] MUST correspond to the [index]
    /// in the definitions of [VR].  Note: the [index]es start at 1, so
    /// in this [List] the 0th dictionary is [_debugReader].
    /* Flush when working
    final List<Function> _readers = <Function>[
      _debugReader,
      _readSQ, _readSS, _readSL, _readOB, _readUN, _readOW,
      _readUS, _readUL, _readAT, _readOL, _readFD, _readFL,
      _readOD, _readOF, _readIS, _readDS, _readAE, _readCS,
      _readLO, _readSH, _readUC, _readST, _readLT, _readUT,
      _readDA, _readDT, _readTM, _readPN, _readUI, _readUR,
      _readAS, _debugReader // VR.kBR is not implemented.
      // preserve formatting
    ];
    */
    final List<Function> _readers = <Function>[
      _debugReader,
      _readAE, _readAS, _readAT, _debugReader, _readCS,
      _readDA, _readDS, _readDT, _readFD, _readFL,
      _readIS, _readLO, _readLT, _readOB, _readOD,
      _readOF, _readOL, _readOW, _readPN, _readSH,
      _readSL, _readSQ, _readSS, _readST, _readTM,
      _readUC, _readUI, _readUL, _readUN, _readUR,
      _readUS, _readUT // stop reformat
    ];

    log.down;
    log.debug(
        '$rbb _readValueField: tag${tag.dcm}, vfLength(${Int32.hex(vfLength)}), index($index)');
    //TODO: make this work
    // VFReader vfReader = _getVFReader(vrIndex);
    final Function vfReader = _readers[index];
    Element<E> e = vfReader(tag, vfLength);
    log.debug('$ree _readValueField: ${e.info}');
    log.up;
    return e;
  }

  //**** VR Readers ****

  //**** Readers of [String] [Element]s
  AE _readAE(Tag tag, int vfLength) => new AE(tag, _readDcmAsciiVF(vfLength));
  AS _readAS(Tag tag, int vfLength) => new AS(tag, _readDcmAsciiVF(vfLength));
  CS _readCS(Tag tag, int vfLength) => new CS(tag, _readDcmAsciiVF(vfLength));
  DA _readDA(Tag tag, int vfLength) => new DA(tag, _readDcmAsciiVF(vfLength));
  DS _readDS(Tag tag, int vfLength) => new DS(tag, _readDcmAsciiVF(vfLength));
  DT _readDT(Tag tag, int vfLength) => new DT(tag, _readDcmAsciiVF(vfLength));
  IS _readIS(Tag tag, int vfLength) => new IS(tag, _readDcmAsciiVF(vfLength));
  LO _readLO(Tag tag, int vfLength) => new LO(tag, _readDcmUtf8VF(vfLength));
  LT _readLT(Tag tag, int vfLength) => new LT(tag, _readDcmUtf8VF(vfLength));
  PN _readPN(Tag tag, int vfLength) => new PN(tag, _readDcmUtf8VF(vfLength));
  SH _readSH(Tag tag, int vfLength) => new SH(tag, _readDcmUtf8VF(vfLength));
  ST _readST(Tag tag, int vfLength) => new ST(tag, _readDcmUtf8VF(vfLength));
  TM _readTM(Tag tag, int vfLength) => new TM(tag, _readDcmAsciiVF(vfLength));
  UC _readUC(Tag tag, int vfLength) => new UC(tag, _readDcmUtf8VF(vfLength));
  UI _readUI(Tag tag, int vfLength) =>
      new UI(tag, _readDcmAsciiVF(vfLength, kNull));
  UR _readUR(Tag tag, int vfLength) => new UR(tag, _readDcmUtf8VF(vfLength));
  UT _readUT(Tag tag, int vfLength) => new UT(tag, _readDcmUtf8VF(vfLength));

  static const List<String> _emptyStringList = const <String>[];

  /// Returns a [List[String].  If [padChar] is [kSpace] just returns the
  /// [String]
  /// if [padChar] is [kNull], it is removed by returning a [String] with
  /// [length - 1].
  /// Note: This calls [readString] in [ByteBuf].
  List<String> _readDcmAsciiVF(vfLength, [int padChar = kSpace]) {
    if (vfLength == 0) return _emptyStringList;
    _checkStringVF(vfLength);
    return _dicomStringToList(readUtf8String(vfLength), padChar);
  }

  List<String> _readDcmUtf8VF(vfLength, [int padChar = kSpace]) {
    if (vfLength == 0) return _emptyStringList;
    _checkStringVF(vfLength);
    return _dicomStringToList(readUtf8String(vfLength), padChar);
  }

  void _checkStringVF(int vfLength) {
    if (vfLength.isOdd || vfLength == kUndefinedLength)
      _debugReader(null, null, vfLength,
          "bad vfLength:$vfLength(${Int32.hex(vfLength)})");
  }

  //Urgent: How to get the warning to the Dataset
  /// Convert a DICOM Value Field [String] to [List] [String].
  /// No validation, just removes padding.
  List<String> _dicomStringToList(String s, padChar) {
    if (s.length.isOdd) throw '_dicomStringToList oddLength(${s.length}: "$s"';
    int last = s.codeUnitAt(s.length - 1);
    if (last == kNull || last == kSpace) {
      //TODO: move to Warning
      if (last != padChar) {
        var name = (last == kNull) ? "Null" : "Space";
        log.warn('$rmm Invalid $name($last) padChar');
      }
      s = s.substring(0, s.length - 1);
    }
    return s.split('\\');
  }

  //**** Readers of 16-bit [Element]s
  SS _readSS(Tag tag, int vfLength) =>
      new SS.fromBytes(tag, readUint8View(vfLength));
  US _readUS(Tag tag, int vfLength) =>
      new US.fromBytes(tag, readUint8View(vfLength));

  //**** Readers of 32-bit [Element]s
  SL _readSL(Tag tag, int vfLength) =>
      new SL.fromBytes(tag, readUint8View(vfLength));
  UL _readUL(Tag tag, int vfLength) =>
      new UL.fromBytes(tag, readUint8View(vfLength));
  OL _readOL(Tag tag, int vfLength) =>
      new OL.fromBytes(tag, readUint8View(vfLength));
  FL _readFL(Tag tag, int vfLength) =>
      new FL.fromBytes(tag, readUint8View(vfLength));
  OF _readOF(Tag tag, int vfLength) =>
      new OF.fromBytes(tag, readUint8View(vfLength));

  //**** Readers of 64-bit [Element]s
  FD _readFD(Tag tag, int vfLength) =>
      new FD.fromBytes(tag, readUint8View(vfLength));
  OD _readOD(Tag tag, int vfLength) =>
      new OD.fromBytes(tag, readUint8View(vfLength));

  /// Reader of AT [Element]s (2 x 16-bits = 32-bit)
  AT _readAT(Tag tag, int vfLength) {
    //Special case because [tag]s have to be read specially
    Uint32List list = new Uint32List(_bytesToLongs(vfLength));
    for (int i = 0; i < list.length; i++) list[i] = _readTagCode();
    return new AT.fromBytes(tag, list.buffer.asUint8List());
  }

  /// Sequence[SQ] reader
  SQ _readSQ(Tag tag, int vfLength) => _readSequence(tag, vfLength);

  //**** Converters from bytes to other length units

  /// Converts [lengthInBytes] to [length] for 2-byte value types.
  //int _bytesToWords(int lengthIB) =>
  //    ((lengthIB & 0x1) == 0) ? lengthIB >> 1 : _lengthError(lengthIB, 2);

  /// Converts [lengthInBytes] to [length] for 4-byte value types.
  int _bytesToLongs(int lengthIB) =>
      ((lengthIB & 0x3) == 0) ? lengthIB >> 2 : _lengthError(lengthIB, 4);

  /// Converts [lengthInBytes] to [length] for 4-byte value types.
  //int _bytesToDoubles(int lengthIB) =>
  //    ((lengthIB & 0x7) == 0) ? lengthIB >> 3 : _lengthError(lengthIB, 8);

  int _lengthError(int vfLength, int sizeInBytes) {
    log.fatal('$wmm Invalid vfLength($vfLength) for elementSize($sizeInBytes)'
        'the vfLength must be evenly divisible by elementSize');
    return -1;
  }

  //**** [Element]s that may have an Undefined Length in the Value Field

  /// There are four [Element]s that might have an Undefined Length value
  /// (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the
  /// Undefined, then it searches for the matching [kSequenceDelimitationItem]
  /// to determine the length. Returns a [kUndefinedLength], which is used for reading
  /// the value field of these [Element]s.

  /// Returns an [SQ] [Element].
  SQ _readSequence(Tag tag, int vfLength) {
    log.down;
    List<Item> items = <Item>[];
    SQ sq = new SQ(tag, vfLength, items);
    log.debug('$rbb ${sq.info}');
    if (vfLength == kUndefinedLength) {
      log.debug('$rmm SQ: ${tag.dcm} Undefined Length');
      int start = readIndex;
      while (!_sequenceDelimiterFound()) {
        Item item = _readItem(sq);
        items.add(item);
      }
      sq.lengthInBytes = (readIndex - 8) - start;
      log.debug('$rmm end of uLength SQ');
    } else {
      log.debug('$rmm SQ: ${tag.dcm} length($vfLength)');
      int limit = readIndex + vfLength;
      while (readIndex < limit) {
        Item item = _readItem(sq);
        items.add(item);
      }
    }
    log.debug('$ree ${sq.info}');
    log.up;
    return sq;
  }

  /// Returns [true] if the [target] delimiter is found.
  bool _foundDelimiter(int target) {
    int delimiter = _peekTagCode();
    bool v = delimiter == target;
    log.debug(
        '$rmm _delimiterFound($v) target${Int.hex(target)}, value${Int.hex(delimiter)}');
    if (delimiter == target) {
      int length = getUint32(4);
      log.debug(
          '$rmm target(${Int.hex(target)}), delimiter(${Int.hex(delimiter)}), length(${Int.hex
                (length, 8)
            }');
      if (length != 0) {
        var msg = '$rmm: Encountered non zero length($length)'
            ' following Undefined Length delimeter';
        log.error(null, msg);
      }
      log.debug(
          '$rmm Found return false target(${Int.hex(target)}), delimiter(${Int.hex(delimiter)}),'
          ' length(${Int.hex(length, 8)}');
      skipReadBytes(8);
      return true;
    }
    return false;
  }

  /// Returns [true] if the [kSequenceDelimitationItem] delimiter is found.
  bool _sequenceDelimiterFound() => _foundDelimiter(kSequenceDelimitationItem);

  /// Returns [true] if the [kItemDelimitationItem] delimiter is found.
  bool _itemDelimiterFound() => _foundDelimiter(kItemDelimitationItem);

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit & readElementExplicit
  /// Returns an [Item] or Fragment.
  Item _readItem(SQ sq) {
    log.down;
    log.debug('$rbb readItem for ${sq.info}');
    int itemStartCode = _readTagCode();
    log.debug('$rmm item tag(${itemStartCode.toRadixString(16)})');
    if (itemStartCode != kItem) _debugReader(itemStartCode, "Bad Item Tag");
    int vfLength = readUint32();
    log.debug('$rmm item length(${vfLength.toRadixString(16)})');
    Item item = new Item(currentDS, <int, Element>{}, sq, vfLength);
    log.debug('$rmm Item ${item.info}');

    // Save parent [Dataset], and make [item] is new parent [Dataset].
    dsStack.push(currentDS);
    currentDS = item;
    log.down;
    log.debug('$rbb readItemElements parent(${dsStack.last}) '
        'child(${currentDS.info}');
    int start = readIndex;
    try {
      if (vfLength == kUndefinedLength) {
        int start = readIndex;
        while (!_itemDelimiterFound()) {
          log.debug('$rmm reading undefined length');
          readElement();
        }
        // [readIndex] is at the end of delimiter and length (8 bytes)
        item.actualLengthInBytes = (readIndex - 8) - start;
      } else {
        int limit = readIndex + vfLength;
        while (readIndex < limit) readElement();
      }
    } finally {
      // Restore previous parent
      currentDS = dsStack.pop;
      log.debug('$ree readItemElements: ds($currentDS) ${item.info}');
    }
    int end = readIndex;
    item.actualLengthInBytes = end - start;
    log.up;
    log.debug('$ree ${item.info}');
    log.up;
    return item;
  }

  Uint8List _uLengthGetBytes(int vfLength) {
    log.down;
    int lengthInBytes = 0;
    log.debug('$rbb _uLengthGetBytes: vfLength(${Int32.hex(vfLength)}})');
    Uint8List values;
    if (vfLength == kUndefinedLength) {
      int start = readIndex;
      do {
        if (readUint16() != kDelimiterFirst16Bits) continue;
        if (readUint16() != kSequenceDelimiterLast16Bits) continue;
        break;
      } while (isReadable);
      // int delimiterLengthField = readUint32();
      if (readUint32() != 0) log.warn('Sequence Delimter with non-zero value');
      int end = readIndex - 8;
      lengthInBytes = end - start;
      log.debug('$rmm start($start), length($lengthInBytes)');
      values = (lengthInBytes == 0)
          ? Uint8.emptyList
          : getUint8View(start, lengthInBytes);
      log.debug('$rmm values.length(${values.length})');
      log.debug('$rmm Undefined vfLength(${Int32.hex(vfLength)}), '
          'lengthInBytes($lengthInBytes)');
    } else {
      lengthInBytes = vfLength;
      log.debug('$rmm vfLength($vfLength)');
      values =
          (lengthInBytes == 0) ? Uint8.emptyList : readUint8View(lengthInBytes);
      log.debug('$rmm vfLength(${Int32.hex(vfLength)}), '
          'lengthInBytes($lengthInBytes)');
    }
    log.debug('$ree _uLengthGetBytes-end: values.length(${values.length})');
    log.up;
    return values;
  }

  /// Read and return an [OB] [Element].
  ///
  /// Note: this should not be used for PixelData Elements.
  Element _readOB(Tag tag, int vfLength) {
    Uint8List vf = _uLengthGetBytes(vfLength);
    log.down;
    log.debug('$rbb $tag, $vfLength, $vf.length');
    log.debug('$rbb readOB vfLength(${Int32.hex(vfLength)})');
    Element e;
    if (tag == Tag.kPixelData) {
      TransferSyntax ts = currentDS.transferSyntax;
      log.debug('$rmm PixelData: $ts');
      IS e0 = currentDS[kNumberOfFrames];
      int nFrames = (e == null) ? 1 : e0.value;
      log.debug('$rmm nFrames: $nFrames, ts: $ts');
      e = new OBPixelData.fromBytes(tag, vfLength, ts, vf, nFrames);
    } else {
      e = new OB.fromBytes(tag, vfLength, vf);
    }
    log.debug('$ree readOB ${e.info}');
    log.up;
    return e;
  }

  Element _readOW(Tag tag, int vfLength) {
    Uint8List vf = _uLengthGetBytes(vfLength);
    log.down;
    log.debug('$rbb readOW $tag, vfLength($vfLength), vf.length(${vf.length})');
    Element e;
    if (tag == Tag.kPixelData) {
      TransferSyntax ts = currentDS.transferSyntax;
      log.debug('$rmm PixelData: $ts');
      IS e0 = currentDS[kNumberOfFrames];
      int nFrames = (e == null) ? 1 : e0.value;
      log.debug('$rmm nFrames: $nFrames, ts: $ts');
      e = new OWPixelData.fromBytes(tag, vfLength, ts, vf, nFrames);
    } else {
      e = new OW.fromBytes(tag, vfLength, vf);
    }
    log.debug('$ree ${e.info}');
    log.up;
    return e;
  }

  UN _readUN(Tag tag, int vfLength) {
    log.down;
    log.debug('$rbb tag${tag.dcm}');
    Uint8List bytes = _uLengthGetBytes(vfLength);
    log.debug(
        '$rmm vfLength($vfLength, ${Int32.hex(vfLength)}), bytes.length(${bytes.length})');
    UN e = new UN.fromBytes(tag, vfLength, bytes);
    log.debug('e= $e');
    log.debug('$ree ${e.info}');
    log.up;
    return e;
  }

  /// Reads and returns a [PrivateGroup].
  ///
  /// A [PrivateGroup] contains all the  [PrivateCreator] and the corresponding
  /// [PrivateData] Data [Element]s with the same (private) group number.
  ///
  /// This method is called when the first Private Tag Code in a Private Group
  /// is encountered, and control remains in this group until the next
  /// Public Group is encountered.
  ///
  /// _Notes_:
  ///     1. All PrivateCreators are read before any of the [PrivateData]
  /// [Element]s are read.
  ///
  ///     2. PrivateCreators for one private group all occur before their
  /// corresponding Private Data Elements.
  ///
  ///     3. It is possible to encounter a Private Data Element that does
  ///     not have a creator. This should be recorded in [Dataset].exceptions.
  ///
  /// Note: designed to read just one PrivateGroup and return it.
  PrivateGroup _readPrivateGroup(int code, {bool isExplicitVR: true}) {
    assert(Group.isPrivate(Group.fromTag(code)),
        "Non Private Group ${Tag.toHex(code)}");

    log.down;
    log.debug('$rbb _readPrivateGroup: code${Tag.toHex(code)}');
    int group = Group.fromTag(code);
    int elt = Elt.fromTag(code);
    PrivateGroup pg = new PrivateGroup(group);
    currentDS.privateGroups.add(pg);

    int nextCode;
    // Private Group Lengths are retired but still might be present.
    if (elt == 0x0000) nextCode = _readPGLength(group, code, isExplicitVR, pg);

    // There should be no [Element]s with [Elt] numbers between 0x01 and 0x0F.
    // [Elt]s between 0x01 and 0x0F are illegal.
    if (elt < 0x0010) nextCode = _readPIllegal(group, code, isExplicitVR, pg);

    // [Elt]s between 0x10 and 0xFF are [PrivateCreator]s.

    if (elt >= 0x10 && elt <= 0xFF)
      nextCode = _readPCreators(group, code, isExplicitVR, pg);
    log.debug('subgroups: ${pg.subgroups}');

    // Read the PrivateData
    if (Group.fromTag(nextCode) == group)
      _readAllPData(group, nextCode, isExplicitVR, pg);

    log.debug('$ree _readPrivateGroup-end $pg');
    log.up;
    return pg;
  }

  // Check for Private Data 'in the wild', i.e. invalid.
  // This group has no creators
  int _readPGLength(int group, int code, bool isExplicitVR, PrivateGroup pg) {
    log.down;
    log.debug('$rbb _readPGroupLength: ${Tag.toDcm(code)}');
    Tag tag = new PrivateTag.groupLength(code);
    Element e = _readElement(tag, isExplicitVR);
    log.debug('$rmm _readPGroupLength e: $e');
    PrivateGroupLength pe = new PrivateGroupLength(tag, e);
    currentDS.add(pe);
    pg.gLength = pe;
    log.debug('$ree _readPGroupLength pe: ${pe.info}');
    log.up;
    return _readTagCode();
  }

  // Reads 'Illegal' [PrivateElement]s in the range (gggg,0000) - (gggg,000F).
  int _readPIllegal(int group, int code, bool isExplicitVR, PrivateGroup pg) {
    log.down;
    log.debug('$rbb _readPIllegal: ${Tag.toDcm(code)}');
    int nextCode = code;
    int g;
    int elt;
    while (g == group && elt < 0x10) {
      log.debug('$rbb _readPIllegal: ${Tag.toDcm(code)}');
      PrivateTag tag = new PrivateTag.illegal(code);
      Element e = _readElement(tag, isExplicitVR);
      log.debug('$rmm _readPIllegal e: $e');
      PrivateElement pe = new PrivateIllegal(e);
      pg.illegal.add(pe);
      currentDS.add(pe);
      log.debug('$ree _readPIllegal pe: ${pe.info}');
      log.up;

      // Check the next TagCode.
      nextCode = _readTagCode();
      g = Group.fromTag(nextCode);
      elt = Elt.fromTag(nextCode);
      log.debug('$rmm Next group(${Group.hex(g)}), Elt(${Group.hex(g)})');
    }
    return nextCode;
  }

  // Read the Private Group Creators.  There can be up to 240 creators
  // with [Elt]s from 0x10 to 0xFF. All the creators come before the
  // [PrivateData] [Element]s. So, read all the [PrivateCreator]s first.
  // Returns when the first non-creator code is encountered.
  // VR = LO or UN
  // Returns the code of the next element.
  //TODO: this can be cleaned up and optimized if needed
  int _readPCreators(int group, int code, bool isExplicitVR, PrivateGroup pg) {
    //   pg.creators = <PrivateCreator>[];
    log.down;
    log.debug('$rbb readAllPCreators');
    int nextCode = code;
    int g;
    int elt;
    do {
      log.down;
      log.debug('$rbb _readPCreator: ${Tag.toDcm(nextCode)}');
      VR vr;
      int vfLength;
      // **** read PCreator
      if (isExplicitVR) {
        vr = _readExplicitVR();
        log.debug('$rmm _readPCreator: $vr');
        if (vr != VR.kLO && vr != VR.kUN) throw 'Bad Private Creator VR($vr)';
        vfLength = (vr.hasShortVF) ? readUint16() : _readLongLength();
      } else {
        log.debug(
            '$rmm _readImplicitVR: ${Tag.toDcm(nextCode)} vfLength($vfLength})');
        vr = VR.kUN;
        vfLength = readUint32();
      }
      // Read the Value Field for the creator token.
      List<String> values = _readDcmUtf8VF(vfLength);
      if (values.length != 1) throw 'InvalidCreatorToken($values)';
      String token = values[0];
      log.debug('nextCode: $nextCode');
      var tag = new PrivateCreatorTag(token, nextCode, vr);
      log.debug('Tag: $tag');
      LO e = new LO(tag, values);
      log.debug('LO: ${e.info}');
      log.debug('LO.code: $nextCode');
      log.debug('e.tag: ${e.tag.info}');
      log.debug('e: ${e.info}');
      var pc = new PrivateCreator(e.tag, e);
      log.debug('$ree _readElement: ${pc.info}');
      log.up;
      var psg = new PrivateSubGroup(pg, pc);
      log.debug('$rmm _readElement: pc($pc)');
      log.debug('$rmm _readElement: $psg');
      currentDS.add(pc);
      // **** end read PCreator

      nextCode = _readTagCode();
      g = Group.fromTag(nextCode);
      elt = Elt.fromTag(nextCode);
      log.debug('$rmm Next group(${Group.hex(g)}), Elt(${Group.hex(g)})');
    } while (g == group && (elt >= 0x10 && elt <= 0xFF));

    log.debug('$ree readAllPCreators-end: $pg');
    log.up;
    return nextCode;
  }

  void _readAllPData(int group, int code, bool isExplicitVR, PrivateGroup pg) {
    // Now read the [PrivateData] [Element]s for each creator, in order.
    log.down;
    log.debug('$rbb _readAllPData');
    int nextCode = code;
    while (group == Group.fromTag(nextCode)) {
      log.debug('nextCode: ${Tag.toDcm(nextCode)}');
      var sgIndex = Elt.fromTag(nextCode) >> 8;
      log.debug('sgIndex: $sgIndex');
      var sg = pg[sgIndex];
      log.debug('Subgroup: $sg');
      if (sg == null) {
        log.warn('This is a Subgroup without a creator');
        sg = new PrivateSubGroup(pg, PrivateCreator.kNonExtantCreator);
      }
      log.debug('Subgroup: $sg');
      nextCode = _readPDSubgroup(nextCode, isExplicitVR, sg);
      log.debug('Subgroup: $sg');
      log.debug('nextCode: nextCode');
    }
    log.debug('$ree _readAllPData-end');
    log.up;
  }

  int _readPDSubgroup(int code, bool isExplicitVR, PrivateSubGroup sg) {
    int nextCode = code;
    //?? while (pcTag.isValidDataCode(nextCode)) {
    PrivateCreator pc = sg.creator;
    PrivateCreatorTag pcTag = pc.tag;
    log.debug('pdInSubgroupt${Tag.toDcm(nextCode)}: ${pc.inSubgroup(nextCode)
    }');
    while (pc.inSubgroup(nextCode)) {
      log.down;
      log.debug('$rbb _readPDataSubgroup: base(${Elt.hex(pc.base)}), '
          'limit(${Elt.hex(pc.limit)})');

      PrivateDataTag dTag = pcTag.lookupData(code);
      log.debug('_readPDataSubgroup: pdTag: ${dTag.info}');
      Element e = _readElement(dTag, isExplicitVR);
      log.debug('_readPDataSubgroup: e: ${e.info}');
      PrivateData pd = new PrivateData(dTag, e);
      log.debug('_readPDataSubgroup: pd: ${pd.info}');
      pc.add(pd);
      log.debug('_readPDataSubgroup: pc: ${pc.info}');
      currentDS.add(e);

      log.debug('$rmm readPD: ${e.info})');
      log.up;
      nextCode = _readTagCode();
    }
    return nextCode;
  }

  /* Flush if not needed.
  Element _readPrivateData(bool isExplicitVR, PrivateCreator pc) {
    log.down;
    int code = _readTagCode();
    log.debug('$rbb _readPrivateData: ${Tag.toDcm(code)} $pc');
    int vfLength;
    VR vr;
    if (isExplicitVR) {
      vr = _readExplicitVR();
      vfLength = (vr.hasShortVF) ? readUint16() : _readLongLength();
      log.debug(
          '$rmm _readExplicitVR: ${Tag.toDcm(code)} $vr, vfLength($vfLength})');
    } else {
      vr = VR.kUN;
      vfLength = readUint32();
      log.debug(
          '$rmm _readImplicitVR: ${Tag.toDcm(code)} $vr, vfLength($vfLength})');
    }
    //Urgent: there are two cases here known and unknown privateTag.
    PrivateData pd = pc.lookupData(code);
    log.debug('$rmm _readPrivateData: $pd');
    Tag tag = pd.tag;
    assert(pd.tag != null);
    VR tagVR = tag.vr;
    log.debug('$rmm _readPrivateData: ${Tag.toDcm(code)}, $tag, tagVR($tagVR');
    Element e = _readValueField(tag, vfLength, tag.vr.index);
    log.debug('$ree _readPrivateData code: ${Tag.toDcm(code)}, e: $e');
  //  PrivateData pd = new PrivateData(code, e);
    log.debug('$ree _readPrivateData pd: ${pd.info}');
    log.up;
    return pd;
  }
*/
  // Returns the position of the next valid Public or Private tag.
  //TODO: eventually to be used in trying to read corrupted studies.
  /*
  int _findNextValidTag() {
    int start = readIndex;
    //TODO: finish
    return -1;
  }
  */

  //TODO: improve
  void _debugReader(tag, obj, [int vfLength, String msg]) {
    // [readIndex] should be at start + 6
    var label;
    if (tag is Tag) {
      label = tag.dcm;
    } else if (tag is int) {
      label = Int.hex(tag);
    } else {
      label = tag.toString();
    }
    var s = '''

debugReader:
  $rrr: $label $msg
    short Length: ${Int.hex(getUint16(readIndex), 4)}
    long Length: ${Int.hex(getUint32(readIndex + 2), 8)}
     bytes: [${toHex(readIndex - 12, readIndex + 12, readIndex)}]
    string: "${toAscii(readIndex - 12, readIndex + 12, readIndex)}"
''';
    log.error(s);
  }
}
