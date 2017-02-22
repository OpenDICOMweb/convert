// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/dataset.dart';
import 'package:core/element.dart';
import 'package:core/log.dart';
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
  static final Logger log = new Logger("DcmReader", logLevel: Level.debug1);

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
    while (isReadable)  {
      log.debug('$rmm buf: $this');
      readElement(isExplicitVR: isExplicitVR);
    }

    log.debug('$ree readRootDataset: $rootDS');
    //  log.up;
    return rootDS;
  }

  bool _hasPrefix() {
    skipReadBytes(128);
    final String prefix = readString(4);
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

  VR _readExplicitVR(int code) {
    //TODO: merge into one call _readExplicitVR()
    int vrCode = readUint16();
    log.debug('$rmm _readExplicitVR: ${Tag.toDcm(code)} ${Uint16.hex(vrCode)}');
    int vrIndex = VR.indexOf(vrCode);
    assert(vrIndex != null);
    return VR.vrs[vrIndex];
  }

  /// Reads a zero or more [Private Groups] and then read an returns
  /// a Public [Element].
  void readElement({bool isExplicitVR: true}) {
    log.down;
    final int code = _peekTagCode();
    log.debug('$rbb readElement: _peekTag${Tag.toDcm(code)}');
    if (Tag.isPublicCode(code)) {
      log.down;
      log.debug('$rbb readPublicElement: isExplicitVR($isExplicitVR)');
      Element e = _readPublicElement(isExplicitVR);
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
  }

  Element _readPublicElement(bool isExplicitVR) {
    // Element Readers
    log.down;
    log.debug('$rbb _readPublicElement:');
    int code = _readTagCode();
    log.debug('$rmm code=${Tag.toDcm(code)}');
    Tag tag = Tag.lookupPublicCode(code);
    assert(tag != null);
    log.debug('$rmm _readPublicElement: ${tag.info}');
    int vfLength;
    VR vr;
    if (isExplicitVR) {
      vr = _readExplicitVR(code);
      vfLength = (vr.hasShortVF) ? readUint16() : _readLongLength();
      log.debug('$rmm _readExplicitVR: ${tag.dcm} $vr, vfLength($vfLength})');
    } else {
      vr = tag.vr;
      vfLength = readUint32();
      log.debug('$rmm _readImplicitVR: ${tag.dcm} $vr, vfLength($vfLength})');
    }
    log.debug('$rmm _readPublicElement: vfLength($vfLength)');
    Element e = _readValueField(tag, vfLength, vr.index);
    log.debug('$ree _readPublicElement: ${e.info}');
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
  AE _readAE(Tag tag, int vfLength) => new AE(tag, _readDcmString(vfLength));
  AS _readAS(Tag tag, int vfLength) => new AS(tag, _readDcmString(vfLength));
  CS _readCS(Tag tag, int vfLength) => new CS(tag, _readDcmString(vfLength));
  DA _readDA(Tag tag, int vfLength) => new DA(tag, _readDcmString(vfLength));
  DS _readDS(Tag tag, int vfLength) => new DS(tag, _readDcmString(vfLength));
  DT _readDT(Tag tag, int vfLength) => new DT(tag, _readDcmString(vfLength));
  IS _readIS(Tag tag, int vfLength) => new IS(tag, _readDcmString(vfLength));
  LO _readLO(Tag tag, int vfLength) => new LO(tag, _readDcmString(vfLength));
  LT _readLT(Tag tag, int vfLength) => new LT(tag, _readDcmString(vfLength));
  PN _readPN(Tag tag, int vfLength) => new PN(tag, _readDcmString(vfLength));
  SH _readSH(Tag tag, int vfLength) => new SH(tag, _readDcmString(vfLength));
  ST _readST(Tag tag, int vfLength) => new ST(tag, _readDcmString(vfLength));
  TM _readTM(Tag tag, int vfLength) => new TM(tag, _readDcmString(vfLength));
  UC _readUC(Tag tag, int vfLength) => new UC(tag, _readDcmString(vfLength));
  UI _readUI(Tag tag, int vfLength) =>
      new UI(tag, _readDcmString(vfLength, kNull));
  UR _readUR(Tag tag, int vfLength) => new UR(tag, _readDcmString(vfLength));
  UT _readUT(Tag tag, int vfLength) => new UT(tag, _readDcmString(vfLength));

  /// Returns a [String].  If [padChar] is [kSpace] just returns the [String]
  /// if [padChar] is [kNull], it is removed by returning a [String] with
  /// [length - 1].
  /// Note: This calls [readString] in [ByteBuf].
  List<String> _readDcmString(int vfLength, [int padChar = kSpace]) {
    if (vfLength == 0) return const <String>[];
    if (vfLength.isOdd || vfLength == kUndefinedLength) {
      _debugReader(null, null, vfLength, "bad vfLength");
      log.fatal(
          '_readDcmStringError: vfLength=$vfLength(${Int32.hex(vfLength)})');
    }
    String s = readString(vfLength);
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
    for (int i = 0; i < vfLength; i++) list[i] = _readTagCode();
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
      values = (lengthInBytes == 0)
          ? Uint8.emptyList
          : readUint8View(lengthInBytes);
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
      e = new OBPixelData.fromBytes(tag, vfLength, ts, nFrames, vf);
    } else {
      e = new OB(tag, vfLength, vf);
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
      e = new OWPixelData.fromBytes(tag, vfLength, ts, nFrames, vf);
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
    UN e = new UN(tag, vfLength, bytes);
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
  PrivateGroup _readPrivateGroup(int code, {bool isExplicitVR: true}) {
    assert(Group.isPrivate(Group.fromTag(code)),
        "Non Private Group ${Tag.toHex(code)}");
    int group = Group.fromTag(code);
    log.down;
    log.debug('$rbb readPrivateGroup: code${Tag.toHex(code)}');

    // Check for Private Data without Creator.
    if (Tag.isPrivateDataCode(code))
      _readInvalidPrivateData(group, code, isExplicitVR);

    List<PrivateCreator> pCreators = _readPCreators(group, isExplicitVR);
    _readAllPData(group, pCreators, isExplicitVR);
    PrivateGroup pg = new PrivateGroup(group, pCreators);
    currentDS.privateGroups.add(pg);
    log.debug('$ree readPrivateGroup-end $pg');
    log.up;
    return pg;
  }

  // Check for Private Data 'in the wild', i.e. invalid.
  // This group has no creators
  PrivateGroup _readInvalidPrivateData(int group, int code, bool isExplicitVR) {
    assert(Tag.isPrivateDataCode(code));
    log.down;
    log.debug('_readInvalidPrivateData: ${Tag.toDcm(code)}');
    var pData  = <PrivateData>[];

    do {
      log.down;
      int code = _readTagCode();
      log.debug('$rbb _readPrivateData: ${Tag.toDcm(code)}');
      int vfLength;
      VR vr;
      if (isExplicitVR) {
        vr = _readExplicitVR(code);
        vfLength = (vr.hasShortVF) ? readUint16() : _readLongLength();
        log.debug('$rmm _readExplicitVR: ${Tag.toDcm(code)} $vr, vfLength($vfLength})');
      } else {
        vr = VR.kUnknown;
        vfLength = readUint32();
        log.debug('$rmm _readImplicitVR: ${Tag.toDcm(code)} $vr, vfLength($vfLength})');
      }
      //Urgent: try to look this up.
      //PrivateDataTag tag = pc.lookupData(code);
      PrivateDataTag tag = new PrivateDataTag.unknown(code);
      VR tagVR = tag.vr;
      log.debug('$rmm _readPrivateData: ${Tag.toDcm(code)}, $tag, tagVR($tagVR');
      Element e = _readValueField(tag, vfLength, tag.vr.index);
      log.debug('$ree _readPrivateData e: $e');
      PrivateData pd = new PrivateData(code, e);
      currentDS.add(pd);
      pData.add(pd);
      log.debug('$ree _readPrivateData pd: ${pd.info}');
      log.up;
    } while (group == Group.fromTag(_peekTagCode()));

    PrivateGroup pg = new BadPrivateGroup(group, pData);
    currentDS.privateGroups.add(pg);
    log.debug('_readInvalidPrivateData-end: $pg');
    log.up;
    return pg;
  }

  // Read the Private Group Creators.  There can be up to 240 creators
  // with [Elt]s from 0x10 to 0xFF. All the creators come before the
  // [PrivateData] [Element]s. So, read all the [PrivateCreator]s first.
  //TODO: this can be cleaned up and optimized if needed
  List<PrivateCreator> _readPCreators(int group, bool isExplicitVR) {
    var pCreators = <PrivateCreator>[];
    log.down;
    log.debug('$rbb readPCreators');
    do {
      log.down;
      int code = _peekTagCode();
      log.debug('$rbb readPCreator: ${Tag.toDcm(code)}');
      int g = Group.fromTag(code);
      log.debug('$rmm PC group(${Group.hex(g)})');
      if (g != group) log.error('$rmm Bad Group(${Group.hex(g)} '
            'while reading ${Group.hex(group)}');
      PrivateCreator e = _readPrivateCreator(isExplicitVR);
      pCreators.add(e);
      currentDS.add(e);
      log.debug('$ree readPCreato-end: $e, ${e.info}');
      log.up;
    } while (Tag.isPrivateCreatorCode(_peekTagCode()));
    log.debug('$ree readPCreators-end: $pCreators');
    log.up;
    return pCreators;
  }

  Element   _readPrivateCreator(bool isExplicitVR) {
    log.down;
    int code = _readTagCode();
    log.debug('$rbb _readPCreator:: ${Tag.toDcm(code)}');
    int vfLength;
    VR vr;
    if (isExplicitVR) {
      vr = _readExplicitVR(code);
      vfLength = (vr.hasShortVF) ? readUint16() : _readLongLength();
      log.debug('$rmm _readExplicitVR: ${Tag.toDcm(code)} $vr, vfLength($vfLength})');
    } else {
      vr = VR.kUnknown;
      vfLength = readUint32();
      log.debug('$rmm _readImplicitVR: ${Tag.toDcm(code)} $vr, vfLength($vfLength})');
    }
    List<String> values = _readDcmString(vfLength);
    Element e = new PrivateCreator(code, vr, values);
    log.debug('$ree _readPCreator:: ${e.info}');
    log.up;
    return e;
  }

  void _readAllPData(
      int group, List<PrivateCreator> pCreators, bool isExplicitVR) {
    // Now read the [PrivateData] [Element]s for each creator, in order.
    log.debug('$rbb readAllPData');
    for (int i = 0; i < pCreators.length; i++) {
      PrivateCreator pc = pCreators[i];
      PrivateCreatorTag tag = pc.tag;
      int base = tag.base;
      int limit = tag.limit;
      List<Element> pgData = [];

      log.down;
      log.debug('$rbb readPData: base(${Elt.hex(base)}), '
          'limit(${Elt.hex(limit)})');

      int code = _peekTagCode();
      do {
        log.down;
        log.debug('$rbb readPD: code(${Tag.toDcm(code)})');
        Element e = _readPrivateData(isExplicitVR, pc);
        log.debug('$rmm readPD: ${e.info})');
        pc.add(e);
        currentDS.add(e);
        log.debug('$rmm readPD: ${e.info}');
        log.up;
        code = _peekTagCode();
        bool valid = Tag.isValidPrivateDataTag(code, pc.code);
        log.debug('$rmm ${Tag.toDcm(code)}, pc${Tag.toDcm(pc.code)} $valid');
      } while (Tag.isValidPrivateDataTag(code, pc.code));
      log.debug('$ree readAllPDataset end: ${pgData.length} data elements');
      log.up;
    }
    //Urgent: what if there are other private elements without creators.
    log.debug('$ree readAllPData-end');
    log.up;
  }

  Element   _readPrivateData(bool isExplicitVR, PrivateCreator pc) {
    log.down;
    int code = _readTagCode();
    log.debug('$rbb _readPrivateData: ${Tag.toDcm(code)} $pc');
    int vfLength;
    VR vr;
    if (isExplicitVR) {
      vr = _readExplicitVR(code);
      vfLength = (vr.hasShortVF) ? readUint16() : _readLongLength();
      log.debug('$rmm _readExplicitVR: ${Tag.toDcm(code)} $vr, vfLength($vfLength})');
    } else {
      vr = VR.kUnknown;
      vfLength = readUint32();
      log.debug('$rmm _readImplicitVR: ${Tag.toDcm(code)} $vr, vfLength($vfLength})');
    }
    PrivateDataTag tag = pc.lookupData(code);
    log.debug('$rmm _readPrivateData: $tag');
    if (tag == null) tag = new PrivateDataTag.unknown(code, pc.token);
    assert(tag != null);
    VR tagVR = tag.vr;
    log.debug('$rmm _readPrivateData: ${Tag.toDcm(code)}, $tag, tagVR($tagVR');
    Element e = _readValueField(tag, vfLength, tag.vr.index);
    log.debug('$ree _readPrivateData code: ${Tag.toDcm(code)}, e: $e');
    PrivateData pd = new PrivateData(code, e);
    log.debug('$ree _readPrivateData pd: ${pd.info}');
    log.up;
    return pd;
  }

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
