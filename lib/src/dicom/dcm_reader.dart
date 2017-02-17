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
    log.down;
    log.debug('$rbb readRootDataset: $rootDS');
    TransferSyntax ts = _readFmi();
    if (ts == null) throw "Unsupported Null TransferSyntax";
    log.debug('$rmm readRootDataset: transferSyntax(${rootDS.transferSyntax})');
    log.debug('$rmm readRootDataset: ${rootDS.hasValidTransferSyntax}');
    if (!rootDS.hasValidTransferSyntax) return rootDS;
    final bool isExplicitVR =
        rootDS.transferSyntax != TransferSyntax.kImplicitVRLittleEndian;
    log.debug('$rmm readRootDataset: isExplicitVR($isExplicitVR)');
    while (isReadable) readElement(isExplicitVR: isExplicitVR);
    log.debug('$ree readRootDataset: $rootDS');
    log.up;
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
// flush
//  Tag _peekTag() => Tag.lookupCode(_peekTagCode());

  /// Reads a zero or more [Private Groups] and then read an returns
  /// a Public [Element].
  void readElement<E>({bool isExplicitVR: true}) {
    log.down;
    final int code = _peekTagCode();
    log.debug('$rbb readElement: _peekTag${Tag.toDcm(code)}');
    //  print('tag.isPublic: code(${Tag.toHex(code)}, isPublic(${Tag.isPublicCode(code)})');
    // int group = Group.fromTag(code);
    //  print('group.isPublic: ${Group.isPublic(group)}');
    //  print('group: ${Group.hex(group)}');
    //  print('isPublicGroup: ${Group.hex(Group.fromTag(code))}');
    if (Tag.isPublicCode(code)) {
      Element<E> e = (isExplicitVR) ? _readExplicit() : _readImplicit();
      log.debug('$rmm readElement:${e.info}');
      currentDS[e.tag.code] = e;
    } else {
      _readPrivateGroup(code, isExplicitVR: isExplicitVR);
    }
    log.debug('$ree readElement:');
    log.up;
  }

  Element<E> _readExplicit<E>() {
    // Element Readers
    log.down;
    Tag tag = _readTag();
    int vrCode = readUint16();
    int vrIndex = VR.indexOf(vrCode);
    log.debug('$rbb _readExplicit: ${tag.dcm}, vrIndex($vrIndex)');
    if (vrIndex == null) throw "bad vrIndex";
    VR vr = VR.vrs[vrIndex];
    if (vr == null) _debugReader(tag, vr);
    log.debug('$rmm _readExplicit: ${tag.dcm} VR[$vrIndex] $vr');
    int vfLength = (vr.hasShortVF) ? readUint16() : _readLongLength();
    log.debug('$rmm _readExplicit: vfLength($vfLength)');
    Element<E> e = _readValueField(tag, vfLength, vrIndex);
    log.debug('$ree _readExplicit: ${e.info}');
    log.up;
    return e;
  }

  Element<E> _readImplicit<E>() {
    // Element Readers
    log.down;
    Tag tag = _readTag();
    int vrIndex = tag.vrIndex;
    log.debug('$rbb _readElement: $tag');
    int vfLength = readUint32();
    Element<E> e = _readValueField(tag, vfLength, vrIndex);
    log.debug('$ree _readImplicit: ${e.info}');
    log.up;
    return e;
  }

  ///TODO: this is expensive! Is there a better way?
  /// Read the DICOM Element Tag
  int _readTagCode() {
    int group = readUint16();
    int element = readUint16();
    int code = (group << 16) + element;
    return code;
  }

  Tag _readTag() => Tag.lookupCode(_readTagCode());

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
        '$rbb _readValueField: tag${tag.dcm}, vfLength($vfLength), index($index)');
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
    if (vfLength.isOdd || vfLength == kUndefinedLength)
      log.fatal('_readDcmStringError: vfLength=$vfLength(${Int32.hex(vfLength)})');
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
    Item item = new Item(
      currentDS,
      <int, Element>{},
      sq,
      vfLength,
    );
    log.debug('$rmm ${item.info}');

    // Save parent [Dataset], and make [item] is new parent [Dataset].
    dsStack.push(currentDS);
    currentDS = item;
    log.down;
    log.debug(
        '$rbb readItemElements parent(${dsStack.last}) child(${currentDS.info}');
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
      log.debug('$rmm values.length(${values.length}');
      log.debug(
          '$rmm Undefined vfLength(${Int32.hex(vfLength)}), lengthInBytes($lengthInBytes)');
    } else {
      lengthInBytes = vfLength;
      log.debug('$wmm vfLength($vfLength)');
      values =
          (lengthInBytes == 0) ? Uint8.emptyList : readUint8View(lengthInBytes);
      log.debug(
          '$rmm vfLength(${Int32.hex(vfLength)}), lengthInBytes($lengthInBytes)');
    }
    log.debug('$ree _uLengthGetBytes-end: values.length(${values.length})');
    log.up;
    return values;
  }

  /// Read and return an [OB] [Element].
  ///
  /// Note: this should not be used for PixelData Elements.
  Element _readOB(Tag tag, int vfLength) {
    log.down;
    log.debug('$rbb readOB vfLength(${Int32.hex(vfLength)})');
    Uint8List bytes = _uLengthGetBytes(vfLength);
    Element e;
    if (tag == Tag.kPixelData) {
      UI tsUid = currentDS[kTransferSyntaxUID];
      TransferSyntax ts = tsUid.uid;
      int nFrames = currentDS[kNumberOfFrames].value;
      e = new OBPixelData.fromBytes(tag, vfLength, ts, nFrames, bytes);
    } else {
      e = new OB(tag, vfLength, bytes);
    }
    log.debug('$ree readOB ${e.info}');
    log.up;
    return e;
  }

  Element _readOW(Tag tag, int vfLength) {
    Uint8List vf = _uLengthGetBytes(vfLength);
    if (tag == Tag.kPixelData) return _readOWPixelData(tag, vfLength, vf);
    log.down;
    log.debug('$rbb readOW bytes.length(${vf.length}');
    OW e = new OW(tag, vfLength, vf);
    log.debug('$ree ${e.info}');
    log.up;
    return e;
  }

  /// Reads and decodes Pixel Data into BulkPixelData.
  OWPixelData _readOWPixelData(tag, int vfLength, Uint8List vf) {
    UI tsUid = currentDS[kTransferSyntaxUID];
    TransferSyntax ts = tsUid.uid;
    int nFrames = currentDS[kNumberOfFrames].value;
    return new OWPixelData.fromBytes(tag, vfLength, ts, nFrames, bytes);
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
  /// [PrivateData] Data [Element]s with the same private group number.
  ///
  /// Note: All PrivateCreators are read before any of the [PrivateData]
  /// [Element]s are read.
  ///
  /// Note: PrivateCreators for one private group all occur before their
  /// corresponding Private Data Elements.
  /*
        while (true) {
            tag = _peekTag();
            if (Tag.isPrivate(tag)) {
                log.debug('$rmm PeekTag${tag.dcm} Private');
                PrivateGroup pg = _readPrivateGroups(tag, isExplicitVR: isExplicitVR);
                currentDS.privateGroups.add(pg);
            } else {
                break;
            }
        }
        */
  // This is called when the first Private Tag Code in a Private Group is encountered,
  // and control remains in this group until the next Public Tag Code is encountered.
  PrivateGroup _readPrivateGroup(int code, {bool isExplicitVR: true}) {
    var pCreators = <PrivateCreator>[];
    int group = Group.fromTag(_peekTagCode());
    if (Group.isNotPrivate(group))
      _debugReader(code, '_readPrivateGroups: non-Private Group($group)');
    log.down;
    log.debug('$rbb readPrivateGroup: tag(${Group.hex(group)}');

    // Read the Private Group Creators
    // There can be up to 240 creators with [Elt]s from 0x10 to 0xFF.
    // All the creators come before the [PrivateData] [Element]s. So,
    // read all the [PrivateCreator]s first.
    log.down;
    log.debug('$rbb readPrivateCreators');
    do {
      log.down;
      log.debug(
          '$rbb readPrivateCreator: peekTag(${Tag.toDcm(code)}) ${Tag.isPrivateCreatorCode
        (code)}');
      int g = Group.fromTag(code);
      log.debug('$rmm PC group(${Group.hex(g)})');
      if (g != group)
        log.error(
            '$rmm Bad Group(${Group.hex(g)} while reading for ${Group.hex(group)}');
      Element e = (isExplicitVR) ? _readExplicit() : _readImplicit();
      PrivateCreator creator = e;
      pCreators.add(creator);
      currentDS.add(e);
      code = _peekTagCode();
      log.debug('$rmm isPrivateCreator(${Tag.isPrivateCreatorCode(code)}');
      log.debug('$ree readPrivateCreator-end: $creator, ${e.info}');
      log.up;
    } while (Tag.isPrivateCreatorCode(code));
    log.debug('$ree readPrivateCreators-end: creators: $pCreators');
    log.up;
    /*
    while (true) {
      log.down;
      int tag = _peekTag();
      //log.debug('$mmm isPrivateGroup ${Group.isPrivate(group)}');
      //log.debug('$mmm isPrivateCreator ${Elt.isPrivateCreator(Tag.elt(tag))}');
      // log.debug('$mmm ${!tag.isPrivateCreator}');
      log.debug('$rbb readPrivateCreator: peekTag(${tag.dcm}) ${tag.isPrivateCreator}');
      if (!tag.isPrivateCreator) {
        log.debug('$ree readPrivateCreator-end: peekTag(${tag.dcm}');
        log.up;
        break;
      }

      int g = tag.group;
      log.debug('$rmm PC group(0x${Group.hex(g)})');
      if (g != group) log.error('Bad Group(${Group.hex(g)} while reading for ${Group.hex(group)}');
      Element e = _readElement(isExplicitVR: isExplicitVR);
      var creator = new PrivateCreator(e.tag, e);
      log.debug('$rmm readPrivateCreator: $creator, ${e.info}');
      pCreators.add(creator);
      currentDS[e.tag] = e;
      log.up;
    }
    log.debug('$ree readPrivateCreators-end: (${pCreators.length})$pCreators');
    log.up;
*/

    // Read the [PrivateData] [Element]s
    log.down;
    log.debug('$rbb readPrivateData');
    List<Element> pgData = [];
    for (int i = 0; i < pCreators.length; i++) {
      PrivateCreator pc = pCreators[i];
      PrivateCreatorTag tag = pc.tag;
      int base = tag.base;
      int limit = tag.limit;

      log.down;
      log.debug(
          '$rbb readPrivateDataSet: base(${Elt.hex(base)}), limit(${Elt.hex(limit)})');
      while (Tag.isPrivateDataCode(code)) {
        log.down;
        log.debug(
            '$rbb readPD: peekTag(${Tag.toDcm(code)}), isPD(${Tag.isPrivateDataCode(code)})');
        PrivateData e = (isExplicitVR) ? _readExplicit() : _readImplicit();
        PrivateDataTag tag = e.tag;
        if (!tag.isPrivateData)
          //TODO: decide what to do
          //IssueType.invalidPrivateDataTagNoCreator,
          // IssueElement issue = new IssueElement(e);
          pgData.add(e);
        currentDS.add(e);
        // Peek at the next tag for the loop;
        code = _peekTagCode();
        log.debug('$ree readPD: ${e.info}');
        log.up;
      }
      log.debug('$ree readPrivateDataSet end: ${pgData.length} data elements');
      log.up;

      /*
      log.down;
      log.debug('$rbb readPrivateDataSet: base(${Elt.hex(base)}), limit(${Elt.hex(limit)})');
      while (true) {
        log.down;
        var tag = _peekTag();
        log.debug('$rbb readPD: peekTag(${tag.dcm}), ''isPD(${tag.isPrivateData})');
        if (tag.group != group) {
          log.debug('$ree readPD peekTag(${tag.dcm})');
          log.up;
          break;
        }
        var elt = Tag.elt(tag);
        if (elt < base || limit < elt) {
          log.debug('$ree readPD peekTag(${tag.dcm})');
          log.up;
          break;
        }
        Element e = _readElement();
        log.debug('$ree readPD: ${e.info}');
        log.up;
        pgData.add(e);
        currentDS[e.tag] = e;
      }
      log.debug('$ree readPrivateDataSet end: ${pgData.length} data elements');
      log.up;
*/
    }

    log.debug('$ree readPrivateData-end');
    log.up;
    PrivateGroup pg = new PrivateGroup(group, pCreators, pgData);
    log.debug('$ree readPrivateGroup-end $pg');
    log.up;
    currentDS.privateGroups.add(pg);
    return pg;
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
