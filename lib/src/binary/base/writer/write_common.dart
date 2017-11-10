// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary.base.writer;

/*
void _writeSequence(Element e) {

}

void _writeSQ(SQ e) {
	_pInfo.nSequences++;
	if (e.isPrivate) _pInfo.nPrivateSequences++;
	return (e.hadULength && !_eParams.doConvertUndefinedLengths)
	       ? _writeIvrSQUndefined(e)
	       : _writeIvrSQDefined(e);
}
*/

void _writeItemUndefined(Item item) {
	_wb..uint32(kItem32BitLE)..uint32(kUndefinedLength);
	item.forEach(_writeEvrElement);
	_wb..uint32(kItemDelimitationItem)..uint32(0);
}

void _writeItemDefined(Item item) {
	_wb..uint32(kItem32BitLE)..uint32(item.lengthInBytes);
	item.forEach(_writeEvrElement);
}


