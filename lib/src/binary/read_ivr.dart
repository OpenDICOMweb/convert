// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
part of odw.sdk.convert.binary;

  /// All [Element]s are read by this method.
  Element _readIvrElement() {
	  final eStart = _rIndex;
	  final code = _readCode();
    // No VR get Tag
    final tag = Tag.lookup(code);
    final vr = (tag == null) ? VR.kUN : tag.vr;
    final vrIndex = vr.index;

	  final e = (vrIndex == VR.kSQ.index || _isSequence(code, vrIndex))
	      ? _readIvrSequence(code, eStart)
	      : _readLongElement(code, eStart, vrIndex);
    assert(_checkRIndex());
    return _finishReadElement(code, eStart, e);
  }

SQ _readIvrSequence(int code, int eStart) => _readSequence(code, eStart, _ivrSQMaker);

EBytes _ivrSQMaker(ByteData bd) => new Ivr(bd);


