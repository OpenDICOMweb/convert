// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import "package:test/test.dart";

import '../../lib/src/bytebuf/bytebuf.dart';
import 'package:system/server.dart';
import 'test_utilities.dart';

String magicAsString = "DICOM-MD";
Uint8List magic = magicAsString.codeUnits;

void main() {
  Server.initialize(name: 'bytebuf/bytebuf_test', level: Level.info0);
  test("Read MetadataFile Magic value", () {
    var s = "DICOM-MD";
    Uint8List list = toUtf8(s);

    var buf = new ByteBuf.fromList(list);
    String name = buf.readString(8);
    expect(name, equals("DICOM-MD"));
  });

  test("Create ByteBuf Read String", () {
    List<String> listIn = ["foo", "bar", "baz"];
    String strings = listIn.join("\\");
    ByteBuf buf = byteBufFromString(strings);

    String s = buf.readString(strings.length);
    expect(s, equals(strings));

    var listOut = s.split(r'\');
    expect(listOut, listIn);
  });

  test("Write then Read String", () {
    List<String> listIn = ["foo", "bar", "baz"];
    String sIn = listIn.join("\\");
    ByteBuf buf = new ByteBuf();

    buf.writeString(sIn);
    String sOut = buf.readString(sIn.length);
    expect(sOut, equals(sIn));

    var listOut = sIn.split(r'\');
    expect(listOut, equals(listIn));
  });

  test("Write then Read String List", () {
    List<String> listIn = ["foo", "bar", "baz"];
    var s = listIn.join(r'\');
    ByteBuf buf = new ByteBuf();

    buf.writeStringList(listIn);
    List<String> listOut = buf.readStringList(s.length);
    expect(listOut, equals(listIn));
  });

  test("Read String List", () {
    List<String> list = ["foo", "bar", "baz"];
    String strings = list.join("\\");
    ByteBuf buf = byteBufFromString(strings);
    List<String> l1 = buf.readStringList(strings.length);
    expect(l1, equals(list));
  });

  test("Read Int8 Values", () {
    List<int> ints = [0, -1, 2, -3, 4];
    Int8List int8list = new Int8List.fromList(ints);
    Uint8List bytes = int8list.buffer.asUint8List();
    ByteBuf reader = new ByteBuf.reader(bytes);

    int n = reader.readInt8();
    expect(n, equals(ints[0]));
    n = reader.readInt8();
    expect(n, equals(ints[1]));
    n = reader.readInt8();
    expect(n, equals(ints[2]));
    n = reader.readInt8();
    expect(n, equals(ints[3]));
  });

  test("Read Int8List Values", () {
    List<int> ints = [0, -1, 2, -3, 4];
    Int8List int8list = new Int8List.fromList(ints);
    Uint8List bytes = int8list.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(bytes);

    List<int> list = buf.readInt8List(int8list.lengthInBytes);
    expect(list, equals(ints));

    buf = new ByteBuf();
    buf.writeInt8List(ints);
    list = buf.readInt8List(ints.length);
    expect(list, equals(ints));
  });

  test("Read Uint8 Values", () {
    List<int> uints = <int>[0, 1, 2, 3, 4];
    Uint8List uint8list = new Uint8List.fromList(uints);
    Uint8List bytes = uint8list.buffer.asUint8List();
    var s = "aaaaaaa aaaaaaa aaaaaaa aaaaaaaab";
    ByteBuf buf = new ByteBuf();

    buf.writeString(s);
    buf.writeUint8List(bytes);
    var t = buf.readString(s.length);
    expect(t, equals(s));

    int n = buf.readUint8();
    expect(n, equals(uints[0]));
    n = buf.readUint8();
    expect(n, equals(uints[1]));
    n = buf.readUint8();
    expect(n, equals(uints[2]));
    n = buf.readUint8();
    expect(n, equals(uints[3]));
  });

  test("Read Uint8List Values", () {
    List<int> uints = [0, 1, 2, 3, 4];
    Uint8List uint8List = new Uint8List.fromList(uints);
    Uint8List bytes = uint8List.buffer.asUint8List();
    var s = "01234567";
    ByteBuf buf = new ByteBuf();

    buf.writeString(s);
    buf.writeUint8List(bytes);
    var t = buf.readString(s.length);
    expect(t, equals(s));

    List<int> list = buf.readUint8List(bytes.lengthInBytes);
    expect(list, equals(uints));

    s = "aaaaaaaab";
    buf = new ByteBuf();
    buf.writeString(s);
    buf.writeUint8List(bytes);

    t = buf.readString(s.length);
    expect(t, equals(s));

    list = buf.readUint8List(uint8List.lengthInBytes);
    expect(list, equals(uints));

    buf = new ByteBuf();
    buf.writeUint8List(uint8List);
    list = buf.readUint8List(uints.length);
    expect(list, equals(uints));
  });

  test("Read Int16 Values", () {
    List<int> int16s = [-257, 3401, -2000, 3000, -4000];
    Int16List int16list = new Int16List.fromList(int16s);
    Uint8List bytes = int16list.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(bytes);

    int n = buf.readInt16();
    expect(n, equals(int16s[0]));
    n = buf.readInt16();
    expect(n, equals(int16s[1]));
    n = buf.readInt16();
    expect(n, equals(int16s[2]));
    n = buf.readInt16();
    expect(n, equals(int16s[3]));
  });

  test("Read Int16List Values", () {
    List<int> int16s = [-257, 3401, -2000, 3000, -4000];
    Int16List int16list = new Int16List.fromList(int16s);
    Uint8List bytes = int16list.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(bytes);

    List<int> list = buf.readInt16List(int16list.length);
    expect(list, equals(int16s));

    buf = new ByteBuf();
    buf.writeInt16List(int16s);
    list = buf.readInt16List(int16s.length);
    expect(list, equals(int16s));
  });

  test("Read Uint16 Values", () {
    List<int> uint16s = [257, 3401, 2000, 3000, 4000];
    Uint16List uint16list = new Uint16List.fromList(uint16s);
    Uint8List bytes = uint16list.buffer.asUint8List();
    ByteBuf reader = new ByteBuf.reader(bytes);

    int n = reader.readUint16();
    expect(n, equals(uint16s[0]));
    n = reader.readUint16();
    expect(n, equals(uint16s[1]));
    n = reader.readUint16();
    expect(n, equals(uint16s[2]));
    n = reader.readUint16();
    expect(n, equals(uint16s[3]));
  });

  test("Read Uint16List Values", () {
    List<int> uint16s = <int>[257, 3401, 2000, 3000, 4000];
    //  log.debug('length0:${uint16s.length}: $uint16s');
    Uint16List uint16List = new Uint16List.fromList(uint16s);
    //  log.debug('length1:${uint16List.length}: $uint16List');
    Uint8List bytes = uint16List.buffer.asUint8List();
    //  log.debug('length2:${bytes.length}: $bytes');
    ByteBuf buf = new ByteBuf.reader(bytes);

    //  log.debug(buf.info);
    List<int> list = buf.readUint16List(uint16List.length);

    expect(uint16s, equals(uint16s));

    buf = new ByteBuf();
    buf.writeUint16List(uint16List);
    list = buf.readUint16List(uint16s.length);
    expect(list, equals(uint16s));
  });

  test("Read Int32 Values", () {
    List<int> int32s = [-257000, 3401000, -2000000, 3000000, -4000000];
    Int32List int32list = new Int32List.fromList(int32s);
    Uint8List bytes = int32list.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(bytes);

    int n = buf.readInt32();
    expect(n, equals(int32s[0]));
    n = buf.readInt32();
    expect(n, equals(int32s[1]));
    n = buf.readInt32();
    expect(n, equals(int32s[2]));
    n = buf.readInt32();
    expect(n, equals(int32s[3]));
  });

  test("Read Int32List Values", () {
    List<int> int32s = [-257000, 3401000, -2000000, 3000000, -4000000];
    Int32List int32List = new Int32List.fromList(int32s);
    Uint8List bytes = int32List.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(bytes);

    List<int> list = buf.readInt32List(int32List.length);
    expect(list, equals(int32s));

    buf = new ByteBuf();
    buf.writeInt32List(int32List);
    list = buf.readInt32List(int32s.length);
    expect(list, equals(int32s));
  });

  test("Read Uint32 Values", () {
    List<int> uint32s = [2570000, 34010000, 20000000, 30000000, 400000000];
    Uint32List uint32list = new Uint32List.fromList(uint32s);
    Uint8List bytes = uint32list.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(bytes);

    int n = buf.readUint32();
    expect(n, equals(uint32s[0]));
    n = buf.readUint32();
    expect(n, equals(uint32s[1]));
    n = buf.readUint32();
    expect(n, equals(uint32s[2]));
    n = buf.readUint32();
    expect(n, equals(uint32s[3]));
  });

  test("Read Uint32List Values", () {
    List<int> uint32s = [2570000, 34010000, 20000000, 30000000, 40000000];
    Uint32List uint32list = new Uint32List.fromList(uint32s);
    Uint8List bytes = uint32list.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(bytes);

    List<int> list = buf.readUint32List(uint32list.length);
    expect(list, equals(uint32s));

    buf = new ByteBuf();
    buf.writeUint32List(uint32s);
    list = buf.readUint32List(uint32s.length);
    expect(list, equals(uint32s));
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
    ByteBuf buf = new ByteBuf.reader(bytes);

    int n = buf.readInt64();
    expect(n, equals(int64s[0]));
    n = buf.readInt64();
    expect(n, equals(int64s[1]));
    n = buf.readInt64();
    expect(n, equals(int64s[2]));
    n = buf.readInt64();
    expect(n, equals(int64s[3]));
  });

  test("Read Int64List Values", () {
    List<int> int64s = [
      -25700000000,
      34010000000,
      -200000000000,
      300000000000,
      -4000000000000
    ];
    Int64List int64list = new Int64List.fromList(int64s);
    Uint8List bytes = int64list.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(bytes);

    List<int> list = buf.readInt64List(int64list.length);
    expect(list, equals(int64s));

    buf = new ByteBuf();
    buf.writeInt64List(int64s);
    list = buf.readInt64List(int64s.length);
    expect(list, equals(int64s));
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
    ByteBuf buf = new ByteBuf.reader(bytes);

    int n = buf.readUint64();
    expect(n, equals(uint64s[0]));
    n = buf.readUint64();
    expect(n, equals(uint64s[1]));
    n = buf.readUint64();
    expect(n, equals(uint64s[2]));
    n = buf.readUint64();
    expect(n, equals(uint64s[3]));
  });

  test("Read Uint64List Values", () {
    List<int> uint64s = [
      25700000000,
      34010000000,
      200000000000,
      300000000000,
      4000000000000
    ];
    Uint64List uint64list = new Uint64List.fromList(uint64s);
    Uint8List bytes = uint64list.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(bytes);

    List<int> list = buf.readUint64List(uint64list.length);
    expect(list, equals(uint64s));

    buf = new ByteBuf();
    buf.writeUint64List(uint64s);
    list = buf.readUint64List(uint64s.length);
    expect(list, equals(uint64s));
  });

  test("Read Float32 Values", () {
    List<double> floats = [0.0, -1.1, 2.2, -3.3, 4.4];
    Float32List float32List = new Float32List.fromList(floats);
    Uint8List float8List = float32List.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(float8List);

    double a = buf.readFloat32();
    expect(a, equals(float32List[0]));
    a = buf.readFloat32();
    expect(a, equals(float32List[1]));
    a = buf.readFloat32();
    expect(a, equals(float32List[2]));
    a = buf.readFloat32();
    expect(a, equals(float32List[3]));
  });

  test("Read Float32List Values", () {
    List<double> floats = [0.0, -1.1, 2.2, -3.3, 4.4];
    Float32List float32List = new Float32List.fromList(floats);
    Uint8List float8List = float32List.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(float8List);

    List<double> list = buf.readFloat32List(float32List.length);
    expect(list, equals(float32List));

    buf = new ByteBuf();
    buf.writeFloat32List(float32List);
    list = buf.readFloat32List(floats.length);
    expect(list, equals(float32List));
  });

  test("Read Float64 Values", () {
    List<double> floats = [0.0, -1.1e10, 2.2e11, -3.3e12, 4.4e13];
    Float64List float64List = new Float64List.fromList(floats);
    Uint8List float8List = float64List.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(float8List);

    double a = buf.readFloat64();
    expect(a, equals(float64List[0]));
    a = buf.readFloat64();
    expect(a, equals(float64List[1]));
    a = buf.readFloat64();
    expect(a, equals(float64List[2]));
    a = buf.readFloat64();
    expect(a, equals(float64List[3]));
  });

  test("Read Float64List Values", () {
    List<double> floats = [0.0, -1.1e10, 2.2e11, -3.3e12, 4.4e13];
    Float64List float64List = new Float64List.fromList(floats);
    Uint8List float8List = float64List.buffer.asUint8List();
    ByteBuf buf = new ByteBuf.reader(float8List);

    List<double> list = buf.readFloat64List(float64List.length);
    expect(list, equals(float64List));

    buf = new ByteBuf();
    buf.writeFloat64List(floats);
    list = buf.readFloat64List(floats.length);
    expect(list, equals(float64List));
  });
}
