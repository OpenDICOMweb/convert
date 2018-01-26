// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:convert/src/byte_list/byte_list.dart';
import 'package:convert/src/buffer/mixins/buffer_mixin.dart';

// ignore_for_file: non_constant_identifier_names,
// ignore_for_file: prefer_initializing_formals

abstract class BufferBase extends Object with BufferMixin {
  @override
  ByteListBase get bList;

  @override
  ByteData get bd => (isClosed) ? null : bList.bd;
  @override
  Uint8List get bytes => (isClosed) ? null : bList.bytes;

  bool _isClosed;
  bool get isClosed => (_isClosed == null) ? false : true;

  void get reset {
    rIndex_ = 0;
    wIndex_ = 0;
    _isClosed = false;
  }

}
