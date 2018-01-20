// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

abstract class ReaderLogMixin {
  int get rIndex;
  int get length;

  /// The current readIndex as a string.
  String get _rrr => 'R@${rIndex.toString().padLeft(5, '0')}';
  String get rrr => _rrr;

  /// The beginning of reading something.
  String get wbb => '> $_rrr';

  /// In the middle of reading something.
  String get wmm => '| $_rrr';

  /// The end of reading something.
  String get wee => '< $_rrr';

  String get pad => ''.padRight('$_rrr'.length);

  void warn(Object msg) => print('** Warning: $msg $_rrr');

  void error(Object msg) => throw new Exception('**** Error: $msg $_rrr');

}

/// Aids to pretty printing
abstract class WriterLogMixin {
  int get wIndex;

  /// The current readIndex as a string.
  String get _www => 'W@${wIndex.toString().padLeft(5, '0')}';
  String get www => _www;

  /// The beginning of reading something.
  String get wbb => '> $_www';

  /// In the middle of reading something.
  String get wmm => '| $_www';

  /// The end of reading something.
  String get wee => '< $_www';

  String get pad => ''.padRight('$_www'.length);

  void warn(Object msg) => print('** Warning: $msg $_www');

  void error(Object msg) => throw new Exception('**** Error: $msg $_www');

}