// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:core/core.dart';



/// DICOM+JSON media type decoder.
class JsonDecoder extends Converter<Uint8List, Entity> {
  Uint8List bytes;

  JsonDecoder(this.bytes);

  Entity get entity => convert(bytes);

  Map get json => JSON.decode(UTF8.decode(bytes));

  @override
  Entity convert(Uint8List bytes) {
    String s = UTF8.decode(bytes);
    return JSON.decode(s);
  }

  static Entity decode(Uint8List bytes) {
    JsonDecoder decoder = new JsonDecoder(bytes);
    return decoder.entity;
  }
}