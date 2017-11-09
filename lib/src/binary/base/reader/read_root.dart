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
RootDataset _read(RootDataset rds, String path, DecodingParameters dParams) {
  final eStart = _rb.rIndex;
  log.debug('Reading RootDS: start: $eStart length: ${_rb.lengthInBytes}', 1);
  _cds = rds;

  log.reset;
  final hadFmi = _readFmi(rds, path, dParams);
  if (!hadFmi && !dParams.allowMissingFMI) return rds;

  try {
    if (_isEvr) {
      _readEvrRootDataset();
    } else {
      _readIvrRootDataset();
    }

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
  final pInfoTotal = _pInfo.nElements + _pInfo.nDuplicateElements;
  log.debug('''\n
lastReadIndex: ${_pInfo.lastReadIndex}
lengthInBytes: ${rds.dsBytes.bd.lengthInBytes}
    rds.total: ${rds.total}
  rds.dupotal: ${rds.dupTotal}
    nElements: ${_pInfo.nElements}
  nDuplicates: ${_pInfo.nDuplicateElements}
  
    rds total: $rdsTotal
 reader total: $pInfoTotal
''', -1);

  //TODO: fix this to include duplicates
  if (_pInfo.nElements != rds.total) readerInconsistencyError(rds);
  return rds;
}

class ReaderInconsistencyError extends Error {
  String msg;

  ReaderInconsistencyError(this.msg);

  @override
  String toString() => msg;
}

RootDataset readerInconsistencyError(RootDataset rds) {
  final rdsAll = rds.total + rds.dupTotal;
  final pInfoAll = _pInfo.nElements + _pInfo.nDuplicateElements;
  final msg = '''
Inconsistent Elements Error: '
   pInfo.total(${_pInfo.nElements})
   pInfo.duplicates(${_pInfo.nDuplicateElements})
   pInfo Total: $pInfoAll
   
   rds.total(${rds.total}) 
   rds.duplicates(${rds.dupTotal})  
   Total with duplciates: $rdsAll = ${rds.total} + ${rds.dupTotal}';
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
