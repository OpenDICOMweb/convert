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
Element _readSequence(int code, int eStart, EBytesMaker maker) {
  final vfLengthField = _rb.uint32;
  final hdrlength = (_isEvr) ? 12 : 8;
  _rb.sMsg('readSequence', code, eStart, 0, hdrlength, vfLengthField);

  return (vfLengthField == kUndefinedLength)
      ? _readUSQ(code, eStart, maker, vfLengthField)
      : _readDSQ(code, eStart, maker, vfLengthField);
}

/// Reads a [kUndefinedLength] Sequence.
Element _readUSQ(int code, int eStart, EBytesMaker ebMaker, int vfLengthField) {
  assert(vfLengthField == kUndefinedLength);
  final items = <Item>[];

  _rb.mMsg('readUSQ', code, eStart, 0, vfLengthField);
  while (!_rb.isSequenceDelimiter()) {
    final item = _readItem();
    items.add(item);
  }

  _pInfo.nUndefinedSequences++;
  return _makeSequence(code, eStart, ebMaker, items);
}

/// Reads a defined [vfLengthField].
Element _readDSQ(int code, int eStart, EBytesMaker ebMaker, int vfLengthField) {
  assert(vfLengthField != kUndefinedLength);
  final items = <Item>[];
  final eEnd = _rb.rIndex + vfLengthField;

  _rb.mMsg('readDSQ', code, eStart, 0, vfLengthField);
  while (_rb.rIndex < eEnd) {
    final item = _readItem();
    items.add(item);
  }

  _pInfo.nDefinedSequences++;
  return _makeSequence(code, eStart, ebMaker, items);
}

Element _makeSequence(int code, int eStart, EBytesMaker ebMaker, List<Item> items) {
  final bd = _rb.buffer.asByteData(eStart, _rb.rIndex - eStart);
  final eb = ebMaker(bd);
  final e = sequenceMaker(eb, _cds, items);

  _pInfo.nSequences++;
  _pInfo.lastSequenceRead = e;
  _pInfo.endOfLastSequence = _rb.rIndex;
  if (e.isPrivate) _pInfo.nPrivateSequences++;
  return _finishReadElement(code, eStart, e);
}

final String kItemAsString = hex32(kItem32BitLE);

/// Returns an [Item].
// rIndex is @ delimiter
Item _readItem() {
  assert(_rb.hasRemaining(8));
  final iStart = _rb.rIndex;

  // read 32-bit kItem code and Item length field
  final delimiter = _rb.uint32;
  _rb.sMsg('readItem', kItem, iStart, null, 8, delimiter);

  //Urgent Jim: make utility
/*  log
    ..debug('${dcm(_rb.getUint32(_rb.rIndex - 4))} - ${_rb.getUint32(_rb.rIndex - 4)}')
    ..debug('${dcm(_rb.getUint32(_rb.rIndex))} - ${_rb.getUint32(_rb.rIndex)}')
    ..debug('${dcm(_rb.getUint32(_rb.rIndex + 4))} - ${_rb.getUint32(_rb.rIndex + 4)}')
    ..debug('${dcm(_rb.getUint32(_rb.rIndex + 8))} - ${_rb.getUint32(_rb.rIndex + 8)}');
  */
  assert(delimiter == kItem32BitLE, 'Invalid Item code: ${dcm(delimiter)}');

  final item = itemMaker(_cds);
  final parentDS = _cds;
  _cds = item;

  try {
    // Save parent [Dataset], and make [item] is new parent [Dataset].

    if (_isEvr) {
      _readEvrItem(item, iStart);
    } else {
      _readIvrItem(item, iStart);
    }
  } on EndOfDataError {
    log.error('${_rb.rrr} End of data Error', -1);
    _pInfo.hadParsingErrors = true;
    log.reset;
    rethrow;
  } catch (e) {
    log.error('${_rb.rrr} Error reading dataset: $_cds', -1);
    _pInfo.hadParsingErrors = true;
    _rb.error(e.toString());
    log.reset;
    rethrow;
  } finally {
    _cds = parentDS;
  }

  final bd = _rb.buffer.asByteData(iStart, _rb.rIndex - iStart);
  item.dsBytes = new IDSBytes(bd);
  _pInfo.nItems++;
  log.debug('${_rb.ree} $item');
  _rb.eMsg(_elementCount, item, iStart, _rb.rIndex);
  return item;
}
