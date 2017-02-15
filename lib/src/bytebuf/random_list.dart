// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:math';
import 'dart:typed_data';

//TODO: there should be a better way to do this.
/// TODO: doc
class RandomList {
  static final _rng = new Random(1);
  final String name;
  final Type type;
  final int elementSizeInBytes;
  final num max;

  const RandomList(this.name, this.type, this.elementSizeInBytes, this.max);

  //TODO: add Type variable T
  static const RandomList int8 = const RandomList("Int8", Int8List, 1, (1 << 8));
  static const RandomList uint8 = const RandomList("Uint8", Uint8List, 1, (1 << 8));
  static const RandomList int16 = const RandomList("Int16", Int16List, 2, (1 << 16));
  static const RandomList uint16 = const RandomList("Uint16", Uint16List, 2, (1 << 16));
  static const RandomList int32 = const RandomList("Int32", Int32List, 4, (1 << 32));
  static const RandomList uint32 = const RandomList("Uint32", Uint32List, 4, (1 << 32));

  static const RandomList int64 = const RandomList("Int64", Int64List, 8, (1 << 32));
  static const RandomList uint64 = const RandomList("Uint64", Uint64List, 8, (1 << 32));
  static const RandomList float32 = const RandomList("Float32", Float32List, 4, null);
  static const RandomList float64 = const RandomList("Float64", Float64List, 4, null);

  List call(int length) {
    return _makeList(length);
  }

  List _makeList(int length) {
    List list;
    //log.debug('name: $name, type: $type, max: $max');
    //log.debug('length: $length');
    if (name == "Int8") {
      list = new Int8List(length);
      // log.debug('Int8List: $list');
    } else if (name == "Uint8") {
      list = new Uint8List(length);
    } else if (name == "Int16") {
      list = new Int16List(length);
    } else if (name == "Uint16") {
      list = new Uint16List(length);
    } else if (name == "Int32") {
      list = new Int32List(length);
    } else if (name == "Uint32") {
      list = new Uint32List(length);
    } else if (name == "Int64") {
      list = new Int64List(length);
      return _fill64List(list);
    } else if (name == "Uint64") {
      list = new Uint64List(length);
      return _fill64List(list);
    } else if (name == "Float32") {
      list = new Float32List(length);
      return _fillFloatList(list);
    } else if (name == "Float64") {
      list = new Float32List(length);
      return _fillFloatList(list);
    } else {
      throw "Invalid";
    }
    for (int i = 0; i < length; i++) {
      list[i] = _rng.nextInt(max);
    }
    return list;
  }

  List _fill64List(List list) {
    for (int i = 0; i < list.length; i++) {
      int sign = (i.isEven) ? -1 : 1;
      int n1 = _rng.nextInt(1 << 32);
      int n2 = _rng.nextInt(1 << 32);
      list[i] = sign * n1 * n2;
    }
    return list;
  }

  List _fillFloatList(List list) {
    for (int i = 0; i < list.length; i++) list[i] = _rng.nextDouble();
    return list;
  }
}
