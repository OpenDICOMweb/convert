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

bool _isMaybeUndefinedLength(int vrIndex) =>
    vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax;

bool _isEvrLongVR(int vrIndex) =>
    vrIndex >= kVREvrLongIndexMin && vrIndex <= kVREvrLongIndexMax;

bool _isEvrShortVR(int vrIndex) =>
    vrIndex >= kVREvrShortIndexMin && vrIndex <= kVREvrShortIndexMax;

bool _isIvrDefinedLength(int vrIndex) =>
    vrIndex >= kVRIvrDefinedIndexMin && vrIndex <= kVRIvrDefinedIndexMax;

final String kItemAsString = hex32(kItem32BitLE);

/// Returns an [Item].
// rIndex is @ delimiter
Item _readItem(Element eReader()) {
  assert(_rb.hasRemaining(8));
  final iStart = _rb.rIndex;

  // read 32-bit kItem code and Item length field
  final delimiter = _rb.uint32;
  assert(delimiter == kItem32BitLE, 'Invalid Item code: ${dcm(delimiter)}');
  final vfLengthField = _rb.uint32;
  _rb.sMsg('readItem', kItem, iStart, -1, 8, delimiter);

  final item = itemMaker(_cds);
  final parentDS = _cds;
  _cds = item;

  (vfLengthField == kUndefinedLength)
      ? _readDatasetUndefined(item, eReader)
      : _readDatasetDefined(item, iStart, vfLengthField, eReader);

  _cds = parentDS;
  final bd = _rb.buffer.asByteData(iStart, _rb.rIndex - iStart);
  item.dsBytes = new IDSBytes(bd);
  _pInfo.nItems++;
  _rb.eMsg(_elementCount, item, iStart, _rb.rIndex);
  return item;
}

void _readDatasetDefined(Dataset ds, int dsStart, int vfLength, Element eReader()) {
  assert(vfLength != kUndefinedLength);
  final dsEnd = _rb.rIndex + vfLength;
  log.debug3('${_rb.rbb} readDatasetDefined $dsStart, $vfLength', 1);

  while (_rb.rIndex < dsEnd) {
    eReader();
  }

  log.debug3('${_rb.ree} $_elementCount Elements read', -1);
  _pInfo.nDefinedDatasets++;
}

void _readDatasetUndefined(Dataset ds, Element eReader()) {
  log.debug2('${_rb.rbb} _readEvrDatasetUndefined', 1);

  while (!_rb.isItemDelimiter()) {
    eReader();
  }

  log.debug2('${_rb.ree} $_elementCount Elements read', -1);
  _pInfo.nUndefinedDatasets++;
}

/// Reads a [kUndefinedLength] Sequence.
Element _readUSQ(
    int code, int eStart, EBytesMaker ebMaker, int vfLengthField, Element eReader()) {
  assert(vfLengthField == kUndefinedLength);
  final items = <Item>[];

  _rb.mMsg('readUSQ', code, eStart, 0);
  while (!_rb.isSequenceDelimiter()) {
    final item = _readItem(eReader);
    items.add(item);
  }

  _pInfo.nUndefinedSequences++;
  return _makeSequence(code, eStart, ebMaker, items);
}

bool _isUNSequence(int code, int eStart, int vrIndex) =>
    (vrIndex == kUNIndex && (_rb.isItemDelimiter() || _rb.isSequenceDelimiter()));

/// Reads a defined [vfLengthField].
Element _readDSQ(
    int code, int eStart, EBytesMaker ebMaker, int vfLengthField, Element eReader()) {
  assert(vfLengthField != kUndefinedLength);
  final items = <Item>[];
  final eEnd = _rb.rIndex + vfLengthField;

  _rb.mMsg('readDSQ', code, eStart, 0, vfLengthField);
  while (_rb.rIndex < eEnd) {
    final item = _readItem(eReader);
    items.add(item);
  }

  _pInfo.nDefinedSequences++;
  return _makeSequence(code, eStart, ebMaker, items);
}

/// There are only three VRs that use this: OB, OW, UN
// _rIndex is Just after vflengthField
Element _readPixelDataUndefined(
  int code,
  int eStart,
  int vrIndex,
  int vfLengthField,
  EBytes ebMaker(ByteData bd),
) {
  assert(vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax);
  log.debug2('${_rb.rbb} _readIvrPixelDataUndefined', 1);

  final delimiter = _rb.getUint32(_rb.rIndex);
  if (delimiter == kItem32BitLE) {
    return __readPixelDataFragments(code, eStart, vfLengthField, vrIndex, ebMaker);
  } else {
    final endOfVF = _rb.findEndOfULengthVF();
    return _makePixelData(code, eStart, vrIndex, endOfVF, true, ebMaker);
  }
}

