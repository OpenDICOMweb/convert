// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:io';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

import 'package:convertX/bytebuf.dart';
import 'package:convertX/src/dcm_reader_base.dart';
import 'package:core/src/dicom_utils.dart';

//TODO: rewrite all comments to reflect current state of code

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
typedef TElement<E> VFReader<E>(int tag, VR<E> vr, int vfLength);

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
class DcmReader extends DcmReaderBase {
  final RootTDataset rootDS;
  TDataset currentDS;

  //TODO: Doc
  /// Creates a new [DcmReader]  where [_rIndex] = [writeIndex] = 0.
/*  DcmReader(this.bd,
      {this.path = "",
      this.throwOnError = true,
      this.allowILEVR = true,
      this.allowMissingFMI = false,
      this.targetTS})
      : endOfBD = bd.lengthInBytes,
        rootDS = new RootDataset.fromByteData(bd,
            path: path, hadUndefinedLength: true) {
    _warnIfShortFile();
  }*/

  DcmReader(ByteData bd,
      {String path = "",
      bool throwOnError = true,
      bool allowILEVR = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS})
      : rootDS = new RootTDataset.fromByteData(bd, hadUndefinedLength: true),
        super(bd,
            path: path,
            throwOnError: throwOnError,
            allowILEVR: allowILEVR,
            allowMissingFMI: allowMissingFMI,
            targetTS: targetTS);

  /// Creates a new [DcmReader]  where [_rIndex] = [writeIndex] = 0.
  factory DcmReader.fromBytes(Uint8List bytes,
      {String path = "",
      bool throwOnError = true,
      bool allowILEVR = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS}) {
    var bd = bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    return new DcmReader(bd, path: path, targetTS: targetTS);
  }

/*
  /// Creates a [Uint8List] with the same length as the elements in [list],
  /// and copies over the elements.  Values are truncated to fit in the list
  /// when they are copied, the same way storing values truncates them.
  factory DcmReader.fromList(List<int> list,
      {bool throwOnError = false,
      String path = "",
      bool allowILEVR = true,
      bool allowMissingFMI = false,
      TransferSyntax targetTS}) {
    Uint8List bytes = new Uint8List.fromList(list);
    ByteData bd = bytes.buffer.asByteData();
    return new DcmReader(bd,
        path: path,
        throwOnError: throwOnError,
        allowILEVR: allowILEVR,
        allowMissingFMI: allowMissingFMI,
        targetTS: targetTS);
  }
*/

  /// [true] if the source [ByteData] have been read.
  bool get wasRead => (_wasRead == null) ? false : _wasRead;
  bool _wasRead;
  set wasRead(bool v) => _wasRead ??= v;

  /// [true] if the source [ByteData] has been read.
  bool get hasParsingErrors =>
      (_hasParsingErrors == null) ? false : _hasParsingErrors;
  bool _hasParsingErrors;

  //****  Core Dataset methods  ****

