// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.reader;

//TODO: redoc to reflect current state of code

/// Reads a Root [Dataset] and returns it.
/// If an error is encountered and [system].throwOnError is true,
/// an Error will be thrown; otherwise, returns null.
RootDataset _readRootDataset(String path, DecodingParameters dParam) {
  final eStart = _rIndex;
  log.debug('Reading RootDS: start: $eStart length: ${_rb.lengthInBytes}');
  try {
      _currentDS = _rootDS;
    _hadFmi = _readFmi(path, dParam);
    if (!_hadFmi && !dParam.allowMissingFMI) return _rootDS;

    // Set the Element reader based on the Transfer Syntax.
    _readElement = (_isEVR) ? _readEvrElement : _readIvrElement;

    //  log.debug1('$rbb readDataset: isExplicitVR(${_isEVR})');
    while (_hasRemaining(8)) {
     // log.debug('_rIndex: $_rIndex, eStart: $eStart');
      assert(_currentDS == _rootDS, '$_currentDS\n$_rootDS');
      _lastTopLevelElementRead = _readElement();
      //  log.debug1('$ree end readDataset: isExplicitVR(${_isEVR})');
      assert(identical(_currentDS, _rootDS));
    }
    //  log.debug('_rootDS: $_rootDS');
    //  log.debug('RootDS.TS: ${_rootDS.transferSyntax}');
    //  log.debug('elementList(${elementList.length})');
  } on ShortFileError catch (x) {
    _hadParsingErrors = true;
    _rootDS = null;
    _rb.error(failedFMIErrorMsg(path, x));
    if (throwOnError) rethrow;
  } on EndOfDataError catch (e) {
    _hadParsingErrors = true;
    _endOfDataError = true;
    log.error(e);
    if (throwOnError) rethrow;
  } on InvalidTransferSyntax catch (e) {
    _rb.warn(failedTSErrorMsg(path, e));
  } on RangeError catch (ex) {
    _rb.error('$ex\n $stats');
    if (_beyondPixelData) log.info0('${_rb.rrr} Beyond Pixel Data');
    // Keep: *** Keep, but only use for debugging.
    if (throwOnError) rethrow;
  } catch (x) {
    _rIndex = eStart;
    _hadParsingErrors = true;
    _rb.error(failedFMIErrorMsg(path, x));
    rethrow;
  } finally {
    bdRead = _rb.buffer.asByteData(0, _endOfLastValueRead);
    //      assert(_rIndex == _endOfLastValueRead,
    //          '_rIndex($_rIndex), _endOfLastValueRead($_endOfLastValueRead)');
    _bytesUnread = _rb.lengthInBytes - _rIndex;
    _hadTrailingBytes = _bytesUnread > 0;
    if (_hadTrailingBytes)
      _hadTrailingZeros = _rb.checkAllZeros(_endOfLastValueRead, _rb.lengthInBytes);
    _dsLengthInBytes = _endOfLastValueRead;
    log.debug('Trailing Bytes($_bytesUnread) All Zeros: $_hadTrailingZeros');
    assert(_dsLengthInBytes == bdRead.lengthInBytes);
  }

  //  log.debug1(stats);
  if (_rIndex != bdRead.lengthInBytes) {
    _rb.warn('End of Data with _rIndex($_rIndex) != bdRead.length'
        '(${bdRead.lengthInBytes}) ${_rb.rrr}');
    _dsLengthInBytes = _rIndex;
    _endOfLastValueRead = _rIndex;
    _hadTrailingBytes = (bdRead.lengthInBytes != _rb.lengthInBytes);
    if (_hadTrailingBytes)
      _hadTrailingZeros = _rb.checkAllZeros(_rIndex, _rb.lengthInBytes);
  }

  _rootDS.parseInfo = getParseInfo();
  final _rootDSTotal = _rootDS.total + _rootDS.dupTotal;
  //Urgent: fix
//  if (_nElementsRead != _rootDSTotal) readerInconsistencyError(_rootDS);
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
  _rb.error(msg);
  if (throwOnError) throw new ReaderInconsistencyError(msg);
  return rds;
}
