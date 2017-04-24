// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

class EndOfDataException implements Exception {
  String method;
  String msg;

  EndOfDataException(this.method, [this.msg = ""]);

  @override
  String toString() => 'EndOfDataException in $method: $msg';
}