  /// Returns an [Map<int, Element] or [null].
  ///
  /// This is the top-level entry point for reading a [Dataset].
  //TODO: validate that [ds] is being handled correctly.
  //TODO: flush count argument when working
  TDataset readRootDataset([int count = 100000]) {
    if (!_hasPrefix()) return null;
    //  log.down;
    log.debug('$rbb readRootDataset: $rootDS');
    if (!readFMI()) return null;
    if (rootDS.transferSyntax == null) throw "Unsupported Null TransferSyntax";
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

  bool _hasPrefix() {
    skipReadBytes(128);
    final String prefix = readAsciiString(4);
    return (prefix == "DICM");
  }

  // ToDo: replace with dcm_byte_data reader
  /// Reads File Meta Information ([Fmi]). If any [Fmi] [Element]s
  /// were present returns true.
  bool readFMI() {
    log.down;
    log.debug2('$rbb readFmi($currentDS)');
    if (isReadable && currentDS is RootTDataset) {
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
 //   return rootDS.transferSyntax;
    return true;
  }

  /// Peek at next tag - doesn't move the [readIndex].
  int _peekTagCode() {
    //Issue: do we really want to make all local variables final?
    //Issue: Doesn't it make it harder to read the code?
    final int group = getUint16(readIndex);
    final int element = getUint16(readIndex + 2);
    final int code = (group << 16) + element;
    return code;
  }

  // Performance: this is expensive! Is there a better way?
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
  void readElement({bool isExplicitVR: true}) {
    final int code = _readTagCode();
    log.debugDown('$rbb readElement: _peekTag${Tag.toDcm(code)}');
    if (Tag.isPublicCode(code)) {
      log.debugDown('$rbb readPublicElement: isExplicitVR($isExplicitVR)');
      TElement e = _readElement(code, isExplicitVR);
      currentDS[e.tag.code] = e;
      log.debugUp('$ree readPublicElement: ${e.info}');
    } else if (Tag.isPrivateCode(code)) {
      log.debugDown('$rbb readPrivateGroup');
      // This should read the whole Private Group before returning.
      PrivateGroup pg = _readPrivateGroup(code, isExplicitVR: isExplicitVR);
      log.debugUp('$ree readPrivateGroup: $pg');
    } else {
      _debugReader(code, code);
      tagCodeError(code);
    }
    log.debugUp('$ree readElement');
  }

  /// Reads an [TElement], either Public or Private. Does not inspect
  /// [Tag]; rather, assumes it is correct, but reads [VR], if explicit,
  /// [vfLength] and Value Field;
  TElement _readElement(int code, bool isExplicitVR) {
    log.debugDown('$rbb _readElement: ${Tag.toDcm(code)}');
    Tag tag;
    VR vr;
    int vfLength;
    if (isExplicitVR) {
      vr = _readExplicitVR();
      tag = Tag.lookupPublicCode(code, vr);
      log.debug('$rmm _readElement: vr($vr), tag.vr(${tag.vr})');
      if (vr != tag.vr)
        log.warn('$rmm _readElement: *** vr($vr) !=  tag.vr(${tag.vr})');
      if (vr == VR.kUN) vr = tag.vr;
      if (tag == PTag.kPixelData &&
          (vr != VR.kOB && vr != VR.kOW) &&
          vr != VR.kUN) throw 'Bad VR($vr) != tag.vr(${tag.vr})';
      vfLength = (vr.hasShortVF) ? readUint16() : _readLongLength();
      log.debug('$rmm _readExplicitVR: ${tag.info} $vr, vfLength($vfLength})');
    } else {
      vr = VR.kUN;
      Tag tag = Tag.lookupPublicCode(code, vr);
      /* flush when working
      if (code == kPixelData) {
        vr = VR.kUN;
      } else {
        vr = tag.vr;
        //  throw 'Bad VR($vr) != tag.vr(${tag.vr})';
      }
      */
      vr = tag.vr;
      vfLength = readUint32();
      log.debug('$rmm _readImplicitVR: $tag $vr, vfLength($vfLength})');
    }
    TElement e = _readValueField(tag, vfLength, vr.index);
    log.debug('$ree _readTElement: ${e.info}');
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

  TElement _readValueField(Tag tag, int vfLength, int index) {
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
    TElement e = vfReader(tag, vfLength);
    log.debug('$ree _readValueField: ${e.info}');
    log.up;
    return e;
  }

  //**** VR Readers ****

  //**** Readers of [String] [TElement]s
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
  List<String> _readDcmAsciiVF(int vfLength, [int padChar = kSpace]) {
    if (vfLength == 0) return _emptyStringList;
    _checkStringVF(vfLength);
    return _dicomStringToList(readUtf8String(vfLength), padChar);
  }

  List<String> _readDcmUtf8VF(int vfLength, [int padChar = kSpace]) {
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
  List<String> _dicomStringToList(String s, int padChar) {
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

  //**** Readers of 16-bit [TElement]s
  SS _readSS(Tag tag, int vfLength) =>
      new SS.fromBytes(tag, readUint8View(vfLength));
  US _readUS(Tag tag, int vfLength) =>
      new US.fromBytes(tag, readUint8View(vfLength));

  //**** Readers of 32-bit [TElement]s
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

  //**** Readers of 64-bit [TElement]s
  FD _readFD(Tag tag, int vfLength) =>
      new FD.fromBytes(tag, readUint8View(vfLength));
  OD _readOD(Tag tag, int vfLength) =>
      new OD.fromBytes(tag, readUint8View(vfLength));

  /// Reader of AT [TElement]s (2 x 16-bits = 32-bit)
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

  //**** [TElement]s that may have an Undefined Length in the Value Field

  /// There are four [TElement]s that might have an Undefined Length value
  /// (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the
  /// Undefined, then it searches for the matching [kSequenceDelimitationItem]
  /// to determine the length. Returns a [kUndefinedLength], which is used for reading
  /// the value field of these [TElement]s.

  /// Returns an [SQ] [TElement].
  SQ _readSequence(Tag tag, int vfLength) {
    log.down;
    List<TItem> items = <TItem>[];
    SQ sq = new SQ(tag, items, vfLength);
    log.debug('$rbb ${sq.info}');
    if (vfLength == kUndefinedLength) {
      log.debug('$rmm SQ: ${tag.dcm} Undefined Length');
     // int start = readIndex;
      while (!_sequenceDelimiterFound()) {
        TItem item = _readItem(sq);
        items.add(item);
      }
      // Fix
      //     sq.lengthInBytes = (readIndex - 8) - start;
      log.debug('$rmm end of uLength SQ');
    } else {
      log.debug('$rmm SQ: ${tag.dcm} length($vfLength)');
      int limit = readIndex + vfLength;
      while (readIndex < limit) {
        TItem item = _readItem(sq);
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
        log.error(msg);
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

  //TODO this can be moved to Dataset_base if we abstract DatasetExplicit
  // & readElementExplicit
  /// Returns an [TItem] or Fragment.
  TItem _readItem(SQ sq) {
    log.down;
    log.debug('$rbb readItem for ${sq.info}');
    int itemStartCode = _readTagCode();
    log.debug('$rmm item tag(${itemStartCode.toRadixString(16)})');
    if (itemStartCode != kItem) _debugReader(itemStartCode, "Bad Item Tag");
    int vfLength = readUint32();
    log.debug('$rmm item length(${vfLength.toRadixString(16)})');
    TItem item = new TItem(currentDS, <int, TElement>{}, vfLength, sq);
    log.debug('$rmm Item ${item.info}');

    // Save parent [Dataset], and make [item] the current [Dataset].
    TDataset parentDS = currentDS;
    currentDS = item;
    log.down;
    log.debug('$rbb readItemElements parent($parentDS) '
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
      currentDS = parentDS;
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

  /// Read and return an [OB] [TElement].
  ///
  /// Note: this should not be used for PixelData TElements.
  TElement _readOB(Tag tag, int vfLength) {
    Uint8List vf = _uLengthGetBytes(vfLength);
    log.down;
    log.debug('$rbb $tag, $vfLength, $vf.length');
    log.debug('$rbb readOB vfLength(${Int32.hex(vfLength)})');
    TElement e;
    if (tag == PTag.kPixelData) {
      TransferSyntax ts = currentDS.transferSyntax;
      e = new OB.fromBytes(tag, vf, vfLength, ts: ts);
    } else {
      e = new OB.fromBytes(tag, vf, vfLength);
    }
    log.debug('$ree readOB ${e.info}');
    log.up;
    return e;
  }

  TElement _readOW(Tag tag, int vfLength) {
    Uint8List vf = _uLengthGetBytes(vfLength);
    log.down;
    log.debug('$rbb readOW $tag, vfLength($vfLength), vf.length(${vf.length})');
    TElement e;
    if (tag == PTag.kPixelData) {
      TransferSyntax ts = currentDS.transferSyntax;
      log.debug('$rmm PixelData: $ts');
      //TODO: frameLength or offsets which is better
     // Fix: int frameLength = vf.length ~/ nFrames;
      e = new OW.fromBytes(tag, vf, vfLength,  ts);
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
    log.debug(
        '$rmm vfLength($vfLength, ${Int32.hex(vfLength)}), bytes.length(${bytes.length})');
    UN e = new UN.fromBytes(tag, bytes, vfLength);
    log.debug('e= $e');
    log.debug('$ree ${e.info}');
    log.up;
    return e;
  }

  /// Reads and returns a [PrivateGroup].
  ///
  /// A [PrivateGroup] contains all the  [PrivateCreator] and the corresponding
  /// [PrivateData] Data [TElement]s with the same (private) group number.
  ///
  /// This method is called when the first Private Tag Code in a Private Group
  /// is encountered, and control remains in this group until the next
  /// Public Group is encountered.
  ///
  /// _Notes_:
  ///     1. All PrivateCreators are read before any of the [PrivateData]
  /// [TElement]s are read.
  ///
  ///     2. PrivateCreators for one private group all occur before their
  /// corresponding Private Data TElements.
  ///
  ///     3. It is possible to encounter a Private Data TElement that does
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

    // There should be no [TElement]s with [Elt] numbers between 0x01 and 0x0F.
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
    log.debugDown('$rbb _readPGroupLength: ${Tag.toDcm(code)}');

    TElement e = _readElement(code, isExplicitVR);
    log.debug('$rmm _readPGroupLength e: $e');
    PrivateGroupLength pgl = new PrivateGroupLength(e.tag, e);
    currentDS.add(pgl);
    pg.gLength = pgl;
    log.debugUp('$ree _readPGroupLength pe: ${pgl.info}');
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
      TElement e = _readElement(tag.code, isExplicitVR);
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
  // [PrivateData] [TElement]s. So, read all the [PrivateCreator]s first.
  // Returns when the first non-creator code is encountered.
  // VR = LO or UN
  // Returns the code of the next TElement.
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
      var tag = new PCTag(nextCode, vr, token);
      log.debug('Tag: $tag');
      LO e = new LO(tag, values);
      log.debug('LO: ${e.info}');
      log.debug('LO.code: $nextCode');
      log.debug('e.tag: ${e.tag.info}');
      log.debug('e: ${e.info}');
      var pc = new PrivateCreator(e);
      log.debug('$ree _readTElement: ${pc.info}');
      log.up;
      var psg = new PrivateSubGroup(pg, pc);
      log.debug('$rmm _readTElement: pc($pc)');
      log.debug('$rmm _readTagElement: $psg');
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
        var creator = new PrivateCreator.phantom(nextCode);
        sg = new PrivateSubGroup(pg, creator);
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
    PCTag pcTag = pc.tag;
    log.debug('pdInSubgroupt${Tag.toDcm(nextCode)}: ${pc.inSubgroup(nextCode)
    }');
    while (pc.inSubgroup(nextCode)) {
      log.down;
      log.debug('$rbb _readPDataSubgroup: base(${Elt.hex(pc.base)}), '
          'limit(${Elt.hex(pc.limit)})');

      PDTagKnown pdTagDef = pcTag.lookupData(nextCode);
      assert(nextCode == pdTagDef.code);
      log.debug('_readPDataSubgroup: pdTag: ${pdTagDef.info}');
      TElement e = _readElement(nextCode, isExplicitVR);
      log.debug('_readPDataSubgroup: e: ${e.info}');
      //  PrivateElement pd = new PrivateData(pdTagDef, e);
      //  log.debug('_readPDataSubgroup: pd: ${pd.info}');
      pc.add(e);
      log.debug('_readPDataSubgroup: pc: ${pc.info}');
      currentDS.add(e);

      log.debug('$rmm readPD: ${e.info})');
      log.up;
      nextCode = _readTagCode();
    }
    return nextCode;
  }

/*  void _warnIfShortFile() {
    int length = bd.lengthInBytes;
    if (length < smallFileThreshold) {
      var s = 'Short file error: length(${bd.lengthInBytes}) $path';
      _hasParsingErrors = true;
      throw s;
    }
    if (length < smallFileThreshold)
      log.warn('**** Trying to read $length bytes');
  }*/

  /* Flush if not needed.
  TElement _readPrivateData(bool isExplicitVR, PrivateCreator pc) {
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
    TElement e = _readValueField(tag, vfLength, tag.vr.index);
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
    bytes: [${toHex(readIndex - 12, 8)}, ${toHex(readIndex, 8)} ${toHex
      (readIndex + 12, 8)}] 
  
    string: "${toAscii(bd, readIndex - 12, readIndex + 12, readIndex)}"
''';
    log.error(s);
  }

// External Interface for Testing
// **** These methods should not be used in the code above ****

  TElement xReadElement({bool isExplicitVR = true}) {
    final int code = _readTagCode();
    return _readElement(code, isExplicitVR);
  }

  /// Returns [true] if the File Meta Information was present and
  /// read successfully.
  TransferSyntax xReadFmi([bool checkForPrefix = true]) {
    if (!readFMI()) return null;
    if (!rootDS.hasFMI || !rootDS.hasValidTransferSyntax) return null;
    return rootDS.transferSyntax;
  }

  TElement xReadPublicElement([bool isExplicitVR = true]) =>
      _readElement(_readTagCode(), isExplicitVR);

  // External Interface for testing
  TElement xReadPGLength([bool isExplicitVR = true]) =>
      _readElement(_readTagCode(), isExplicitVR);

  // External Interface for testing
  TElement xReadPrivateIllegal(int code, [bool isExplicitVR = true]) =>
      _readElement(_readTagCode(), isExplicitVR);

  // External Interface for testing
  TElement xReadPrivateCreator([bool isExplicitVR = true]) =>
      _readElement(_readTagCode(), isExplicitVR);

  // External Interface for testing
  TElement xReadPrivateData(TElement pc, [bool isExplicitVR = true]) {
    //  _TagMaker maker =
    //      (int nextCode, VR vr, [name]) => new PDTag(nextCode, vr, pc.tag);
    return _readElement(_readTagCode(), isExplicitVR);
  }

  // Reads
  TDataset xReadDataset([bool isExplicitVR = true]) {
    log.debug('$rbb readDataset: isExplicitVR($isExplicitVR)');
    while (isReadable) {
      var e = _readElement(_readTagCode(), isExplicitVR);
      rootDS.add(e);
      e = rootDS[e.code];
      assert(e == e);
    }
    log.debug('$ree end readDataset: isExplicitVR($isExplicitVR)');
    return currentDS;
  }

/*  static RootTDataset fmi(Uint8List bytes,
      {String path = "", TransferSyntax targetTS}) {
    ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmReader reader = new DcmReader(bd, path: path, targetTS: targetTS);
    return reader.currentDSMI();
  }

  static RootTDataset rootDataset(Uint8List bytes,
      {String path = "", TransferSyntax targetTS}) {
    ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmReader reader = new DcmReader(bd, path: path, targetTS: targetTS);
    return reader.readRootDataset();
  }

  static RootTDataset dataset(Uint8List bytes,
      {String path = "", TransferSyntax targetTS}) {
    ByteData bd =
        bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
    DcmReader reader = new DcmReader(bd, path: path, targetTS: targetTS);
    return reader.xReadDataset();
  }

  static RootTDataset readBytes(Uint8List bytes,
      {String path: "", bool fmiOnly = false, TransferSyntax targetTS}) {
    if (fmiOnly) return DcmReader.fmi(bytes, path: path);
    return DcmReader.rootDataset(bytes, path: path);
  }

  static RootTDataset readFile(File file,
      {bool fmiOnly = false, TransferSyntax targetTS}) {
    Uint8List bytes = file.readAsBytesSync();
    return readBytes(bytes,
        path: file.path, fmiOnly: fmiOnly, targetTS: targetTS);
  }*/
  static RootTDataset readBytes(Uint8List bytes,
      {String path: "",
      bool fmiOnly = false,
      fast = true,
      TransferSyntax targetTS}) {
    if (bytes == null) throw new ArgumentError('readBytes: $bytes');
    return DcmReader.readDataset(bytes,
        path: path, fmiOnly: fmiOnly, targetTS: targetTS);
  }

  static RootTDataset readFile(File file,
      {bool fmiOnly = false, bool fast: false, TransferSyntax targetTS}) {
    if (file == null) throw new ArgumentError('readFile: $file');
    Uint8List bytes = file.readAsBytesSync();
    return readBytes(bytes,
        path: file.path, fmiOnly: fmiOnly, targetTS: targetTS);
  }

  static RootTDataset readPath(String path,
          {bool fmiOnly = false, bool fast = false, TransferSyntax targetTS}) =>
      readFile(new File(path),
          fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);

  static TDataset readDataset(obj,
      {String path = "",
      bool fmiOnly = false,
      fast = false,
      TransferSyntax targetTS}) {
    if (obj is String)
      return readPath(obj, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    if (obj is File)
      return readFile(obj, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    if (obj is Uint8List)
      return readBytes(obj,
          path: path, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    throw new ArgumentError('$obj');
  }

  static Instance readInstance(obj,
      {String path = "",
      bool fmiOnly = false,
      fast = false,
      TransferSyntax targetTS}) {
    var rds = readDataset(obj,
        path: path, fmiOnly: fmiOnly, fast: fast, targetTS: targetTS);
    return new Instance.fromDataset(rds);
  }
}
