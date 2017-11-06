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
RootDataset _readRootDS(RootDataset rds, String path, DecodingParameters dParams) {
  final eStart = _rb.rIndex;
  log.debug('Reading RootDS: start: $eStart length: ${_rb.lengthInBytes}');
  _currentDS = rds;
  final hadFmi = _readFmi(rds, path, dParams);
  if (!hadFmi && !dParams.allowMissingFMI) return rds;

  // Set the Element reader based on the Transfer Syntax.
  _readElement = (rds.isEVR) ? _readEvrElement : _readIvrElement;

  int count;
  try {
    final rdsX = (_isEvr) ? _readEvrRootDataset() : _readIvrRootDataset();
  } on EndOfDataError catch (e) {
    addErrorInfo(e);
    log.error(e);
    if (throwOnError) rethrow;
  } on RangeError catch (e) {
    addErrorInfo(e);
    _rb.error('$e\n $_pInfo.stats');
    if (_beyondPixelData) log.info0('${_rb.rrr} Beyond Pixel Data');
    // Keep: *** Keep, but only use for debugging.
    if (throwOnError) rethrow;
  } catch (e) {
    addErrorInfo(e);
    _rb.error(e);
    rethrow;
  } finally {
    bdRead = _rb.close();
    rds.dsBytes = new RDSBytes(bdRead);
    _pInfo.lastReadIndex = _rb.rIndex;
  }

  final rdsTotal = rds.total + rds.dupTotal;
  log
    ..debug('lastReadIndex: ${_pInfo.lastReadIndex}')
    ..debug('nElements: ${rds.dsBytes.bd.lengthInBytes}')
    ..debug('rds.total: ${rds.total}')
    ..debug('rds.dupotal: ${rds.dupTotal}')
    ..debug('nElements: ${_pInfo.nElements}');

  if (_pInfo.nElements != rdsTotal) readerInconsistencyError(rds);
  return rds;
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
   ElementsRead(${_pInfo.nElements})
   rds.total(${rds.total}) 
   rds.duplicates(${rds.dupTotal})  
   Total with duplciates: $all = ${rds.total} + ${rds.dupTotal}';
''';
  _rb.error(msg);
// Urgent: fix
//  if (throwOnError) throw new ReaderInconsistencyError(msg);
  return rds;
}

void addErrorInfo(Object e) {
  _pInfo.exceptions.add(e);
  _pInfo.hadParsingErrors = true;
  _pInfo.lastReadIndex = _rb.rIndex;
}
