// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

class EndOfDataError extends Error {
  String method;
  String msg;

  EndOfDataError(this.method, [this.msg = '']);

  @override
  String toString() => 'EndOfDataException in $method: $msg';
}

class ShortFileError extends Error {
  String msg;

  ShortFileError([this.msg = '']);

  @override
  String toString() => 'ShortFileError in $msg';
}



