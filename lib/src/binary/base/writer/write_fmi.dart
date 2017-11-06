// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

/// Writes File Meta Information (FMI) to the output.
/// _Note_: FMI is always Explicit Little Endian
bool _writeFmi(RootDataset rootDS, EncodingParameters eParams) {
  //  if (encoding.doUpdateFMI) return writeODWFMI();
  if (rootDS is! RootDataset) log.error('Not _rootDS');
  if (!rootDS.hasFmi) {
  	final pInfo = rootDS.parseInfo;
    assert(pInfo.hadPrefix == false || !_eParams.doAddMissingFMI);
    log.warn('Root Dataset does not have FMI: $_rds');
    if (!_eParams.allowMissingFMI || !_eParams.doAddMissingFMI) {
      log.error('Dataset $_rds is missing FMI elements');
      return false;
    }
    if (eParams.doUpdateFMI) return writeOdwFMI(rootDS);
  }
  assert(rootDS.hasFmi);
  _writeExistingFmi(rootDS, _eParams.doCleanPreamble);
  _isEvr = _rds.isEvr;
  return true;
}

bool writeOdwFMI(RootDataset rootDS) {
  if (rootDS is! RootDataset) log.error('Not _rds');
  //Urgent finish
  _writeCleanPrefix();
  return true;
}

void _writeExistingFmi(RootDataset rootDS, bool cleanPreamble) {
  _isEvr = true;
  _writePrefix(rootDS, cleanPreamble);
  for (var e in rootDS.elements) {
    if (e.code > 0x00030000) break;
    _writeEvr(e);
  }
}

//TODO: redoc
/// Writes a DICOM Preamble and Prefix (see PS3.10) as the
/// beginning of the encoding.
bool _writePrefix(RootDataset rootDS, bool cleanPreamble) {
  if (rootDS is! RootDataset) log.error('Not _rds');
  final pInfo = rootDS.parseInfo;
  return (pInfo.preambleWasZeros || _eParams.doCleanPreamble)
      ? _writeCleanPrefix()
      : _writeExistingPrefix(pInfo);
}

/// Writes a new Open DICOMweb FMI.
bool _writeCleanPrefix() {
  for (var i = 0; i < 128; i += 8) _wb.uint64(0);
  _wb.uint32(kDcmPrefix);
  return true;
}

/// Writes a new Open DICOMweb FMI.
bool _writeExistingPrefix(ParseInfo pInfo) {
  assert(pInfo.preamble != null && !_eParams.doCleanPreamble);
  for (var i = 0; i < 128; i++) _wb.bd.setUint8(i, pInfo.preamble[i]);
  _wb.uint32(kDcmPrefix);
  return true;
}

void writePrivateInformation(Uid uid, ByteData privateInfo) {
  _wb.ascii(uid.asString);
}
