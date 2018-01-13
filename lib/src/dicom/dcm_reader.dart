// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:convert/src/bytebuf/bytebuf.dart';
import 'package:core/core.dart';


//TODO: remove log.debug when working

//TODO: rewrite all comments to reflect current state of code

/// The type of the different Value Field readers.  Each [VFReader]
/// reads the Value Field for a particular Value Representation.
typedef Element<K, T, V> VFReader<K, T, V>(int tag, VR<V> vr, int vfLength);

//The type of a Tag TagMaker.
typedef Tag _TagMaker(int code, VR vr, [extra]);

/// A library for parsing [Uint8List] containing DICOM File Format [Dataset]s.
///
/// Supports parsing LITTLE ENDIAN format in the super class [ByteBuf].
/// _Notes_:
///   1. In all cases DcmReader reads and returns the Value Fields as they
///   are in the data, for example DcmReader does not trim whitespace from
///   strings.  This is so they can be written out byte for byte as they were
///   read. and a byte-wise comparator will find them to be equal.
///   2. All String manipulation should be handled in the attribute itself.
///   3. All VFReaders allow the Value Field to be empty.  In which case they
///   return the empty [List] [].
class DcmReader<E> extends ByteBuf {
  ///TODO: doc
  static final Logger log = new Logger("DcmReader", watermark: Severity.info);

  /// The root Dataset for the object being read.
  final RootDataset rootDS;

  final String path;

  //TODO: remove this it's not necessary
  /// A stack of [Dataset]s.  Used to save parent [Dataset].
//flush  final DatasetStack dsStack = new DatasetStack();

  /// If [true] errors will throw; otherwise, return [null].
  final bool throwOnError;

  final bool allowILEVR;

  /// The current dataset.  This changes as Sequences are read and
  /// [Items]s are pushed on and off the [dsStack].
  Dataset currentDS;
  bool prefixPresent;
  bool fmiPresent;

  //*** Constructors ***

  //TODO: finish
  /// Creates a new [DcmReader]  where [readIndex] = [writeIndex] = 0.
  DcmReader(Uint8List bytes, this.rootDS,
      {this.path = "", this.throwOnError = false, this.allowILEVR = true})
      : super.reader(bytes) {
    _warnIfShortFile(bytes.lengthInBytes);
    currentDS = rootDS;
  }
  //TODO: finish
  /// Creates a new [DcmReader]  where [readIndex] = [writeIndex] = 0.
  DcmReader.fromSource(DSSource source,
      {RootDataset rootDS,
      this.path = "",
      this.throwOnError = false,
      this.allowILEVR = true})
      : rootDS = (rootDS == null) ? new RootDataset() : rootDS,
        super.reader(source.bytes) {
    _warnIfShortFile(source.bytes.lengthInBytes);
    currentDS = rootDS;
  }

  /// Creates a [Uint8List] with the same length as the elements in [list],
  /// and copies over the elements.  Values are truncated to fit in the list
  /// when they are copied, the same way storing values truncates them.
  DcmReader.fromList(List<int> list,
      {this.path = "", this.throwOnError = false, this.allowILEVR = true})
      : rootDS = new RootDataset(),
        super.fromList(list) {
    _warnIfShortFile(list.length);
    currentDS = rootDS;
  }

  /// Returns [true] if the [Dataset] being read has an
  /// Explicit VR Transfer Syntax.
  bool get isExplicitVR =>
      rootDS.transferSyntax != TransferSyntax.kImplicitVRLittleEndian;

  @override
  String get info => '$runtimeType: rootDS: ${rootDS.info}, currentDS: '
      '${currentDS.info}';

  /// Reads a [RootDataset] from [this] and returns it. If an error is
  /// encountered [readRootDataset] will throw an Error is or [null].
  RootDataset readRootDataset([bool allowMissingFMI = false]) {
    int start = readIndex;
    prefixPresent = _hasPrefix();
    log.debug('$rbb readRootDataset: $rootDS');

    bool hasFmi = readFMI();
    if (!hasFmi) return null;

    var ts = rootDS.transferSyntax;
    log.debug('$rmm readRootDataset: TS($ts)}, isExplicitVR: $isExplicitVR');
    if (!rootDS.hasValidTransferSyntax) {
      if (throwOnError) throw new InvalidTransferSyntaxError(ts, log);
      log.up;
      return rootDS;
    }
    if (ts == TransferSyntax.kExplicitVRBigEndian)
      throw new InvalidTransferSyntaxError(ts);

    readDataset(rootDS.isExplicitVR);

    log.reset;
    log.debug('start($start), readIndex($readIndex), lengthInBytes'
        '($lengthInBytes)');
    if (start != 0 || readIndex != lengthInBytes) {
      log.error('Did not read to end of file: Start($start), readIndex'
          '($readIndex) lengthInBytes($lengthInBytes): $this');
      if (throwOnError) throw 'Terminated before EOF';
    }
    log.debug('$ree readRootDataset: $rootDS');
    log.up;
    return rootDS;
  }