/// Reads an encapsulated (compressed) [kPixelData] [Element].
Element __readPixelDataFragments(
    int code, int eStart, int vfLengthField, int vrIndex, EBytes ebMaker(ByteData bd)) {
  log.debug('${_rb.rmm} _readPixelData Fragments', 1);
  assert(vrIndex >= kVRMaybeUndefinedIndexMin && vrIndex <= kVRMaybeUndefinedIndexMax);
  __checkForOB(vrIndex, _rds.transferSyntax);

  final fragments = __readFragments();
  log.up2;
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
  var iCode = _rb.uint32;
  do {
    assert(iCode == kItem32BitLE, 'Invalid Item code: ${dcm(iCode)}');
    final vfLengthField = _rb.uint32;
    log.debug3('${_rb.rbb} _readFragment ${dcm(iCode)} length: $vfLengthField', 1);
    assert(vfLengthField != kUndefinedLength, 'Invalid length: ${dcm(vfLengthField)}');

    final startOfVF = _rb.rIndex;
    final endOfVF = _rb + vfLengthField;
    fragments.add(_rb.buffer.asUint8List(startOfVF, endOfVF - startOfVF));

    log.debug3('${_rb.ree}  length: ${endOfVF - startOfVF}', -1);
    iCode = _rb.uint32;
  } while (iCode != kSequenceDelimitationItem32BitLE);

  __checkItemLengthField(iCode);

  _pInfo.pixelDataHadFragments = true;
  final v = new VFFragments(fragments);
  log.debug3('${_rb.ree}  fragments: $v', -1);
  return v;
}

void __checkItemLengthField(int iCode) {
  final vfLengthField = _rb.uint32;
  if (vfLengthField != 0)
    _rb.warn('Pixel Data Sequence delimiter has non-zero '
        'value: $iCode/0x${hex32(iCode)} ${_rb.rrr}');
}

Element _finishReadElement(int code, int eStart, Element e) {
  assert(_rb.checkIndex());
  // Elements are always read into the current dataset.
  // **** This is the only place they are added to the dataset.
  final ok = _cds.tryAdd(e);
  if (!ok) log.debug('*** duplicate: $e');

  _elementCount++;
  if (_statisticsEnabled) {
    if (ok) {
      _pInfo.nElements++;
      _pInfo.lastElementRead = e;
      _pInfo.endOfLastElement = _rb.rIndex;
      if (e.isPrivate) _pInfo.nPrivateElements++;
      if (e is SQ) {
        _pInfo.nSequences++;
        _pInfo.endOfLastSequence = _rb.rIndex;
        _pInfo.lastSequenceRead = e;
      }
    } else {
      _pInfo.nDuplicateElements++;
    }
    if (_elementOffsetsEnabled) _inputOffsets.add(eStart, _rb.rIndex, e);
  }

/*  if (log.level == Level.debug3) {
    final msg = '''\n
     pInfo.elements: ${_pInfo.nElements}
rds.elements.length: ${_rds.elements.length}
cds.elements.length: ${_cds.elements.length}
 rds.elements.total: ${_rds.elements.total}
 cds.elements.total: ${_cds.elements.total}
''';
    log.debug(msg);
  }
  */
  _rb.eMsg(_elementCount, e, eStart, _rb.rIndex, -1);
//  print('Level: ${log.indenter.level}');
  return e;
}

Element _makeSequence(int code, int eStart, EBytesMaker ebMaker, List<Item> items) {
  final eb = _makeEBytes(eStart, ebMaker);
  return sequenceMaker(eb, _cds, items);
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

/*
  for(var i = eStart - 20; i <= eStart + 32; i += 2) {
  log.debug('$i ${hex16(_rb.getUint16 (i))} - ${_rb.getUint16 (i)}');
  }
*/

//Urgent Jim: make utility
/*  log
    ..debug('${dcm(_rb.getUint32(_rb.rIndex - 4))} - ${_rb.getUint32(_rb.rIndex - 4)}')
    ..debug('${dcm(_rb.getUint32(_rb.rIndex))} - ${_rb.getUint32(_rb.rIndex)}')
    ..debug('${dcm(_rb.getUint32(_rb.rIndex + 4))} - ${_rb.getUint32(_rb.rIndex + 4)}')
    ..debug('${dcm(_rb.getUint32(_rb.rIndex + 8))} - ${_rb.getUint32(_rb.rIndex + 8)}');
  */
/* Enhancement:
  void _printTrailingData(int start, int length) {
    for (var i= start; i < start + length; i += 4) {
      final x = _getUint16(i);
      final y = _getUint16(i + 2);
      final z = _getUint32(i);
      final xx = toHex8(x);
      final yy = toHex16(y);
      final zz = hex32(z);
      print('@$i: 16($x, $xx) | $y, $yy) 32($z, $zz)');
    }
  }
*/

/*  Enhancement: Flush if not needed
  bool _doLog = true;


  String get _XCode => '${dcm(_code)}';
  String get _XvrCode => 'vrCode(${toHex16(_vrCode)})';
  String get _XvfLengthField => 'vfLengthField(${hex32(_vfLengthField)})';


  _start(String name, [int code, int start]) {
    if (!_doLog) return;
    //  log.debug('$rbb $name${dcm(code)} $_evrString ', 1);
  }

  _end(String name, Element e, [String msg]) {
    if (!_doLog) return;
    //  log.debug('$ree $_nElementsRead: $e @end', -1);
  }
*/
