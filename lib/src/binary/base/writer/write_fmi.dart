// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

//TODO: move to common
const int kDcmPrefix = 0x4449434d;

bool _writeExistingFmi() {

}
/// Writes a new Open DICOMweb FMI.
bool writeZeroPrefix() {
	//Urgent finish
	// Write Preamble
	for (var i = 0; i < 128; i +=8) _writeUint64(0);
	// Write Prefix
	_writeUint32(kDcmPrefix);
	return true;
}

bool writeOdwFMI() {

}

void writePrivateInformation(Uid uid, ByteData privateInfo) {
	_writeAsciiString(uid.asString);

}