  Dataset readDataset([bool isExplicitVR = true]) {
    log.down;
    log.debug('$rbb readDataset: isExplicitVR($isExplicitVR)');
    try {
      while (isReadable) _readElement(isExplicitVR);
    } on EndOfDataException catch (e) {
      log.debug(e);
    }
    log.debug('$ree end readDataset: isExplicitVR($isExplicitVR)');
    log.up;
    return rootDS;
  }

  void _readElement([bool isExplicitVR = true]) {
    final int code = _readTagCode();
    log.debug('$rmm readElement: _readCode${Tag.toDcm(code)}');
    if (Tag.isPublicCode(code)) {
      Element e = _xReadElement(code, PTag.maker, isExplicitVR);
      log.debug('$rmm readPublicElement: ${e.info}');
      currentDS[e.tag.code] = e;
      return;
    } else if (Tag.isPrivateCode(code)) {
      PrivateGroup e = _readPrivateGroup(code, isExplicitVR);
      currentDS.privateGroups.add(e);
      log.debug('$rmm readPrivateGroup: ${e.info}');
      return;
    } else {
      Element e = _xReadElement(code, PTag.unknownMaker, isExplicitVR);
      log.debug('$rmm readIllegalElement: ${e.info}');
      currentDS[e.tag.code] = e;
      return;
    }
    //   if (throwOnError) tagCodeError(code);
    //   _debugReader(code, code);
    //   return;
  }

  // **** Internal Method from here to Test Interface ****
  bool _hasPrefix() {
    skipReadBytes(128);
    final String prefix = readAsciiString(4);
    if (prefix == "DICM") return true;
    log.warn('No DICOM Prefix present');
    skipReadBytes(-132);
    return false;
  }

  /// Reads File Meta Information ([Fmi]). If any [Fmi] [Element]s
  /// were present returns true.
  bool readFMI() {
    log.down;
    log.debug('$rbb readFmi($currentDS)');
    setReadIndexMark;
    try {
      while (isReadable) {
        int code = _readTagCode();
        if (code >= 0x00080000) {
          unreadBytes(4);
          break;
        }
        Element value = _xReadElement(code, PTag.maker, true);
        currentDS[value.tag.code] = value;
        log.debug('$rmm _readFmi: ${value.info}');
      }
    } catch (e) {
      log.error('Failed to read FMI: "${rootDS.path}"');
      log.error('Exception: $e');
      log.error('File length: ${bytes.lengthInBytes}');
      resetReadIndexMark;
      log.up;
      return false;
    }
    log.debug('$ree readFmi: ${rootDS.transferSyntax}');
    log.up;
    return true;
  }

  /// Peek at next tag - doesn't move the [readIndex].
  int _peekTagCode() {
    //TODO: Do we really want to make all local variables final?
    // Doesn't it make it harder to read the code?
    final int group = getUint16(readIndex);
    final int element = getUint16(readIndex + 2);
    final int code = (group << 16) + element;
    return code;
  }

  ///TODO: this is expensive! Is there a better way?
  /// Read the DICOM Element Tag
  int _readTagCode() {
    if (isNotReadable) if (throwOnError) {
      throw new EndOfDataException('_readPCreators');
    } else {
      _debugReader(
          new Tag(0, VR.kUN),
          "Is not readable: readIndex "
          "$readIndex");
    }
    int group = readUint16();
    int elt = readUint16();
    int code = (group << 16) + elt;
    //TODO: remove when working
    log.debug('$rmm _readTagCode: group(${Group.hex(group)}), '
        'elt(${Elt.hex(elt)}), code(${Tag.toHex(code)})');
    return code;
  }

