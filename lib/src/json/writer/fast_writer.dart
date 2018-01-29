// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';

import 'package:core/core.dart';
import 'package:convert/src/json/writer/writer_mixin.dart';



class FastJsonWriter extends Object with FastJsonWriter {
  final StringBuffer sb;
  FastJsonWriter() : sb = new StringBuffer();




  static void _sqError(Element e, StringBuffer sb) =>
      invalidElementIndex(e.vrIndex);

  static void floatVF(Element e, StringBuffer sb) {
    assert(e is FloatBase);
    sb.write('${e.values}');
  }

  static void intVF(Element e, StringBuffer sb) {
    assert(e is IntBase);
    sb.write('${e.values}');
  }

  static void otherVF(Element e, StringBuffer sb) {
    assert(e is FloatBase);
    sb.write(BASE64.encode(e.vfBytes));
  }

  static void textVF(Element e, StringBuffer sb) {
    assert(e is Text);
    sb.write('["${e.values}"]');
  }

  static void stringVF(Element e, StringBuffer sb) {
    assert(e is StringBase);
    final v = e.values;
    final nList = new List<String>(v.length);
    for (var i = 0; i < v.length; i++)
      nList[i] = '"${v.elementAt(i)}"';
    sb.write('[${nList.join(', ')}]');
  }
}
