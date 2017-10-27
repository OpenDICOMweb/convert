// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary;

//TODO: redoc to reflect current state of code

/// If this is a Sequence, it is either empty, in which case the next
/// 32-bits will be a kSequenceDelimitationItem32Bit; or it is not
/// empty, in which case the next 32 bits will be an kItem32Bit value.
/// The [kPixelData] [Element] also has these characteristics,
/// and we return [false] if [code] is [kPixelData].
bool _isSequence(int code, int vrIndex) {
  if (vrIndex != VR.kUN.index || code == kPixelData) return false;
  final delimiter = _getUint32(_rIndex);
  return (delimiter == kItem32BitLE || delimiter == kSequenceDelimitationItem32BitLE)
      ? true
      : false;
}

// There are four [Element]s that might have an Undefined Length value
// (0xFFFFFFFF), [SQ], [OB], [OW], [UN]. If the length is the Undefined,
// then it searches for the matching [kSequenceDelimitationItem32Bit] to
// determine the length. Returns a [kUndefinedLength], which is used for
// reading the value field of these [Element]s. Returns an [SQ] [Element].

Element _readSequence(int code, int eStart, EBytesMaker maker) {
  final vfLengthField = _readUint32();
  return (vfLengthField == kUndefinedLength)
      ? _readUSQ(code, eStart, maker, vfLengthField)
      : _readDSQ(code, eStart, maker, vfLengthField);
}

/// Reads a [kUndefinedLength] Sequence.
Element _readUSQ(int code, int eStart, EBytesMaker ebMaker, int vfLengthField) {
  assert(vfLengthField == kUndefinedLength);
  //  log.debug('$rbb readUSQ: ${_startSQ(code, eStart, vfLengthField)}', 1);
  // FIX: give this a type when understood.
  final items = <Item>[];
  while (!_isSequenceDelimiter()) items.add(_readItem());
  return _makeSequence(code, eStart, ebMaker, items);
}

/// Reads a defined [vfLengthField].
Element _readDSQ(int code, int eStart, EBytesMaker ebMaker, int vfLengthField) {
  assert(vfLengthField != kUndefinedLength);
  //  log.debug('$rbb readDSQ: ${_startSQ(code, eStart, vfLengthField)}', 1);
  final items = <Item>[];
  final eEnd = _rIndex + vfLengthField;
  while (_rIndex < eEnd) {
    items.add(_readItem());
    _checkRIndex();
  }
  return _makeSequence(code, eStart, ebMaker, items);
}

Element _makeSequence(
  int code,
  int eStart,
  EBytesMaker ebMaker,
  List<Item> items,
) {
  //  log.debug1('$rmm   makeSQ: $eStart - $items', 1);
  // Keep, but only use for debugging.
  //_showNext(_rIndex);
  //  log.debug1('$rmm   eLength($eLength), makeSQ');
  final bd = _rootBD.buffer.asByteData(eStart, _rIndex - eStart);
  final eb = ebMaker(bd);
  final SQ sq = makeSequence(eb, _currentDS, items);
  _currentDS.elements.add(sq);
  if (Tag.isPrivateCode(code)) _nPrivateSequencesRead++;
  _nSequencesRead++;
  //  log.debug('$ree  ${show(sq)} ${items.length} items readDS@ @end', -1);
  return sq;
}

/// Returns [true] if the sequence delimiter is found at [_rIndex].
bool _isSequenceDelimiter() => _checkForDelimiter(kSequenceDelimitationItem32BitLE);

/// Returns [true] if the kItemDelimitationItem32Bit delimiter is found.
bool _checkForItemDelimiter() => _checkForDelimiter(kItemDelimitationItem32BitLE);

final String kItem = hex32(kItem32BitLE);

/// Returns an [Item] or Fragment.
Item _readItem() {
  assert(_hasRemaining(8));
  final Item item = makeItem(_currentDS);
  final itemStart = _rIndex;
  // read 32-bit kItem code
  final delimiter = _readUint32();
  assert(delimiter == kItem32BitLE, 'Invalid Item code: ${dcm(delimiter)}');
  final vfLengthField = _readUint32();

  // Save parent [Dataset], and make [item] is new parent [Dataset].
  final RootDataset parentDS = _currentDS;

  _elements = new MapAsList();

  int itemEnd;
  try {
    if (vfLengthField == kUndefinedLength) {
      //  log.debug2('$rmm   Undefined Item length');
      while (!_checkForItemDelimiter()) _readElement();
      itemEnd = _rIndex;
    } else {
      itemEnd = _rIndex + vfLengthField;
      //  log.debug2('$rmm   Fixed Item length: itemEnd($itemEnd)');
      while (_rIndex < itemEnd) {
        _lastElementRead = _readElement();
        _elements.add(_lastElementRead);
      }
    }
  } on EndOfDataError {
    //  log.debug('$ree   @end', -1);
    log.reset;
    rethrow;
  } catch (e) {
    _hadParsingErrors = true;
    _error(e);
    log.reset;
    rethrow;
  } finally {
    //  log.debug2('$rmm   item.length(${currentDS.length})');
    // Restore previous parent
    _currentDS = parentDS;
    //duplicates = currentDS.dupTotal;
    // Keep, but only use for debugging.
    //  _showNext(_rIndex);
  }

  final bd = _rootBD.buffer.asByteData(itemStart, itemEnd - itemStart);
  final dsBytes = new IDSBytes(bd);
  item.dsBytes = dsBytes;
  _nItemsRead++;
  //  log.debug('$ree   ${showItem(item)} @end', -1);
  _checkRIndex();
  return item;
}

/// Returns [true] if the [target] delimiter is found. If the target
/// delimiter is found [_rIndex] is advanced past the Value Length Field;
/// otherwise, readIndex does not change
bool _checkForDelimiter(int target) {
  final delimiter = _getUint32(_rIndex);
  if (delimiter == target) {
    _skip(4);
    final delimiterLength = _readUint32();
    if (delimiterLength != 0) {
      _delimiterLengthWarning(delimiterLength);
    }
    return true;
  }
  return false;
}

void _delimiterLengthWarning(int dLength) {
  _nonZeroDelimiterLengths++;
  _warn('Encountered non-zero delimiter length($dLength) $_rrr');
}

// **** Debugging utilities

/*
  String _startSQ(int code, int eStart, int vfLengthField) =>
      '${dcm(code)} eStart($eStart) vfLengthField ($vfLengthField, ${hex32(vfLengthField)})';
*/