  Element<E> _xReadElement(int code, _TagMaker tagMaker, bool isExplicitVR) =>
      (isExplicitVR)
          ? _xReadExplicitElement(code, tagMaker)
          : _xReadImplicitElement(code, tagMaker);

  Element<E> _xReadExplicitElement(code, _TagMaker tagMaker) {
    VR _readExplicitVR() {
      int vrCode = readUint16();
      VR vr = VR.lookup(vrCode);
      assert(vr != null, 'Invalid null VR: code(${Uint16.hex(vrCode)})');
      return vr;
    }

    // Read a 16-bit or 32-bit Value Field Length field depending on the VR.
    int _readExplicitVFLength(VR vr) {
      if (vr.hasShortVF) return readUint16();
      skipReadBytes(2);
      return readUint32();
    }

    VR vr = _readExplicitVR();
    int vfLength = _readExplicitVFLength(vr);
    log.debug('$rmm _xReadExplicitElement ${Tag.toDcm(code)}, $vr, $vfLength');
    // Tag tag = tagMaker(code, vr);

    Element<E> e = _readValueField(code, vr, vfLength, tagMaker);
    log.debug('$rmm _xReadExplicitElement ${e.tag.info}');
    log.debug('$rmm _xReadExplicitElement ${e.info}');
    return e;
  }

  Element<E> _xReadImplicitElement(code, _TagMaker tagMaker) {
    final int vfLength = readUint32();
    return _readValueField(code, VR.kUN, vfLength, tagMaker);
  }

