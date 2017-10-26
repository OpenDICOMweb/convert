// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary;

//TODO: redoc to reflect current state of code

/// Reads a Root [Dataset] from [this] and returns it.
/// If an error is encountered and [system].throwOnError is [true],
/// an Error will be thrown; otherwise, returns [null].
RootDataset _readRootDataset(String path, DecodingParameters dParam) {
  _currentDS = _rootDS;

   _hadFmi = _readFmi(path, dParam);
  if (!_hadFmi) return _rootDS;



  // Set the Element reader based on the Transfer Syntax.
  _readElement = (_isEVR) ? _readEvrElement : _readIvrElement;

  try {
    _currentDS = _rootDS;
    //  log.debug1('$rbb readDataset: isExplicitVR(${_isEVR})');
    while (_hasRemaining(8)) {
      _lastTopLevelElementRead = _readElement();
      //  log.debug1('$ree end readDataset: isExplicitVR(${_isEVR})');
      assert(identical(_currentDS, _rootDS));
    }
  } on EndOfDataError {
    log.info0('$_rrr EndOfDataError');
    _endOfDataError = true;
  } on ShortFileError {
    rethrow;
  } on RangeError catch (ex) {
    _error('$ex\n $stats');
    if (_beyondPixelData) log.info0('$_rrr Beyond Pixel Data');
    // Keep: *** Keep, but only use for debugging.
    if (throwOnError) rethrow;
  } catch (ex) {
    _error('$_rrr $ex\n $stats');
    // *** Keep, but only use for debugging.
    if (throwOnError) rethrow;
  } finally {
    bdRead = _rootBD.buffer.asByteData(0, _endOfLastValueRead);
    //      assert(_rIndex == _endOfLastValueRead,
    //          '_rIndex($_rIndex), _endOfLastValueRead($_endOfLastValueRead)');
    _bytesUnread = _rootBD.lengthInBytes - _rIndex;
    _hadTrailingBytes = _bytesUnread > 0;
    _hadTrailingZeros = _checkAllZeros(_endOfLastValueRead, _rootBD.lengthInBytes);
    _dsLengthInBytes = _endOfLastValueRead;
    assert(_dsLengthInBytes == bdRead.lengthInBytes);
  }

  //  log.debug1(stats);
  if (_rIndex != bdRead.lengthInBytes) {
    _warn('End of Data with _rIndex($_rIndex) != bdRead.length'
        '(${bdRead.lengthInBytes}) $_rrr');
    _dsLengthInBytes = _rIndex;
    _endOfLastValueRead = _rIndex;
    _hadTrailingBytes = (bdRead.lengthInBytes != _rootBD.lengthInBytes);
    if (_hadTrailingBytes)
      _hadTrailingZeros = _checkAllZeros(_rIndex, _rootBD.lengthInBytes);
  }

  final _rootDSTotal = _rootDS.total + _rootDS.dupTotal;
  if (_nElementsRead != _rootDSTotal) readerInconsistencyError(_rootDS);
  return _rootDS;
}

class ReaderInconsistencyError extends Error {
  String msg;

  ReaderInconsistencyError(this.msg);

  @override
  String toString() => msg;
}

RootDataset readerInconsistencyError(RootDataset rds) {
  final all = rds.total + rds.dupTotal;
  final msg = '''
Inconsistent Elements Error: '
   _nElementsRead($_nElementsRead)
   _rootDS.total(${rds.total}) 
   _rootDS.duplicates(${_rootDS.dupTotal})  
   Total with duplciates: $all = ${rds.total} + ${rds.dupTotal}';
''';
  _error(msg);
  if (throwOnError) throw new ReaderInconsistencyError(msg);
  return rds;
}
