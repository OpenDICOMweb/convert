//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

class EndOfDataError extends Error {
  String method;
  String msg;

  EndOfDataError(this.method, [this.msg = '']);

  @override
  String toString() => '**** EndOfDataException in $method: $msg';
}

class ShortFileError extends Error {
  String msg;

  ShortFileError([this.msg = '']);

  @override
  String toString() => '**** ShortFileError: $msg';
}

class DataAfterPixelDataError extends Error {
  String msg;

  DataAfterPixelDataError([this.msg = '']);

  @override
  String toString() => '**** DataAfterPixelDataError: $msg';
}



