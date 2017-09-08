// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:dcm_convert/src/bytebuf/bytebuf_reader.dart';
import 'package:system/server.dart';
import "package:test/test.dart";

import 'test_utilities.dart';

String magicAsString = "DICOM-MD";
Uint8List magic = magicAsString.codeUnits;

void main() {
  Server.initialize(name: 'bytebuf/byte_buf_reader_todo', level: Level.info0);
  test("Read MetadataFile Magic value", () {
    var s = "DICOM-MD";
    //List<int> cu = s.codeUnits;
    //log.debug('code units = $cu');
    Uint8List list = toUtf8(s);
    log.debug('utf8= $list');
    //var list = new Uint8List.fromList(cu);
    log.debug('list= $list');
    var reader = new ByteBufReader(list);
    log.debug('reader= $reader');
    String name = reader.readString(8);
    log.debug('name= "$name"');
    expect(name, equals("DICOM-MD"));
  });

  test("Read String", () {
    List<String> list = ["foo", "bar", "baz"];
    String strings = list.join("\\");
    ByteBufReader reader = new ByteBufReader.fromString(strings);
    String s = reader.readString(strings.length);
    expect(s, equals(strings));
  });

  test("Read String List", () {
    List<String> list = ["foo", "bar", "baz"];
    String strings = list.join("\\");
    ByteBufReader reader =  new ByteBufReader.fromString(strings);
    List l1 = reader.readStringList(strings.length);
    expect(l1, equals(list));
  });

  test("Read Uint8 Values", () {
    List<int> uints = [0, 1, 2, 3, 4];
    Uint8List uint8list = new Uint8List.fromList(uints);
    Uint8List bytes = uint8list.buffer.asUint8List();
    ByteBufReader reader = new ByteBufReader(bytes);
    int n = reader.readUint8();
    log.debug('Uint8 = $n');
    expect(n, equals(uints[0]));
    n = reader.readUint8();
    log.debug('Uint8 = $n');
    expect(n, equals(uints[1]));
    n = reader.readUint8();
    log.debug('Uint8 = $n');
    expect(n, equals(uints[2]));
    n = reader.readUint8();
    log.debug('Uint8 = $n');
    expect(n, equals(uints[3]));
  });

  test("Read Uint8List Values", () {
    List<int> uints = [0, 1, 2, 3, 4];
    Uint8List uint8list = new Uint8List.fromList(uints);
    Uint8List bytes = uint8list.buffer.asUint8List();
    ByteBufReader reader = new ByteBufReader(bytes);

    Uint8List list = reader.readUint8List(uint8list.lengthInBytes);
    log.debug('Uint8List = $list');
    expect(list, equals(uints));
  });

  test("Read Int8 Values", () {
    List<int> ints = [0, -1, 2, -3, 4];
    Int8List int8list = new Int8List.fromList(ints);
    Uint8List bytes = int8list.buffer.asUint8List();
    ByteBufReader reader = new ByteBufReader(bytes);

    int n = reader.readInt8();
    log.debug('Int8 = $n');
    expect(n, equals(ints[0]));
    n = reader.readInt8();
    log.debug('Int8 = $n');
    expect(n, equals(ints[1]));
    n = reader.readInt8();
    log.debug('Int8 = $n');
    expect(n, equals(ints[2]));
    n = reader.readInt8();
    log.debug('Int8 = $n');
    expect(n, equals(ints[3]));
  });

  test("Read Int8List Values", () {
    List<int> ints = [0, -1, 2, -3, 4];
    Int8List int8list = new Int8List.fromList(ints);
    Uint8List bytes = int8list.buffer.asUint8List();
    ByteBufReader buf = new ByteBufReader(bytes);

    Int8List list = buf.readInt8List(int8list.lengthInBytes);
    log.debug('Int8List = $list');
    expect(list, equals(ints));
  });

  test("Read Uint16 Values", () {
    List<int> uint16s = [257, 3401, 2000, 3000, 4000];
    Uint16List uint16list = new Uint16List.fromList(uint16s);
    Uint8List bytes = uint16list.buffer.asUint8List();
    log.debug('Uint16s: $uint16s');
    log.debug('Uint16list: $uint16list');
    log.debug('bytes: $bytes');
    ByteBufReader reader = new ByteBufReader(bytes);

    int n = reader.readUint16();
    log.debug('Uint16 = $n');
    expect(n, equals(uint16s[0]));

    n = reader.readUint16();
    log.debug('Uint16 = $n');
    expect(n, equals(uint16s[1]));

    n = reader.readUint16();
    log.debug('Uint16 = $n');
    expect(n, equals(uint16s[2]));

    n = reader.readUint16();
    log.debug('Uint16 = $n');
    expect(n, equals(uint16s[3]));
  });

  test("Read Uint16List Values", () {
    log.debug("*** Read Uint16List Values");
    List<int> uint16s = [257, 3401, 2000, 3000, 4000];
    Uint16List uint16list = new Uint16List.fromList(uint16s);
    Uint8List bytes = uint16list.buffer.asUint8List();
    log.debug('uint16s: $uint16s');
    log.debug('uint16list: $uint16list');
    log.debug('bytes: $bytes');
    ByteBufReader reader = new ByteBufReader(bytes);

    log.debug('Uint16List.lengthInBytes= ${uint16list.length}');
    Uint16List list = reader.readUint16List(uint16list.length);
    log.debug('readList = $list');
    expect(list, equals(uint16s));
  });

  test("Read Int16 Values", () {
    List<int> int16s = [-257, 3401, -2000, 3000, -4000];
    Int16List int16list = new Int16List.fromList(int16s);
    Uint8List bytes = int16list.buffer.asUint8List();
    log.debug('int16s: $int16s');
    log.debug('int16list: $int16list');
    log.debug('bytes: $bytes');
    ByteBufReader reader = new ByteBufReader(bytes);

    int n = reader.readInt16();
    log.debug('Int16 = $n');
    expect(n, equals(int16s[0]));

    n = reader.readInt16();
    log.debug('Int16 = $n');
    expect(n, equals(int16s[1]));

    n = reader.readInt16();
    log.debug('Int16 = $n');
    expect(n, equals(int16s[2]));

    n = reader.readInt16();
    log.debug('Int16 = $n');
    expect(n, equals(int16s[3]));
  });

  test("Read Int16List Values", () {
    log.debug("*** Read Int16List Values");
    List<int> int16s = [-257, 3401, -2000, 3000, -4000];
    Int16List int16list = new Int16List.fromList(int16s);
    Uint8List bytes = int16list.buffer.asUint8List();
    log.debug('int16s: $int16s');
    log.debug('int16list: $int16list');
    log.debug('bytes: $bytes');
    ByteBufReader buf = new ByteBufReader(bytes);

    log.debug('int16List.lengthInBytes= ${int16list.length}');
    Int16List list = buf.readInt16List(int16list.length);
    log.debug('Int16List = $list');
    expect(list, equals(int16s));
  });

  test("Read Uint32 Values", () {
    List<int> uint32s = [2570000, 34010000, 20000000, 30000000, 400000000];
    Uint32List uint32list = new Uint32List.fromList(uint32s);
    Uint8List bytes = uint32list.buffer.asUint8List();
    log.debug('Uint32s: $uint32s');
    log.debug('Uint32list: $uint32list');
    log.debug('bytes: $bytes');
    ByteBufReader buf = new ByteBufReader(bytes);

    int n = buf.readUint32();
    log.debug('Uint32 = $n');
    expect(n, equals(uint32s[0]));

    n = buf.readUint32();
    log.debug('Uint32 = $n');
    expect(n, equals(uint32s[1]));

    n = buf.readUint32();
    log.debug('Uint32 = $n');
    expect(n, equals(uint32s[2]));

    n = buf.readUint32();
    log.debug('Uint32 = $n');
    expect(n, equals(uint32s[3]));
  });

  test("Read Uint32List Values", () {
    log.debug("*** Read Uint32List Values");
    List<int> uint32s = [2570000, 34010000, 20000000, 30000000, 40000000];
    Uint32List uint32list = new Uint32List.fromList(uint32s);
    Uint8List bytes = uint32list.buffer.asUint8List();
    log.debug('int32s: $uint32s');
    log.debug('int32list: $uint32list');
    log.debug('bytes: $bytes');
    ByteBufReader buf = new ByteBufReader(bytes);

    log.debug('int32List.lengthInBytes= ${uint32list.length}');
    Uint32List list = buf.readUint32List(uint32list.length);
    log.debug('Uint32List = $list');
    expect(list, equals(uint32s));
  });

  test("Read Int32 Values", () {
    List<int> int32s = [-257000, 3401000, -2000000, 3000000, -4000000];
    Int32List int32list = new Int32List.fromList(int32s);
    Uint8List bytes = int32list.buffer.asUint8List();
    log.debug('int32s: $int32s');
    log.debug('int32list: $int32list');
    log.debug('bytes: $bytes');
    ByteBufReader buf = new ByteBufReader(bytes);

    int n = buf.readInt32();
    log.debug('Int32 = $n');
    expect(n, equals(int32s[0]));

    n = buf.readInt32();
    log.debug('Int32 = $n');
    expect(n, equals(int32s[1]));

    n = buf.readInt32();
    log.debug('Int32 = $n');
    expect(n, equals(int32s[2]));

    n = buf.readInt32();
    log.debug('Int32 = $n');
    expect(n, equals(int32s[3]));
  });

  test("Read Int32List Values", () {
    log.debug("*** Read Int32List Values");
    List<int> int32s = [-257000, 3401000, -2000000, 3000000, -4000000];
    Int32List int32list = new Int32List.fromList(int32s);
    Uint8List bytes = int32list.buffer.asUint8List();
    log.debug('int32s: $int32s');
    log.debug('int32list: $int32list');
    log.debug('bytes: $bytes');
    ByteBufReader buf = new ByteBufReader(bytes);

    log.debug('int32List.lengthInBytes= ${int32list.lengthInBytes}');
    Int32List list = buf.readInt32List(int32list.lengthInBytes);
    log.debug('int32List = $list');
    expect(list, equals(int32s));
  });

  test("Read Uint64 Values", () {
    List<int> uint64s = [
      25700000000,
      34010000000,
      200000000000,
      300000000000,
      4000000000000
    ];
    Uint64List uint64list = new Uint64List.fromList(uint64s);
    Uint8List bytes = uint64list.buffer.asUint8List();
    log.debug('Uint64s: $uint64s');
    log.debug('Uint64list: $uint64list');
    log.debug('bytes: $bytes');
    ByteBufReader buf = new ByteBufReader(bytes);

    int n = buf.readUint64();
    log.debug('Uint64 = $n');
    expect(n, equals(uint64s[0]));

    n = buf.readUint64();
    log.debug('Uint64 = $n');
    expect(n, equals(uint64s[1]));

    n = buf.readUint64();
    log.debug('Uint64 = $n');
    expect(n, equals(uint64s[2]));

    n = buf.readUint64();
    log.debug('Uint64 = $n');
    expect(n, equals(uint64s[3]));
  });

  test("Read Uint64List Values", () {
    log.debug("*** Read Int64List Values");
    List<int> uint64s = [
      25700000000,
      34010000000,
      200000000000,
      300000000000,
      4000000000000
    ];
    Uint64List uint64list = new Uint64List.fromList(uint64s);
    Uint8List bytes = uint64list.buffer.asUint8List();
    log.debug('int64s: $uint64s');
    log.debug('int64list: $uint64list');
    log.debug('bytes: $bytes');
    ByteBufReader buf = new ByteBufReader(bytes);

    log.debug('int64List.lengthInBytes= ${uint64list.lengthInBytes}');
    Uint64List list = buf.readUint64List(uint64list.lengthInBytes);
    log.debug('UInt64List = $list');
    expect(list, equals(uint64s));
  });

  test("Read Int64 Values", () {
    List<int> int64s = [
      -25700000000,
      34010000000,
      -200000000000,
      300000000000,
      -4000000000000
    ];
    Int64List int64list = new Int64List.fromList(int64s);
    Uint8List bytes = int64list.buffer.asUint8List();
    log.debug('int64s: $int64s');
    log.debug('int64list: $int64list');
    log.debug('bytes: $bytes');
    ByteBufReader buf = new ByteBufReader(bytes);

    int n = buf.readInt64();
    log.debug('Int64 = $n');
    expect(n, equals(int64s[0]));

    n = buf.readInt64();
    log.debug('Int64 = $n');
    expect(n, equals(int64s[1]));

    n = buf.readInt64();
    log.debug('Int64 = $n');
    expect(n, equals(int64s[2]));

    n = buf.readInt64();
    log.debug('Int64 = $n');
    expect(n, equals(int64s[3]));
  });

  test("Read Int64List Values", () {
    log.debug("*** Read Int64List Values");
    List<int> int64s = [
      -25700000000,
      34010000000,
      -200000000000,
      300000000000,
      -4000000000000
    ];
    Int64List int64list = new Int64List.fromList(int64s);
    Uint8List bytes = int64list.buffer.asUint8List();
    log.debug('int64s: $int64s');
    log.debug('int64list: $int64list');
    log.debug('bytes: $bytes');
    ByteBufReader buf = new ByteBufReader(bytes);

    log.debug('int64List.lengthInBytes= ${int64list.lengthInBytes}');
    Int64List list = buf.readInt64List(int64list.lengthInBytes);
    log.debug('int64List = $list');
    expect(list, equals(int64s));
  });

  test("Read Float32 Values", () {
    List<double> floats = [0.0, -1.1, 2.2, -3.3, 4.4];
    Float32List float32List = new Float32List.fromList(floats);
    Uint8List float8List = float32List.buffer.asUint8List();
    log.debug('float32List: $float32List');
    log.debug('float8List: $float8List');

    ByteBufReader buf = new ByteBufReader(float8List);
    double a = buf.readFloat32();
    log.debug('Float32 = $a');
    expect(a, equals(float32List[0]));
    a = buf.readFloat32();
    log.debug('Float32 = $a');
    expect(a, equals(float32List[1]));
    a = buf.readFloat32();
    log.debug('Float32 = $a');
    expect(a, equals(float32List[2]));
    a = buf.readFloat32();
    log.debug('Float32 = $a');
    expect(a, equals(float32List[3]));
  });

  test("Read Float32List Values", () {
    List<double> floats = [0.0, -1.1, 2.2, -3.3, 4.4];
    Float32List float32List = new Float32List.fromList(floats);
    Uint8List float8List = float32List.buffer.asUint8List();
    log.debug('float32List: $float32List');
    log.debug('float8List: $float8List');

    ByteBufReader buf = new ByteBufReader(float8List);
    Float32List list = buf.readFloat32List(float8List.lengthInBytes);
    log.debug('Float32List = $list');
    expect(list, equals(float32List));
  });

  test("Read Float64 Values", () {
    List<double> floats = [0.0, -1.1e10, 2.2e11, -3.3e12, 4.4e13];
    Float64List float64List = new Float64List.fromList(floats);
    Uint8List float8List = float64List.buffer.asUint8List();
    log.debug('float64List: $float64List');
    log.debug('float8List: $float8List');

    ByteBufReader buf = new ByteBufReader(float8List);
    double a = buf.readFloat64();
    log.debug('Float64 = $a');
    expect(a, equals(float64List[0]));
    a = buf.readFloat64();
    log.debug('Float64 = $a');
    expect(a, equals(float64List[1]));
    a = buf.readFloat64();
    log.debug('Float64 = $a');
    expect(a, equals(float64List[2]));
    a = buf.readFloat64();
    log.debug('Float64 = $a');
    expect(a, equals(float64List[3]));
  });

  test("Read Float64List Values", () {
    List<double> floats = [0.0, -1.1e10, 2.2e11, -3.3e12, 4.4e13];
    Float64List float64List = new Float64List.fromList(floats);
    Uint8List float8List = float64List.buffer.asUint8List();
    log.debug('float64List: $float64List');
    log.debug('float8List: $float8List');

    ByteBufReader buf = new ByteBufReader(float8List);
    Float64List list = buf.readFloat64List(float8List.lengthInBytes);
    log.debug('Float64List = $list');
    expect(list, equals(float64List));
  });
}
