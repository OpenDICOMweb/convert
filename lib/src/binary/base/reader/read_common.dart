// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

// There are four [Element]s that might have an Undefined Length value
// (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
// then it searches for the matching [kSequenceDelimitationItem32Bit] to
// determine the length. Returns a [kUndefinedLength], which is used for
// reading the value field of these [Element]s. Returns an [SQ] [Element].

bool _isSequenceVR(int vrIndex) => vrIndex == 0;

bool _isSpecialVR(int vrIndex) =>
    vrIndex >= kVRSpecialIndexMin && vrIndex <= kVRSpecialIndexMax;

bool _isNormalVR(int vrIndex) =>
    vrIndex >= kVRNormalIndexMin && vrIndex <= kVRNormalIndexMax;

bool _isMaybeUndefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isEvrLongVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isEvrShortVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isIvrDefinedLengthVR(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;

final String kItemAsString = hex32(kItem32BitLE);

bool _inItem;

void __readRootDataset() {
	log
		..reset
	  ..debug('${_rb.rbb} readRootDataset');
	_readDatasetDefinedLength(_rds, _rb.rIndex, _rb.remaining, _readEvrElement);
	log.debug('${_rb.ree} readRootDataset $_elementCount Elements read with '
			          '${_rb.remaining} bytes remaining\nDatasets: ${_pInfo.nDatasets}');
}
/// Returns an [Item].
// rIndex is @ delimiterFvr
Item _readItem(EReader eReader, int count) {
  assert(_rb.hasRemaining(8));
  final iStart = _rb.rIndex;

  // read 32-bit kItem code and Item length field
  final delimiter = _rb.getUint32(_rb.rIndex);
  if (delimiter != kItem32BitLE) throw 'Missing Item Delimiter';
  _rb + 4;
  _inItem = true;
  final vfLengthField = _rb.uint32;
  log.debug('${_rb.rbb} Start Reading item #$count length: $vfLengthField', 1);

  final item = itemMaker(_cds);
  final parentDS = _cds;
  _cds = item;

  (vfLengthField == kUndefinedLength)
      ? _readDatasetUndefinedLength(item, eReader)
      : _readDatasetDefinedLength(item, _rb.rIndex, vfLengthField, eReader);

  _cds = parentDS;
  final bd = _rb.buffer.asByteData(iStart, _rb.rIndex - iStart);
  item.dsBytes = new IDSBytes(bd);
  _pInfo.nItems++;
  _inItem == false;
  log.debug('${_rb.ree} End Reading item #$count', -1);
  return item;
}

void _readDatasetDefinedLength(Dataset ds, int dsStart, int vfLength, EReader eReader) {
  assert(vfLength != kUndefinedLength);
  final dsEnd = dsStart + vfLength;
  log.debug2('${_rb.rbb} readDatasetDefined $dsStart - $dsEnd: $vfLength', 1);

  assert(dsStart == _rb.rIndex);
  while (_rb.rIndex < dsEnd) {
    eReader();
  }

  log.debug2('${_rb.ree} readDatasetDefined $_elementCount Elements read', -1);
  _pInfo.nDefinedLengthDatasets++;
}

void _readDatasetUndefinedLength(Dataset ds, EReader eReader) {
  log.debug2('${_rb.rbb} readEvrDatasetUndefined', 1);

  while (!__isItemDelimiter()) {
    eReader();
  }

  log.debug2('${_rb.ree} readDatasetUndefined $_elementCount Elements read', -1);
  _pInfo.nUndefinedLengthDatasets++;
}

/// If the item delimiter _kItemDelimitationItem32Bit_, reads and checks the
/// _delimiter length_ field, and returns _true_.
bool __isItemDelimiter() => _checkForDelimiter(kItemDelimitationItem32BitLE);

int _sqDepth = 0;
bool get _inSQ => _sqDepth <= 0;

/// Read a Sequence.
Element __readSQ(
    int code, int eStart, int vlf, EBMaker ebMaker, EReader eReader) {
	final eNumber = _elementCount;
	log.debug('${_rb.rbb} #$eNumber readSQ ${dcm(code)} @$eStart vfl:$vlf', 1);
  _sqDepth++;
  _pInfo.nSequences++;
  final e = (vlf == kUndefinedLength)
      ? __readUSQ(code, eStart, vlf, ebMaker, eReader)
      : __readDSQ(code, eStart, vlf, ebMaker, eReader);
  _sqDepth--;
  if (_sqDepth < 0) readError('_sqDepth($_sqDepth) < 0');
	log.debug('${_rb.ree} #$eNumber readSQ ${dcm(code)} $e', -1);
  return e;
}

/// Reads a [kUndefinedLength] Sequence.
Element __readUSQ(int code, int eStart, int uLength, EBMaker ebMaker, EReader eReader) {
  assert(uLength == kUndefinedLength);
  final items = <Item>[];
  _pInfo.nUndefinedLengthSequences++;

  // print('_element #$_elementCount');
  // print('offsets: ${_inputOffsets.length}');
  final offsetIndex = _inputOffsets.reserveSlot;
  log.debug('${_rb.rbb} readUSQ Reading ${items.length} Items', 1);
  var itemCount = 0;
  while (!__isSequenceDelimiter()) {
    final item = _readItem(eReader, itemCount);
    items.add(item);
    itemCount++;
  }
  log.debug('${_rb.ree} USQ Read $itemCount Items', -1);
  final e = _makeSequence(code, eStart, ebMaker, items);
  // print('*** insert at $offsetIndex $eStart ${e.eStart} ${e.eEnd}');
  _inputOffsets.insertAt(offsetIndex, e.eStart, e.eEnd, e);
  return e;
}

/// Reads a defined [vfLength].
Element __readDSQ(int code, int eStart, int vfLength, EBMaker ebMaker, EReader eReader) {
  assert(vfLength != kUndefinedLength);
  final items = <Item>[];
  _pInfo.nDefinedLengthSequences++;

  final vfStart = _rb.rIndex;
  // print('eStart: $eStart, vfStart: $vfStart, vfLength: $vfLength');
//  assert(eStart == _rb.rIndex - 12, '$eStart == ${_rb.rIndex - 12}');
  // print('_element #$_elementCount');
  // print('offsets: ${_inputOffsets.length}');
  final offsetIndex = _inputOffsets.reserveSlot;
  log.debug2('${_rb.rbb} readDSQ Reading ${items.length} Items', 1);
  final eEnd = vfStart + vfLength;
  var itemCount = 0;
  while (_rb.rIndex < eEnd) {
    final item = _readItem(eReader, itemCount);
    items.add(item);
    itemCount++;
  }
  final end = _rb.rIndex;
  assert(eEnd == end, '$eEnd == $end');
  log.debug2('${_rb.ree} DSQ Read $itemCount Items', -1);
  final e = _makeSequence(code, eStart, ebMaker, items);
  // print('insert at $offsetIndex');
  // print('*** insert at $offsetIndex $eStart ${_rb.rIndex} ${e.eStart} ${e.eEnd}');
  _inputOffsets.insertAt(offsetIndex, eStart, eEnd, e);
  return e;
}

// If VR is UN then this might be a Sequence
Element __tryReadUNSequence(
    int code, int eStart, int vlf, EBMaker ebMaker, EReader eReader) {
  log.debug3('${_rb.rmm} *** Maybe Reading Evr UN Sequence');
  final delimiter = _rb.getUint32(_rb.rIndex);
  if (delimiter == kSequenceDelimitationItem32BitLE) {
    // An empty Sequence
    _pInfo.nSequences++;
    _pInfo.nEmptyUNSequences++;
    log.debug3('${_rb.rmm} *** Empty Evr UN Sequence');
    _readAndCheckDelimiterLength();
    return _makeSequence(code, eStart, EvrLong.make, emptyItemList);
  } else if (delimiter == kItem) {
    // A non-empty Sequence
    log.debug3('${_rb.rmm} *** Found UN Sequence');
    _readAndCheckDelimiterLength();
    _pInfo.nSequences++;
    _pInfo.nNonEmptyUNSequences++;
    return __readSQ(code, eStart, vlf, EvrLong.make, _readEvrElement);
  }
  log.debug3('${_rb.rmm} *** UN Sequence not found');
  return null;
}

Element _makeSequence(int code, int eStart, EBMaker ebMaker, List<Item> items) {
  final eb = _makeEBytes(eStart, ebMaker);
  return sequenceMaker(eb, _cds, items);
}

/// If the sequence delimiter is found at the current _read index_, reads the
/// _delimiter_, reads and checks the _delimiter length_ field, and returns _true_.
bool __isSequenceDelimiter() => _checkForDelimiter(kSequenceDelimitationItem32BitLE);

/// Returns the Value Field Length (vfLength) of a non-Sequence Element.
/// The _read index_ is left at the end of the Element Delimiter.
//  The [_rIndex] should be at the beginning of the Value Field.
// Note: Since for binary DICOM the Value Field is 16-bit aligned,
// it must be checked 16 bits at a time.
int _findEndOfULengthVF() {
  while (_rb.isReadable) {
    if (uint16 != kDelimiterFirst16Bits) continue;
    if (uint16 != kSequenceDelimiterLast16Bits) continue;
    break;
  }
  _readAndCheckDelimiterLength();
  final endOfVF = _rb.rIndex - 8;
  return endOfVF;
}

/// Returns true if the [target] delimiter is found. If the target
/// delimiter is found the _read index_ is advanced to the end of the delimiter
/// field (8 bytes); otherwise, readIndex does not change.
bool _checkForDelimiter(int target) {
  final delimiter = _rb.uint32Peek;
  if (target == delimiter) {
    _rb + 4;
    _readAndCheckDelimiterLength();
    return true;
  }
  return false;
}

void _readAndCheckDelimiterLength() {
  final length = _rb.uint32;
  log.debug2('${_rb.rmm} ** Delimiter Length: $length');
  if (length != 0) {
    _pInfo.nonZeroDelimiterLengths++;
    _rb.warn('Encountered non-zero delimiter length($length) ${_rb.rrr}');
  }
}

/// Read an Element (not SQ)  with a 32-bit vfLengthField, that might have
/// kUndefinedValue.
Element __readMaybeUndefinedLength(int code, int eStart, int vrIndex, int vlf,
    EBytes ebMaker(ByteData bd), EReader eReader) {
	log.debug('${_rb.rbb} readMaybeUndefined ${dcm(code)} vr($vrIndex) '
			          '$eStart + 12 + ??? = ???', 1);
  // If VR is UN then this might be a Sequence
  if (vrIndex == kUNIndex) {
    final e = __tryReadUNSequence(code, eStart, vlf, ebMaker, eReader);
    if (e != null) return e;
  }
	_pInfo.nMaybeUndefinedElements++;
  return (vlf == kUndefinedLength)
      ? __readUndefinedLength(code, eStart, vrIndex, vlf, ebMaker)
      : __readLongDefinedLength(code, eStart, vrIndex, vlf, ebMaker);
}

// Finish reading an EVR Long Defined Length Element
Element __readLongDefinedLength(
    int code, int eStart, int vrIndex, int vlf, EBytes ebMaker(ByteData bd)) {
  assert(vlf != kUndefinedLength);

  log.debug('${_rb.rmm} readLongDefinedLength ${dcm(code)} vr($vrIndex) '
      '$eStart + 12 + $vlf = ${eStart + 12 + vlf}');
  _pInfo.nLongDefinedLengthElements++;
  _rb + vlf;
  return (code == kPixelData)
      ? _makePixelData(code, eStart, vrIndex, _rb.rIndex, false, ebMaker)
      : _makeElement(code, eStart, vrIndex, _rb.rIndex, ebMaker);
}

// Finish reading an EVR Long Undefined Length Element
Element __readUndefinedLength(
    int code, int eStart, int vrIndex, int vlf, EBytes ebMaker(ByteData bd)) {
  assert(vlf == kUndefinedLength);
  log.debug('${_rb.rmm} readEvrUndefinedLength ${dcm(code)} vr($vrIndex) '
      '$eStart + 12 + ??? = ???');
  _pInfo.nUndefinedLengthElements++;
  if (code == kPixelData) {
    return __readEncapsulatedPixelData(code, eStart, vrIndex, vlf, ebMaker);
  } else {
    final endOfVF = _findEndOfULengthVF();
    return _makeElement(code, eStart, vrIndex, endOfVF, ebMaker);
  }
}

/// There are only three VRs that use this: OB, OW, UN
// _rIndex is Just after vflengthField
Element __readEncapsulatedPixelData(
    int code, int eStart, int vrIndex, int vlf, EBytes ebMaker(ByteData bd)) {
  assert(vlf == kUndefinedLength);
  assert(_isMaybeUndefinedLengthVR(vrIndex));
  log.debug1('${_rb.rbb} readEncapsulatedPixelData', 1);

  final delimiter = _rb.getUint32(_rb.rIndex);
  if (delimiter == kItem32BitLE) {
    return __readPixelDataFragments(code, eStart, vlf, vrIndex, ebMaker);
  } else if (delimiter == kSequenceDelimitationItem32BitLE) {
    // An Empty Pixel Data Element
    _readAndCheckDelimiterLength();
    return _makePixelData(code, eStart, vrIndex, _rb.rIndex, true, ebMaker);
  } else {
    throw 'Non-Delimiter ${dcm(delimiter)}, $delimiter found';
  }
}

/// Reads an encapsulated (compressed) [kPixelData] [Element].
Element __readPixelDataFragments(
    int code, int eStart, int vfLengthField, int vrIndex, EBytes ebMaker(ByteData bd)) {
  log.debug2('${_rb.rmm} readPixelData Fragments', 1);
  assert(_isMaybeUndefinedLengthVR(vrIndex));
  __checkForOB(vrIndex, _rds.transferSyntax);

  final fragments = __readFragments();
  log.debug3('${_rb.ree}  read Fragments: $fragments', -1);
  return _makePixelData(code, eStart, vrIndex, _rb.rIndex, true, ebMaker, fragments);
}

void __checkForOB(int vrIndex, TransferSyntax ts) {
  if (vrIndex != kOBIndex && vrIndex != kUNIndex) {
    final vr = VR.lookupByIndex(vrIndex);
    _rb.warn('Invalid VR($vr) for Encapsulated TS: $ts ${_rb.rrr}');
    _pInfo.hadParsingErrors = true;
  }
}

/// Read Pixel Data Fragments.
/// They each start with an Item Delimiter followed by the 32-bit Item
/// length field, which may not have a value of kUndefinedValue.
VFFragments __readFragments() {
  final fragments = <Uint8List>[];
  var delimiter = _rb.uint32;
  do {
    assert(delimiter == kItem32BitLE, 'Invalid Item code: ${dcm(delimiter)}');
    final vlf = _rb.uint32;
    log.debug3('${_rb.rbb} readFragment ${dcm(delimiter)} length: $vlf', 1);
    assert(vlf != kUndefinedLength, 'Invalid length: ${dcm(vlf)}');

    final startOfVF = _rb.rIndex;
    final endOfVF = _rb + vlf;
    fragments.add(_rb.buffer.asUint8List(startOfVF, endOfVF - startOfVF));

    log.debug3('${_rb.ree}  length: ${endOfVF - startOfVF}', -1);
    delimiter = _rb.uint32;
  } while (delimiter != kSequenceDelimitationItem32BitLE);

  _checkDelimiterLength(delimiter);

  _pInfo.pixelDataHadFragments = true;
  final v = new VFFragments(fragments);
  return v;
}

void _checkDelimiterLength(int delimiter) {
  final vfLengthField = _rb.uint32;
  if (vfLengthField != 0)
    _rb.warn('Delimiter has non-zero '
        'value: $delimiter/0x${hex32(delimiter)} ${_rb.rrr}');
}

void _doEndOfElementStats(int code, int eStart, Element e, bool ok) {
  _pInfo.nElements++;
  if (ok) {
    _pInfo.lastElementRead = e;
    _pInfo.endOfLastElement = _rb.rIndex;
    if (e.isPrivate) _pInfo.nPrivateElements++;
    if (e is SQ) {
      _pInfo.endOfLastSequence = _rb.rIndex;
      _pInfo.lastSequenceRead = e;
    }
  } else {
    _pInfo.nDuplicateElements++;
  }
  if (e is! SQ && _elementOffsetsEnabled) _inputOffsets.add(eStart, _rb.rIndex, e);
}

// vfLength cannot be undefined.
Element _makeElement(
    int code, int eStart, int vrIndex, int endOfVF, EBytes ebMaker(ByteData bd)) {
  assert(endOfVF != kUndefinedLength);
  final eb = _makeEBytes(eStart, ebMaker);
  return elementMaker(eb, vrIndex);
}

PixelData _makePixelData(int code, int eStart, int vrIndex, int endOfVF, bool undefined,
    EBytes ebMaker(ByteData bd),
    [VFFragments fragments]) {
  _beyondPixelData = true;
  _maybeDoPixelDataStats(eStart, endOfVF, vrIndex, undefined);
  final eb = _makeEBytes(eStart, ebMaker);
  log.debug3('${_rb.ree} _makePixelData: $eb');
  _beyondPixelData = true;
  return pixelDataMaker(eb, vrIndex, _rds.transferSyntax, fragments);
}

EBytes _makeEBytes(int eStart, EBytes ebMaker(ByteData bd)) =>
    ebMaker(_rb.buffer.asByteData(eStart, _rb.rIndex - eStart));

void _maybeDoPixelDataStats(int eStart, int endOfVF, int vrIndex, bool undefined) {
  if (_statisticsEnabled) {
    final eLength = endOfVF - eStart;
    _pInfo.pixelDataStart = eStart;
    _pInfo.pixelDataLength = eLength;
    _pInfo.pixelDataHadUndefinedLength = undefined;
    _pInfo.pixelDataVR = VR.lookupByIndex(vrIndex);
  }
}

//TODO: check the performance cost of code checking
Tag __checkCode(int code, int eStart) {
  if (_checkCode) {
    if (code < 0x00020000 || code >= kItem) {
      if (_beyondPixelData) {
        log.warn('** Bad data beyond Pixel Data');
        if (throwOnError)
          return invalidTagError('code${dcm(code)} @${eStart - 4} +${_rb.remaining}');
      }
      log.error('Invalid Tag code: ${dcm(code)}');
      showReadIndex(_rb.rIndex - 6);
      throw 'bad code';
    }
    if (code <= 0) _zeroEncountered(code);
    // Check for Group Length Code
    final elt = code & 0xFFFF;
    if (code > 0x3000 && (elt == 0)) _pInfo.hadGroupLengths = true;
  }

  final tag = Tag.lookup(code);
  if (tag == null) {
    _rb.warn('Tag is Null: ${dcm(code)} start: $eStart ${_rb.rrr}');
    _showNext(_rb.rIndex - 4);
  }
  return tag;
}

int __vrToIndex(int code, VR vr) {
  var vrIndex = vr.index;
  if (_isSpecialVR(vrIndex)) {
	  log.info1('-- Changing Special VR ${VR.lookupByIndex(vrIndex)}) to VR.kUN');
    vrIndex = VR.kUN.index;
  }
  return vrIndex;
}

bool __isValidVR(int code, int vrIndex, Tag tag) {
  if (vrIndex == kUNIndex) {
    log.debug3('${_rb.rmm} VR ${VR.kUN} is valid for $tag');
    return true;
  }
  if (tag.hasNormalVR && vrIndex == tag.vrIndex) return true;
  if (tag.hasSpecialVR && tag.vr.isValidVRIndex(vrIndex)) {
    log.debug3('VR ${VR.lookupByIndex(vrIndex)} is valid for $tag');
    return true;
  }
  log.error('**** vrIndex $vrIndex is not valid for $tag');
  return false;
}

bool __isNotValidVR(int code, int vrIndex, Tag tag) => !__isValidVR(code, vrIndex, tag);

int __correctVR(int code, int vrIndex, Tag tag) {
  if (vrIndex == kUNIndex) {
    if (tag.vrIndex == kUNIndex) return vrIndex;
    return (tag.hasNormalVR) ? tag.vrIndex : vrIndex;
  }
  return vrIndex;
}

/// Returns true if there are only trailing zeros at the end of the
/// Object being parsed.
Null _zeroEncountered(int code) {
  final msg = (_beyondPixelData) ? 'after kPixelData' : 'before kPixelData';
  _rb.warn('Zero encountered $msg ${_rb.rrr}');
  throw new EndOfDataError('Zero encountered $msg ${_rb.rrr}');
}

String failedTSErrorMsg(String path, Error x) => '''
Invalid Transfer Syntax: "$path"\nException: $x\n ${_rb.rrr}
    File length: ${_rb.lengthInBytes}\n${_rb.rrr} readFMI catch: $x
''';

String failedFMIErrorMsg(String path, Object x) => '''
Failed to read FMI: "$path"\nException: $x\n'
	  File length: ${_rb.lengthInBytes}\n${_rb.rrr} readFMI catch: $x');
''';

// Issue:
// **** Below this level is all for debugging and can be commented out for
// **** production.

void _showNext(int start) {
  if (_isEvr) {
    _showShortEVR(start);
    _showLongEVR(start);
    _showIVR(start);
    _showShortEVR(start + 4);
    _showLongEVR(start + 4);
    _showIVR(start + 4);
  } else {
    _showIVR(start);
    _showIVR(start + 4);
  }
}

void _showShortEVR(int start) {
  if (_rb.hasRemaining(8)) {
    final code = _rb.getCode(start);
    final vrCode = _rb.getUint16(start + 4);
    final vr = VR.lookupByCode(vrCode);
    final vfLengthField = _rb.getUint16(start + 6);
    log.debug('${_rb.rmm} **** Short EVR: ${dcm(code)} $vr vfLengthField: '
        '$vfLengthField');
  }
}

void _showLongEVR(int start) {
  if (_rb.hasRemaining(8)) {
    final code = _rb.getCode(start);
    final vrCode = _rb.getUint16(start + 4);
    final vr = VR.lookupByCode(vrCode);
    final vfLengthField = _rb.getUint32(start + 8);
    log.debug('${_rb.rmm} **** Long EVR: ${dcm(code)} $vr vfLengthField: $vfLengthField');
  }
}

void _showIVR(int start) {
  if (_rb.hasRemaining(8)) {
    final code = _rb.getCode(start);
    final tag = Tag.lookupByCode(code);
    if (tag != null) log.debug(tag);
    final vfLengthField = _rb.getUint16(start + 4);
    log.debug('${_rb.rmm} **** IVR: ${dcm(code)} vfLengthField: $vfLengthField');
  }
}

String toVFLength(int vfl) => 'vfLengthField($vfl, ${hex32(vfl)})';
String toHadULength(int vfl) =>
    'HadULength(${(vfl == kUndefinedLength) ? 'true': 'false'})';

void showReadIndex([int index, int before = 20, int after = 28]) {
  index ??= _rb.rIndex;
  if (index.isOdd) {
    _rb.warn('**** Index($index) is not at even offset ADDING 1');
    index++;
  }

  for (var i = index - before; i < index; i += 2) {
    log.debug('$i:   ${hex16(_rb.getUint16 (i))} - ${_rb.getUint16 (i)}');
  }

  log.debug('** ${hex16(_rb.getUint16 (index))} - ${_rb.getUint16 (index)}');

  for (var i = index + 2; i < index + after; i += 2) {
    log.debug('$i: ${hex16(_rb.getUint16 (i))} - ${_rb.getUint16 (i)}');
  }
}

/*
//Enhancement:
void _printTrailingData(int start, int length) {
  for (var i = start; i < start + length; i += 4) {
    final x = _rb.getUint16(i);
    final y = _rb.getUint16(i + 2);
    final z = _rb.getUint32(i);
    final xx = hex8(x);
    final yy = hex16(y);
    final zz = hex32(z);
    // print('@$i: 16($x, $xx) | $y, $yy) 32($z, $zz)');
  }
}
*/