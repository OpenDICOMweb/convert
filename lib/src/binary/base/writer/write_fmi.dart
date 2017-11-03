// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

//TODO: move to common
const int kDcmPrefix = 0x4449434d;

/// Writes (encodes) only the FMI in the root [Dataset] in 'application/dicom'
/// media type, writes it to a Uint8List, and returns the [Uint8List].
Uint8List writeFmi({bool hadFmi}) {
  _writeFMI(hadFmi);
  final bytes = _blw.asUint8ListView;
  _writePath(bytes, _path);
  return bytes;
}

/// Writes File Meta Information (FMI) to the output.
/// _Note_: FMI is always Explicit Little Endian
bool _writeFMI(bool hadFmi) {
  //  if (encoding.doUpdateFMI) return writeODWFMI();
  if (_currentDS != _rootDS) log.error('Not _rootDS');

  // Check to see if we should write FMI if missing
  if (!hadFmi && !_eParams.allowMissingFMI) {
    log.error('Dataset $_rootDS is missing FMI elements');
    return false;
  } else if (_eParams.doUpdateFMI || (!hadFmi && _eParams.doAddMissingFMI)) {
    return writeOdwFMI();
  } else {
    assert(hadFmi);
    return _writeExistingFmi();
  }
  _isEVR = _rootDS.isEVR;
  return true;
}

void _writeExistingFMI() {
  _isEVR = true;
  _writeExistingPrefix();
  for (var e in _rootDS.elements) {
    if (e.code < 0x00030000) {
      _writeElement(e);
    } else {
      break;
    }
  }
}

//TODO: redoc
/// Writes a DICOM Preamble and Prefix (see PS3.10) as the
/// beginning of the encoding.
void _writeExistingPrefix() {
  final pInfo = _rootDS.parseInfo;
  assert(pInfo.hadPrefix == false || !_eParams.doAddMissingFMI);
  if (pInfo.preambleWasZeros || _eParams.doCleanPreamble) {
    for (var i = 0; i < 128; i++) _blw.bd.setUint8(i, 0);
  } else {
    assert(pInfo.preamble != null && !_eParams.doCleanPreamble);
    for (var i = 0; i < 128; i++) _blw.bd.setUint8(i, pInfo.preamble[i]);
  }
  _blw
    ..move(128)
    ..writeAsciiString('DICM');
}

bool _writeExistingFmi() {}

/// Writes a new Open DICOMweb FMI.
bool writeZeroPrefix() {
  //Urgent finish
  // Write Preamble
  for (var i = 0; i < 128; i += 8) _blw.writeUint64(0);
  // Write Prefix
  _blw.writeUint32(kDcmPrefix);
  return true;
}

bool writeOdwFMI() {}

void writePrivateInformation(Uid uid, ByteData privateInfo) {
  _blw.writeAsciiString(uid.asString);
}
