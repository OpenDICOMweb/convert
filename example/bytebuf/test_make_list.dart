// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import '../../lib/bytebuf.dart';

void main() {

  print('int8List: ${RandomList.int8(8)}');
  print('uint8List: ${RandomList.uint8(8)}');
  print('int16List: ${RandomList.int16(8)}');
  print('uint16List: ${RandomList.uint16(8)}');
  print('int32List: ${RandomList.int32(8)}');
  print('uint32List: ${RandomList.uint32(8)}');
  print('int64List: ${RandomList.int64(8)}');
  print('uint64List: ${RandomList.uint64(8)}');
  print('floatList: ${RandomList.float32(8)}');
  print('floatList: ${RandomList.float64(8)}');
}