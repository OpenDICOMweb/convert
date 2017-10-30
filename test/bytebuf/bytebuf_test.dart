// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:system/server.dart';
import 'package:test/test.dart';

import '../../lib/src/bytebuf/bytebuf.dart';
import 'test_utilities.dart';

String magicAsString = 'DICOM-MD';
final Uint8List magic = magicAsString.codeUnits;

void main() {
  Server.initialize(name: 'bytebuf_test.dart', level: Level.info0);
  test('Read MetadataFile Magic value', () {
	  final s = 'DICOM-MD';
    final list = toUtf8(s);

    final buf = new ByteBuf.fromList(list);
    final name = buf.readString(8);
    expect(name, equals('DICOM-MD'));
  });

  test('Create ByteBuf Read String', () {
    final listIn = ['foo', 'bar', 'baz'];
    final strings = listIn.join('\\');
    final buf = byteBufFromString(strings);

    final s = buf.readString(strings.length);
    expect(s, equals(strings));

    final listOut = s.split(r'\');
    expect(listOut, listIn);
  });

  test('Write then Read String', () {
    final listIn = ['foo', 'bar', 'baz'];
    final sIn = listIn.join('\\');
    final buf = new ByteBuf()..writeString(sIn);
    final sOut = buf.readString(sIn.length);
    expect(sOut, equals(sIn));

    final listOut = sIn.split(r'\');
    expect(listOut, equals(listIn));
  });

  test('Write then Read String List', () {
    final listIn = ['foo', 'bar', 'baz'];
    final s = listIn.join(r'\');
    final buf = new ByteBuf()..writeStringList(listIn);
    final listOut = buf.readStringList(s.length);
    expect(listOut, equals(listIn));
  });

  test('Read String List', () {
    final list = ['foo', 'bar', 'baz'];
    final strings = list.join('\\');
    final buf = byteBufFromString(strings);
    final l1 = buf.readStringList(strings.length);
    expect(l1, equals(list));
  });

  test('Read Int8 Values', () {
    final ints = [0, -1, 2, -3, 4];
    final int8list = new Int8List.fromList(ints);
    final bytes = int8list.buffer.asUint8List();
    final reader = new ByteBuf.reader(bytes);

    var n = reader.readInt8();
    expect(n, equals(ints[0]));
    n = reader.readInt8();
    expect(n, equals(ints[1]));
    n = reader.readInt8();
    expect(n, equals(ints[2]));
    n = reader.readInt8();
    expect(n, equals(ints[3]));
  });

  test('Read Int8List Values', () {
    final ints = [0, -1, 2, -3, 4];
    final int8list = new Int8List.fromList(ints);
    final bytes = int8list.buffer.asUint8List();
    var buf = new ByteBuf.reader(bytes);

    var list = buf.readInt8List(int8list.lengthInBytes);
    expect(list, equals(ints));

    buf = new ByteBuf()..writeInt8List(ints);
    list = buf.readInt8List(ints.length);
    expect(list, equals(ints));
  });

  test('Read Uint8 Values', () {
    final uints = <int>[0, 1, 2, 3, 4];
    final uint8list = new Uint8List.fromList(uints);
    final bytes = uint8list.buffer.asUint8List();
    final s = 'aaaaaaa aaaaaaa aaaaaaa aaaaaaaab';
    final buf = new ByteBuf();

    buf.writeString(s)..writeUint8List(bytes);
    final t = buf.readString(s.length);
    expect(t, equals(s));

    var n = buf.readUint8();
    expect(n, equals(uints[0]));
    n = buf.readUint8();
    expect(n, equals(uints[1]));
    n = buf.readUint8();
    expect(n, equals(uints[2]));
    n = buf.readUint8();
    expect(n, equals(uints[3]));
  });

  test('Read Uint8List Values', () {
    final uints = [0, 1, 2, 3, 4];
    final uint8List = new Uint8List.fromList(uints);
    final bytes = uint8List.buffer.asUint8List();
    var s = '01234567';
    var buf = new ByteBuf()
      ..writeString(s)
      ..writeUint8List(bytes);
    var t = buf.readString(s.length);
    expect(t, equals(s));

    var list = buf.readUint8List(bytes.lengthInBytes);
    expect(list, equals(uints));

    s = 'aaaaaaaab';
    buf = new ByteBuf()
      ..writeString(s)
      ..writeUint8List(bytes);

    t = buf.readString(s.length);
    expect(t, equals(s));

    list = buf.readUint8List(uint8List.lengthInBytes);
    expect(list, equals(uints));

    buf = new ByteBuf()..writeUint8List(uint8List);
    list = buf.readUint8List(uints.length);
    expect(list, equals(uints));
  });

  test('Read Int16 Values', () {
    final int16s = [-257, 3401, -2000, 3000, -4000];
    final int16list = new Int16List.fromList(int16s);
    final bytes = int16list.buffer.asUint8List();
    final buf = new ByteBuf.reader(bytes);

    var n = buf.readInt16();
    expect(n, equals(int16s[0]));
    n = buf.readInt16();
    expect(n, equals(int16s[1]));
    n = buf.readInt16();
    expect(n, equals(int16s[2]));
    n = buf.readInt16();
    expect(n, equals(int16s[3]));
  });

  test('Read Int16List Values', () {
    final int16s = [-257, 3401, -2000, 3000, -4000];
    final int16list = new Int16List.fromList(int16s);
    final bytes = int16list.buffer.asUint8List();
    var buf = new ByteBuf.reader(bytes);

    var list = buf.readInt16List(int16list.length);
    expect(list, equals(int16s));

    buf = new ByteBuf()..writeInt16List(int16s);
    list = buf.readInt16List(int16s.length);
    expect(list, equals(int16s));
  });

  test('Read Uint16 Values', () {
    final uint16s = [257, 3401, 2000, 3000, 4000];
    final uint16list = new Uint16List.fromList(uint16s);
    final bytes = uint16list.buffer.asUint8List();
    final reader = new ByteBuf.reader(bytes);

    var n = reader.readUint16();
    expect(n, equals(uint16s[0]));
    n = reader.readUint16();
    expect(n, equals(uint16s[1]));
    n = reader.readUint16();
    expect(n, equals(uint16s[2]));
    n = reader.readUint16();
    expect(n, equals(uint16s[3]));
  });

  test('Read Uint16List Values', () {
    final uint16s = <int>[257, 3401, 2000, 3000, 4000];
    //  print('length0:${uint16s.length}: $uint16s');
    final uint16List = new Uint16List.fromList(uint16s);
    //  print('length1:${uint16List.length}: $uint16List');
    final bytes = uint16List.buffer.asUint8List();
    //  print('length2:${bytes.length}: $bytes');
    var buf = new ByteBuf.reader(bytes);

    //  print(buf.info);
    var list = buf.readUint16List(uint16List.length);

    expect(uint16s, equals(uint16s));

    buf = new ByteBuf()..writeUint16List(uint16List);
    list = buf.readUint16List(uint16s.length);
    expect(list, equals(uint16s));
  });

  test('Read Int32 Values', () {
    final int32s = [-257000, 3401000, -2000000, 3000000, -4000000];
    final int32list = new Int32List.fromList(int32s);
    final bytes = int32list.buffer.asUint8List();
    final buf = new ByteBuf.reader(bytes);

    var n = buf.readInt32();
    expect(n, equals(int32s[0]));
    n = buf.readInt32();
    expect(n, equals(int32s[1]));
    n = buf.readInt32();
    expect(n, equals(int32s[2]));
    n = buf.readInt32();
    expect(n, equals(int32s[3]));
  });

  test('Read Int32List Values', () {
    final int32s = [-257000, 3401000, -2000000, 3000000, -4000000];
    final int32List = new Int32List.fromList(int32s);
    final bytes = int32List.buffer.asUint8List();
    var buf = new ByteBuf.reader(bytes);
    var list = buf.readInt32List(int32List.length);
    expect(list, equals(int32s));

    buf = new ByteBuf()..writeInt32List(int32List);
    list = buf.readInt32List(int32s.length);
    expect(list, equals(int32s));
  });

  test('Read Uint32 Values', () {
    final uint32s = [2570000, 34010000, 20000000, 30000000, 400000000];
    final uint32list = new Uint32List.fromList(uint32s);
    final bytes = uint32list.buffer.asUint8List();
    final buf = new ByteBuf.reader(bytes);

    var n = buf.readUint32();
    expect(n, equals(uint32s[0]));
    n = buf.readUint32();
    expect(n, equals(uint32s[1]));
    n = buf.readUint32();
    expect(n, equals(uint32s[2]));
    n = buf.readUint32();
    expect(n, equals(uint32s[3]));
  });

  test('Read Uint32List Values', () {
    final uint32s = [2570000, 34010000, 20000000, 30000000, 40000000];
    final uint32list = new Uint32List.fromList(uint32s);
    final bytes = uint32list.buffer.asUint8List();
    var buf = new ByteBuf.reader(bytes);
    var list = buf.readUint32List(uint32list.length);
    expect(list, equals(uint32s));

    buf = new ByteBuf()..writeUint32List(uint32s);
    list = buf.readUint32List(uint32s.length);
    expect(list, equals(uint32s));
  });

  test('Read Int64 Values', () {
    final int64s = [
      -25700000000,
      34010000000,
      -200000000000,
      300000000000,
      -4000000000000
    ];
    final int64list = new Int64List.fromList(int64s);
    final bytes = int64list.buffer.asUint8List();
    final buf = new ByteBuf.reader(bytes);

    var n = buf.readInt64();
    expect(n, equals(int64s[0]));
    n = buf.readInt64();
    expect(n, equals(int64s[1]));
    n = buf.readInt64();
    expect(n, equals(int64s[2]));
    n = buf.readInt64();
    expect(n, equals(int64s[3]));
  });

  test('Read Int64List Values', () {
    final int64s = [
      -25700000000,
      34010000000,
      -200000000000,
      300000000000,
      -4000000000000
    ];
    final int64list = new Int64List.fromList(int64s);
    final bytes = int64list.buffer.asUint8List();
    var buf = new ByteBuf.reader(bytes);
    var list = buf.readInt64List(int64list.length);
    expect(list, equals(int64s));

    buf = new ByteBuf()..writeInt64List(int64s);
    list = buf.readInt64List(int64s.length);
    expect(list, equals(int64s));
  });

  test('Read Uint64 Values', () {
    final uint64s = [25700000000, 34010000000, 200000000000, 300000000000, 4000000000000];
    final uint64list = new Uint64List.fromList(uint64s);
    final bytes = uint64list.buffer.asUint8List();
    final buf = new ByteBuf.reader(bytes);

    var n = buf.readUint64();
    expect(n, equals(uint64s[0]));
    n = buf.readUint64();
    expect(n, equals(uint64s[1]));
    n = buf.readUint64();
    expect(n, equals(uint64s[2]));
    n = buf.readUint64();
    expect(n, equals(uint64s[3]));
  });

  test('Read Uint64List Values', () {
    final uint64s = [25700000000, 34010000000, 200000000000, 300000000000, 4000000000000];
    final uint64list = new Uint64List.fromList(uint64s);
    final bytes = uint64list.buffer.asUint8List();
    var buf = new ByteBuf.reader(bytes);

    var list = buf.readUint64List(uint64list.length);
    expect(list, equals(uint64s));

    buf = new ByteBuf()..writeUint64List(uint64s);
    list = buf.readUint64List(uint64s.length);
    expect(list, equals(uint64s));
  });

  test('Read Float32 Values', () {
    final floats = [0.0, -1.1, 2.2, -3.3, 4.4];
    final float32List = new Float32List.fromList(floats);
    final float8List = float32List.buffer.asUint8List();
    final buf = new ByteBuf.reader(float8List);

    var a = buf.readFloat32();
    expect(a, equals(float32List[0]));
    a = buf.readFloat32();
    expect(a, equals(float32List[1]));
    a = buf.readFloat32();
    expect(a, equals(float32List[2]));
    a = buf.readFloat32();
    expect(a, equals(float32List[3]));
  });

  test('Read Float32List Values', () {
    final floats = [0.0, -1.1, 2.2, -3.3, 4.4];
    final float32List = new Float32List.fromList(floats);
    final float8List = float32List.buffer.asUint8List();
    var buf = new ByteBuf.reader(float8List);

    var list = buf.readFloat32List(float32List.length);
    expect(list, equals(float32List));

    buf = new ByteBuf()..writeFloat32List(float32List);
    list = buf.readFloat32List(floats.length);
    expect(list, equals(float32List));
  });

  test('Read Float64 Values', () {
    final floats = [0.0, -1.1e10, 2.2e11, -3.3e12, 4.4e13];
    final float64List = new Float64List.fromList(floats);
    final float8List = float64List.buffer.asUint8List();
    final buf = new ByteBuf.reader(float8List);

    var a = buf.readFloat64();
    expect(a, equals(float64List[0]));
    a = buf.readFloat64();
    expect(a, equals(float64List[1]));
    a = buf.readFloat64();
    expect(a, equals(float64List[2]));
    a = buf.readFloat64();
    expect(a, equals(float64List[3]));
  });

  test('Read Float64List Values', () {
    final floats = [0.0, -1.1e10, 2.2e11, -3.3e12, 4.4e13];
    final float64List = new Float64List.fromList(floats);
    final float8List = float64List.buffer.asUint8List();
    var buf = new ByteBuf.reader(float8List);
    var list = buf.readFloat64List(float64List.length);
    expect(list, equals(float64List));

    buf = new ByteBuf()..writeFloat64List(floats);
    list = buf.readFloat64List(floats.length);
    expect(list, equals(float64List));
  });
}