  Element<E> _readValueField<E>(
      int code, VR vr, int vfLength, _TagMaker tagMaker) {
    /// The order of the VRs in this [List] MUST correspond to the [index]
    /// in the definitions of [VR].  Note: the [index]es start at 1, so
    /// in this [List] the 0th dictionary is [_debugReader].
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
    log.debug('$rbb _readValueField: code${Tag.toDcm(code)}, '
        'index(${vr.index}) vfLength(${Int32.hex(vfLength)})');
    //TODO: make this work
    // VFReader vfReader = _getVFReader(vrIndex);
    var e;
    if (Tag.isPrivateCreatorCode(code)) {
      List<String> values = _readDcmUtf8VF(vfLength);
      Tag tag = tagMaker(code, vr, values[0]);
      e = new LO(tag, values);
      //TODO: is there a better way to do this?

    } else {
      Tag tag = tagMaker(code, vr);
      //   log.info('Tag: ${tag.info}');
      if (vr == VR.kUN) {
        log.debug('vr($vr), tag.vr(${tag.vr}');
        vr = tag.vr;
      }
      if (vr.index > 32) {
        vr = VR.kUN;
        log.debug('vr.index > 32: vr($vr), tag.vr(${tag.vr}');
      }
      final Function vfReader = _readers[vr.index];
      e = vfReader(tag, vfLength);
    }
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
  /// [String]. if [padChar] is [kNull], it is removed by returning a
  /// [String] with [length - 1].
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
        log.debug('$rmm Invalid $name($last) padChar');
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

  /// Converts [lengthInBytes] to [length] for 4-byte value types.
  int _bytesToLongs(int lengthIB) =>
      ((lengthIB & 0x3) == 0) ? lengthIB >> 2 : _lengthError(lengthIB, 4);

  int _lengthError(int vfLength, int sizeInBytes) {
    log.fatal('$wmm Invalid vfLength($vfLength) for elementSize($sizeInBytes)'
        'the vfLength must be evenly divisible by elementSize');
    return -1;
  }

  /// There are four [Element]s that might have an Undefined Length value
  /// (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
  /// then it searches for the matching [kSequenceDelimitationItem] to
  /// determine the length. Returns a [kUndefinedLength], which is used for
  /// reading the value field of these [Element]s. Returns an [SQ] [Element].
  SQ _readSequence(Tag tag, int vfLength) {
    log.down;
    List<Item> items = <Item>[];
    SQ sq = new SQ(tag, items,  vfLength);
    log.debug('$rbb ${sq.info}');
    if (vfLength == kUndefinedLength) {
      log.debug('$rmm SQ: ${tag.dcm} Undefined Length');
      int start = readIndex;
      while (!_sequenceDelimiterFound()) {
        Item item = _readItem(sq, isExplicitVR);
        items.add(item);
      }
      sq.lengthInBytes = (readIndex - 8) - start;
      log.debug('$rmm end of uLength SQ');
    } else {
      log.debug('$rmm SQ: ${tag.dcm} length($vfLength)');
      int limit = readIndex + vfLength;
      while (readIndex < limit) {
        Item item = _readItem(sq, isExplicitVR);
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
    log.debug('$rmm _delimiterFound($v) target${Int.hex(target)}, '
        'value${Int.hex(delimiter)}');
    if (delimiter == target) {
      int length = getUint32(4);
      log.debug(
          '$rmm target(${Int.hex(target)}), delimiter(${Int.hex(delimiter)}), '
          'length(${Int.hex(length, 8)}');
      if (length != 0) {
        var msg = '$rmm: Encountered non zero length($length)'
            ' following Undefined Length delimeter';
        log.error(msg);
      }
      log.debug('$rmm Found return false target(${Int.hex(target)}), '
          'delimiter(${Int.hex(delimiter)}), length(${Int.hex(length, 8)}');
      skipReadBytes(8);
      return true;
    }
    return false;
  }

  /// Returns [true] if the [kSequenceDelimitationItem] delimiter is found.
  bool _sequenceDelimiterFound() => _foundDelimiter(kSequenceDelimitationItem);

  /// Returns [true] if the [kItemDelimitationItem] delimiter is found.
  bool _itemDelimiterFound() => _foundDelimiter(kItemDelimitationItem);

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit
  // & readElementExplicit
  /// Returns an [Item] or Fragment.
  Item _readItem(SQ sq, isExplicitVR) {
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
          _readElement(isExplicitVR);
        }
        // [readIndex] is at the end of delimiter and length (8 bytes)
        item.actualLengthInBytes = (readIndex - 8) - start;
      } else {
        int limit = readIndex + vfLength;
        while (readIndex < limit) _readElement(isExplicitVR);
      }
    } on EndOfDataException {
      log.debug('_readItem');
      rethrow;
    } finally {
      // Restore previous parent
      currentDS = dsStack.pop;
      log.debug('$ree readItemElements: ds($currentDS) ${item.info}');
    }
    int end = readIndex;
    item.actualLengthInBytes = end - start;
    log.up;
    log.debug1('$ree _readItem ${item.info}');
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
    if (tag == PTag.kPixelData) {
      TransferSyntax ts = currentDS.transferSyntax;
      log.debug('$rmm PixelData: $ts');
      IS e0 = currentDS[kNumberOfFrames];
      int nFrames = (e == null) ? 1 : e0.value;
      log.debug('$rmm nFrames: $nFrames, ts: $ts');
      e = new OBPixelData.fromBytes(tag, vf, vfLength, ts, nFrames);
    } else {
      e = new OB.fromBytes(tag, vf, vfLength);
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
    if (tag == PTag.kPixelData) {
      TransferSyntax ts = currentDS.transferSyntax;
      log.debug('$rmm PixelData: $ts');
      IS e0 = currentDS[kNumberOfFrames];
      int nFrames = (e == null) ? 1 : e0.value;
      log.debug('$rmm nFrames: $nFrames, ts: $ts');
      e = new OWPixelData.fromBytes(tag, vfLength, ts, vf, nFrames);
    } else {
      e = new OW.fromBytes(tag, vf, vfLength);
    }
    log.debug('$ree ${e.info}');
    log.up;
    return e;
  }

  UN _readUN(Tag tag, int vfLength) {
    log.down;
    log.debug('$rbb tag${tag.dcm}');
    Uint8List bytes = _uLengthGetBytes(vfLength);
    log.debug('$rmm vfLength($vfLength, ${Int32.hex(vfLength)}), '
        'bytes.length(${bytes.length})');
    UN e = new UN.fromBytes(tag, bytes, vfLength);
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
  PrivateGroup _readPrivateGroup(int code, bool isExplicitVR) {
    assert(Group.isPrivate(Group.fromTag(code)),
        "Non Private Group ${Tag.toHex(code)}");

    log.down;
    log.debug('$rbb _readPrivateGroup: code${Tag.toHex(code)}');
    int group = Group.fromTag(code);
    PrivateGroup pg = new PrivateGroup(group);
    currentDS.privateGroups.add(pg);

    int nextCode = code;
    int elt = Elt.fromTag(nextCode);
    // Private Group Lengths are retired but still might be present.
    if (elt == 0x0000) nextCode = _readPGLength(nextCode, isExplicitVR, pg);

    // There should be no [Element]s with [Elt] numbers between 0x01 and 0x0F.
    // [Elt]s between 0x01 and 0x0F are illegal.
    elt = Elt.fromTag(nextCode);
    if (elt < 0x0010)
      nextCode = _readPIllegal(group, nextCode, isExplicitVR, pg);

    // [Elt]s between 0x10 and 0xFF are [PrivateCreator]s.
    elt = Elt.fromTag(nextCode);
    if (elt >= 0x10 && elt <= 0xFF)
      nextCode = _readPCreators(group, nextCode, isExplicitVR, pg);
    log.debug('subgroups: ${pg.subgroups}');

    // Read the PrivateData
    if (Group.fromTag(nextCode) == group)
      nextCode = _readAllPData(group, nextCode, isExplicitVR, pg);

    // Unread the last code read.
    unreadBytes(4);
    log.debug('$ree _readPrivateGroup-end $pg');
    log.up;
    return pg;
  }

  // Check for Private Data 'in the wild', i.e. invalid.
  // This group has no creators
  int _readPGLength(int code, bool isExplicitVR, PrivateGroup pg) {
    log.down;
    log.debug('$rbb _readPGroupLength: ${Tag.toDcm(code)}');
    Element<E> e =
        _xReadElement(code, PrivateGroupLengthTag.maker, isExplicitVR);
    log.debug('$rmm _readPGroupLength e: $e');
    // Add to issues if not VR.kUL
    if (e is! UL) currentDS.issues[e.code] = e;
    currentDS.add(e);
    pg.gLength = e;
    log.debug('$ree _readPGroupLength pe: ${e.info}');
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
      Element e = _xReadElement(code, PTag.maker, isExplicitVR);
      log.debug('$rmm _readPIllegal e: $e');
      //  PrivateElement pe = new PrivateIllegal(e);
      pg.illegal.add(e);
      currentDS.add(e);
      log.debug('$ree _readPIllegal pe: ${e.info}');
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
    do {
      log.down;
      log.debug('$rbb _readPCreator: ${Tag.toDcm(nextCode)}');
      // **** read PCreator
      Element e = _xReadElement(nextCode, PCTag.maker, isExplicitVR);
      log.debug('$rmm _readPCreator tag: ${e.tag.info}');
      log.debug('$rmm _readPCreator e:${e.info}');
      // TODO: test this in verifier
      //    if (e.vr != VR.kLO && e.vr != VR.kUN)
      //      throw 'Bad Private Creator VR(${e.vr})';
      if (e.values.length != 1) throw 'InvalidCreatorToken(${e.values})';
      var pc = new PrivateCreator(e);
      log.debug('$ree _readElement: ${e.info}');
      var psg = new PrivateSubGroup(pg, pc);
      log.debug('$rmm _readElement: pc($e), $psg');
      currentDS.add(e);
      // **** end read PCreator
//TODO: create Group.equal(int code0, int code1)
//TODO: create Tag.codeInGroup(int code, int group)
//TODO: Tag.isCreatorInGroup(int code, int group)
      nextCode = _readTagCode();
    } while (Tag.isCreatorCodeInGroup(nextCode, group));

    log.debug('$ree readAllPCreators-end: $pg');
    log.up;
    return nextCode;
  }

  int _readAllPData(int group, int code, bool isExplicitVR, PrivateGroup pg) {
    // Now read the [PrivateData] [Element]s for each creator, in order.
    log.down;
    log.debug('$rbb _readAllPData');
    int nextCode = code;
    while (group == Group.fromTag(nextCode)) {
      log.down;
      log.debug('$rmm nextCode: ${Tag.toDcm(nextCode)}');
      var sgIndex = Elt.fromTag(nextCode) >> 8;
      log.debug('$rmm sgIndex: ${Tag.toHex(sgIndex)}');
      var sg = pg[sgIndex];
      log.debug('$rmm Subgroup: $sg');
      if (sg == null) {
        //Flush next
        log.debug('$rmm group(${Group.hex(group)}), '
            'nextCode${Tag.toDcm(nextCode)}, sgIndex(${Elt.hex(sgIndex)})');
        log.warn('$rmm This is a Subgroup without a creator');
        var pc = new PrivateCreator.phantom(nextCode);
        log.info('Phantom Creator: $pc');
        sg = new PrivateSubGroup(pg, pc);
      }
      log.debug('$rmm Subgroup: $sg nextCode: ${Tag.toDcm(nextCode)}');
      nextCode = _readPDSubgroup(nextCode, isExplicitVR, sg);
      log.debug('$rmm Subgroup: $sg nextCode: ${Tag.toDcm(nextCode)}');
      log.up;
      if (nextCode == null) throw new EndOfDataException('_readAllPData');
    }

    // Read any Invalid Elements in this Group, but not in range.
    if (Group.fromTag(nextCode) == group) {
      log.debug('$rmm Invalid PData: Group($group),'
          ' nextCode( ${Tag.toDcm(nextCode)})');
      do {
        log.down;
        nextCode = _readPIllegal(group, nextCode, isExplicitVR, pg);
        log.up;
      } while (Group.fromTag(nextCode) == group);
    }
    log.debug('$ree _readAllPData-end');
    log.up;
    return nextCode;
  }

  int _readPDSubgroup(int code, bool isExplicitVR, PrivateSubGroup sg) {
    int nextCode = code;
    PrivateCreator pc = sg.creator;
    log.down;
    log.debug('$rbb readPDSubgroup${Tag.toDcm(nextCode)}: '
        '${pc.inSubgroup(nextCode)}');
    while (pc.inSubgroup(nextCode)) {
      log.down;
      log.debug('$rmm _readPDSubgroup: base(${Elt.hex(pc.base)}), '
          'limit(${Elt.hex(pc.limit)})');
      _TagMaker maker =
          (int nextCode, VR vr, [name]) => new PDTag(nextCode, vr, pc.tag);
      Element<E> pd = _xReadElement(nextCode, maker, isExplicitVR);
      log.debug('$rmm _readPDataSubgroup: pd: ${pd.info}');
      //TODO remove next line
      pc.add(pd);
      //Flush sg.add(pd);
      currentDS.add(pd);
      log.up;
      nextCode = _readTagCode();
    }
    log.debug('$ree end _readPDInSubgroupt${Tag.toDcm(nextCode)}: $sg');
    log.up;
    return nextCode;
  }

  static const int kMinFileLength = 4096;

  static void _warnIfShortFile(int length) {
    if (length < kMinFileLength) log.warn('**** Trying to read $length bytes');
  }

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

// External Interface for Testing
// **** These methods should not be used in the code above ****

  /// Returns [true] if the File Meta Information was present and
  /// read successfully.
  TransferSyntax xReadFmi([bool checkForPrefix = true]) {
    if (checkForPrefix && !_hasPrefix()) return null;
    bool hasFMI = readFMI();
    if (!hasFMI || !rootDS.hasValidTransferSyntax) return null;
    return rootDS.transferSyntax;
  }

  Element<E> xReadPublicElement([bool isExplicitVR = true]) =>
      _xReadElement(_readTagCode(), PTag.maker, isExplicitVR);

  // External Interface for testing
  Element<E> xReadPGLength([bool isExplicitVR = true]) =>
      _xReadElement(_readTagCode(), PrivateGroupLengthTag.maker, isExplicitVR);

  // External Interface for testing
  Element<E> xReadPrivateIllegal(int code, [bool isExplicitVR = true]) =>
      _xReadElement(_readTagCode(), PTag.maker, isExplicitVR);

  // External Interface for testing
  Element<E> xReadPrivateCreator([bool isExplicitVR = true]) =>
      _xReadElement(_readTagCode(), PCTag.maker, isExplicitVR);

  // External Interface for testing
  Element<E> xReadPrivateData(Element pc, [bool isExplicitVR = true]) {
    _TagMaker maker =
        (int nextCode, VR vr, [name]) => new PDTag(nextCode, vr, pc.tag);
    return _xReadElement(_readTagCode(), maker, isExplicitVR);
  }

  static RootDataset fmi(Uint8List bytes, [String path = ""]) {
    DcmReader reader = new DcmReader(bytes, path: path);
    return (reader.readFMI()) ? reader.rootDS : null;
  }

  static RootDataset rootDataset(Uint8List bytes, [String path = ""]) {
    DcmReader reader = new DcmReader(bytes, path: path);
    return reader.readRootDataset();
  }

  static RootDataset dataset(Uint8List bytes, [String path = ""]) {
    DcmReader reader = new DcmReader(bytes, path: path);
    return reader.readDataset();
  }
}
