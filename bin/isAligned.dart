// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

void main(List<String> args) {

  final a = new ByteData(20);
  final b = a.buffer.asByteData(1);

  print('offset: ${a.offsetInBytes}, length: ${a.lengthInBytes}');
  print('offset: ${b.offsetInBytes}, length: ${b.lengthInBytes}');
  assert(_isAligned16(a, 4) == true);
  assert(_isAligned16(a, 3) == false);
  assert(_isAligned16(b, 4) == false);
  assert(_isAligned16(b, 3) == true);

  assert(_isAligned32(a, 4) == true);
  assert(_isAligned32(a, 3) == false);
  assert(_isAligned32(b, 4) == false);
  assert(_isAligned32(b, 3) == true);

  assert(_isAligned64(a, 8) == true);
  assert(_isAligned64(a, 3) == false);
  assert(_isAligned64(b, 8) == false);
  assert(_isAligned64(b, 7) == true);

}

bool _isAligned(ByteData bd, int offset, int size) =>
    ((bd.offsetInBytes + offset) % size) == 0;

bool _isAligned16(ByteData bd, int offset) => _isAligned(bd, offset, 2);
bool _isAligned32(ByteData bd,int offset) => _isAligned(bd, offset, 4);
bool _isAligned64(ByteData bd,int offset) => _isAligned(bd, offset, 8);
