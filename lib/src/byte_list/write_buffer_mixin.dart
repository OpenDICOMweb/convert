// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

abstract class WriteBufferMixin {
  int _wIndex;
  ByteData get bd;

  // **** WriteBuffer specific Getters and Methods

  int get wIndex => _wIndex;
  set wIndex(int n) => _setWIndexTo(n);

  /// Moves the [wIndex] forward/backward. Returns the new [wIndex].
  int wSkip(int n) => _setWIndexTo(_wIndex + n);

  int _setWIndexTo(int wIndex) {
    if (wIndex < 0 || wIndex > bd.lengthInBytes)
      throw new RangeError.range(wIndex, 0, bd.lengthInBytes);
    return _wIndex = wIndex;
  }

  /// Returns the number of bytes left in the current buffer ([bd]).
  int get remaining => bd.lengthInBytes - _wIndex;

  bool hasRemaining(int n) => (_wIndex + n) <= bd.lengthInBytes;

  int get start => bd.offsetInBytes;
  int get end => bd.lengthInBytes;

  bool get isWritable => _isWritable;
  bool get _isWritable => _wIndex < bd.lengthInBytes;

  bool get isEmpty => _wIndex == start;

  bool get isNotEmpty => !isEmpty;

  int move(int n) {
    final v = _wIndex + n;
    if (v < 0 || v >= bd.lengthInBytes)
      throw new RangeError.range(v, 0, bd.lengthInBytes);
    return _wIndex = v;
  }

  bool _checkAllZeros(int start, int end) {
    for (var i = start; i < end; i++) if (bd.getUint8(i) != 0) return false;
    return true;
  }

  ByteData toByteData(int offset, int lengthInBytes) =>
      bd.buffer.asByteData(bd.offsetInBytes + offset, lengthInBytes);

  Uint8List toUint8List(int offset, int lengthInBytes) =>
      bd.buffer.asUint8List(bd.offsetInBytes + offset, lengthInBytes);

  // **** Aids to pretty printing - these may go away.

  /// The current readIndex as a string.
  String get _www => 'W@${_wIndex.toString().padLeft(5, '0')}';
  String get www => _www;

  /// The beginning of reading something.
  String get wbb => '> $_www';

  /// In the middle of reading something.
  String get wmm => '| $_www';

  /// The end of reading something.
  String get wee => '< $_www';

  String get pad => ''.padRight('$_www'.length);

  void error(Object msg) {
    final s = '**** $msg $_www';
    throw new Exception(s);
  }
}
