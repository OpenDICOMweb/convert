// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';
import 'package:dictionary/dictionary.dart';

bool _throwOnError;

bool _notEqual(e0, e1) {
  print('e0: ${e0.info}');
  print('e0: ${e0.info}');
  return !_throwOnError ? false : throw 'ds0 != ds1';
}

/// Compare two [Dataset]s. Returns [true] if all [Element] are equal (==).
bool compareDatasets(Dataset ds0, Dataset ds1, [bool throwOnError = false]) {
  _throwOnError = throwOnError;
  if (ds0.length != ds1.length) return _notEqual(ds0, ds1);
  var iterator0 = ds0.elements.iterator;
  var iterator1 = ds1.elements.iterator;
  while (true) {
    iterator0.moveNext();
    iterator1.moveNext();
    var e0 = iterator0.current;
    var e1 = iterator1.current;
    if (e0 == null && e1 == null) return true;
    if (e0.vrCode == VR.kSQ.code) {
      if (!_compareSequences(e0, e1)) return _notEqual(e0, e1);
    } else {
      if (!_compareElement(e0, e1, throwOnError)) return _notEqual(e0, e1);
    }
  }
}

bool _compareSequences(Sequence s0, Sequence s1, [bool throwOnError = false]) {
  if (s1.vrCode != VR.kSQ.code) return _notEqual(s0, s1);
  if (s0.code != s1.code ||
      s0.vrCode != s1.vrCode ||
      s0.values.length != s1.values.length) return _notEqual(s0, s1);
  for (int i = 0; i < s0.values.length; i++) {
    Item item0 = s0[i];
    Item item1 = s1[i];
    if (!compareDatasets(item0, item1)) _notEqual(s0, s1);
  }
  return true;
}

/// Compare simple [Element]s.
bool _compareElement(Element e0, Element e1, [bool throwOnError = false]) {
  if (e0.code != e1.code ||
      e0.vrCode != e1.vrCode ||
      e0.vfLength != e1.vfLength ||
      e0.vfBytes.length != e1.vfBytes.length) {
    return _notEqual(e0, e1);
  }
  var v0 = e0.values;
  var v1 = e1.values;
  if (v0.length != v1.length) return _notEqual(e0, e1);
  for (int i = 0; i < v0.length; i++) if (v0[i] != v1[i]) return _notEqual(e0, e1);
  return true;
}
