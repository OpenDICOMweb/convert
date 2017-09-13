// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

class JsonType {
  static const String baseType = 'application/';
  static const String jsonSubType = 'json';
  static const String dicomSubType = 'dicom+json';
  final String name;
  final String subtype;
  final String parameter;


    const JsonType(this.name, this.subtype, this.parameter);

  String get mediaType => '$baseType$subtype';

  String get contentType => '$mediaType; encoding=$parameter';

  static const basic = const JsonType("Basic", dicomSubType, 'basic');
  static const fast = const JsonType("Fase", dicomSubType, 'fast');
  static const pure = const JsonType("Pure", jsonSubType, 'pure');
}