// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.


import 'dart:convert';

void main(List<String> args) {
	const token = 'DICM';
	final bytes = ascii.encode(token);
	final bd = bytes.buffer.asByteData();
	final v = bd.getUint32(0);
	final s = v.toRadixString(16).padLeft(8, '0');
	print('DICM: $v, 0x$s');
}