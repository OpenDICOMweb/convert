// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';

class FastJsonWriter {
  /// The [RootDataset] to be written.
  final RootDataset rds;

  /// The output [File] path.
  final String path;

  /// An indenting StringBuffer
  final Indenter sb;
  final BulkdataList bdList;

  /// The threshold, in number of bytes, beyond which a Value Field
  /// is move to a Bulkdata object.
  final int bulkdataThreshold;

  /// _true_ if _Bulkdata_ should be separated from _Metadata_.
  final bool separateBulkdata;

  /// _true_ if File Meta-Information should be written as part of
  /// the [RootDataset] being written.
  final bool includeFmi;

  FastJsonWriter(this.rds, this.path,
      {this.bulkdataThreshold = 1024,
      this.separateBulkdata = false,
      this.includeFmi = true,
      int increment = 2})
      : sb = new Indenter(null, increment),
        bdList = (separateBulkdata) ? new BulkdataList(path) : null {
    _separateBulkdata = separateBulkdata;
    _bdThreshold = bulkdataThreshold;
    _bdList = bdList;
  }

  FastJsonWriter.metadata(this.rds, this.path,
      {this.bulkdataThreshold = 1024,
      this.separateBulkdata = false,
      this.includeFmi = true,
      int increment = 2})
      : sb = new Indenter(null, increment),
        bdList = new BulkdataList(path) {
    _separateBulkdata = separateBulkdata;
    _bdThreshold = (separateBulkdata) ? bulkdataThreshold : -1;
  }

  String write() => _writeRootDataset(rds, sb);

  String _writeRootDataset(RootDataset rds, Indenter sb) {
    sb.indent('[');
    if (includeFmi) _writeFmi(rds, sb);
    _writeDataset(rds, '');
    sb.outdent(']');
    return sb.toString();
  }

  void _writeFmi(RootDataset rds, Indenter sb) {
    sb.indent('[');
/*    for (var e in rds.fmi.elements) {
 //     print('writeFmi: $e');
      _writeElement(e, ',');
    }*/
    final elements = rds.fmi.elements;
    final last = elements.length - 1;
    for (var i = 0; i < last; i++)
      _writeElement(elements.elementAt(i), ',');
    _writeElement(elements.elementAt(last), '');
    sb.outdent('],');
  }

  void _writeElement(Element e, String comma) {
    if (e is SQ) {
//      print('e: $e');
      _writeSQ(e, comma);
    } else {
//      print('e: $e');
//      print('e.vr: ${e.vrIndex} tag.vr: ${e.tag.vrIndex}');
      if (e.vrIndex > 30) print(e);
      _elementWriters[e.vrIndex](e, sb, comma);
    }
  }

  void _writeSQ(SQ e, String comma) {
    final items = e.items;
    if (items.isEmpty) {
      sb.writeln('["${e.hex}", "${e.vrId}", []]$comma');
    } else {
//      print('WriteSQ: $e Items: ${e.items.length}');
      sb.indent('["${e.hex}", "${e.vrId}", [', 2);
      _writeItems(e.items, comma);
      sb.outdent(']]$comma', 2);

    }
  }

  void _writeItems(List<Item> items, String comma) {
    final last = items.length - 1;
    for (var i = 0; i < last; i++) {
      final item = items.elementAt(i);
//      print('item: $item');
      _writeDataset(item, ',');
    }
//    final item = items.elementAt(last);
//    print('item: $item');
    _writeDataset(items.elementAt(last), '');
  }

//  void _writeItem(Item item, String comma) => _writeDataset(item, comma);

  void _writeDataset(Dataset ds, String comma) {
    sb.indent('[');
    final elements = ds.elements;
    final last = elements.length - 1;
    for (var i = 0; i < last; i++)
      _writeElement(elements.elementAt(i), ',');
    _writeElement(elements.elementAt(last), '');
    sb.outdent(']$comma');
  }

  void _writeDataset1(Dataset ds, String comma) {
    sb.indent('[');
    for (var e in ds.elements)
      _writeElement(e, ', ');
    sb.outdent(']$comma');
  }
}

typedef void _ElementWriter(Element e, Indenter sb, String comma);

bool _separateBulkdata;
int _bdThreshold;
BulkdataList _bdList;

List<_ElementWriter> _elementWriters = <_ElementWriter>[
  _sqError, // no reformat
  // Maybe Undefined Lengths
  _writeOtherInt, _writeOtherInt, _writeOtherInt,

  // EVR Long
  _writeOtherFloat, _writeOtherFloat, _writeOtherInt,
  _writeStringList, _writeText, _writeText,

  // EVR Short
  _writeStringList, _writeStringList, _writeInt,
  _writeStringList, _writeStringList, _writeStringList,
  _writeStringList, _writeFloat, _writeFloat,
  _writeStringList, _writeStringList, _writeText,
  _writeStringList, _writeStringList, _writeInt,
  _writeInt, _writeText, _writeStringList,
  _writeStringList, _writeInt, _writeInt,
];

Null _sqError(Element e, Indenter sb, String comma) =>
    invalidElementIndex(e.vrIndex);

void _writeFloat(Element e, Indenter sb, String comma) {
  assert(e is Float);
  if (!_separateBulkdata || e.vfLength < _bdThreshold) {
    sb.writeln('["${e.hex}", "${e.vrId}", ${e.values}]$comma');
  } else {
    final url = _bdList.add(e.code, e.vfBytes);
    sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
  }
}

void _writeOtherFloat(Element e, Indenter sb, String comma) {
  assert(e is Float);
//  print('***** vfLength: ${e.vfLength}');
//  print('***** vfBytes.Length: ${e.vfBytes.length}');
  if (!_separateBulkdata || e.vfLength < _bdThreshold) {
    (e.values.isEmpty)
        ? sb.writeln('["${e.hex}", "${e.vrId}", ""]$comma')
        : sb.writeln('["${e.hex}", "${e.vrId}", '
            '["InlineBinary", "${BASE64.encode(e.vfBytes)}"]]$comma');
  } else {
    final url = _bdList.add(e.code, e.vfBytes);
    sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
  }
}

void _writeInt(Element e, Indenter sb, String comma) {
  assert(e is IntBase);
  if (!_separateBulkdata || e.vfLength < _bdThreshold) {
    sb.writeln('["${e.hex}", "${e.vrId}", ${e.values}]$comma');
  } else {
    final url = _bdList.add(e.code, e.vfBytes);
    sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
  }
}


void _writeOtherInt(Element e, Indenter sb, String comma) {
  assert(e is IntBase);
  if (e.code == kPixelData) return _writePixelData(e, sb, comma);
  final v = e.values;
  final vb = e.vfBytes;
  final doPrint = false;

  if (vb is List<int> && vb is TypedData) {
    if (doPrint) {
      print('-----           e: $e');
      print('***** isTypedData: ${e.values is TypedData}');
      print('*****           v: ${v.runtimeType}: ${v.length}');
      print('*****          vb: ${vb.runtimeType}: ${vb.length}');
    //  print('*****      values: (${e.values.length})${e.values}');
      print('*****    vfLength: ${e.vfLength}');
      print('*****        size: ${e.sizeInBytes}');
    //  print('*****     vfBytes: (${e.vfBytes.lengthInBytes})${e.vfBytes}');
    }
    final u8 = vb.buffer.asUint8List(vb.offsetInBytes, vb.lengthInBytes);
    final u8Length = u8.lengthInBytes;
    final vLIB = vb.lengthInBytes;
    assert(u8Length == vLIB, 'u8Length: $u8Length vLIB: $vLIB');
    final vLength = e.values.length * e.sizeInBytes;
    assert(vLength == vb.lengthInBytes, 'vLength: $vLength vLIB: $vLIB');

  }
  if (!_separateBulkdata || e.vfLength < _bdThreshold) {
    (e.values.isEmpty)
        ? sb.writeln('["${e.hex}", "${e.vrId}", []]$comma')
        : sb.writeln('["${e.hex}", "${e.vrId}", ["InlineBinary", '
            '"${BASE64.encode(e.vfBytes)}"]]$comma');
  } else {
    final url = _bdList.add(e.code, e.vfBytes);
    sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
  }
}

void _writePixelData(Element e, Indenter sb, String comma) {
  assert(e is IntBase);
  assert(e.code == kPixelData);
  final v = e.values;
  final vb = e.vfBytes;

  if (vb is List<int> && vb is TypedData) {

    final doPrint = false;
    if (doPrint) {
      print('-----           e: $e');
      print('***** isTypedData: ${e.values is TypedData}');
      print('*****           v: ${v.runtimeType}: ${v.length}');
      print('*****          vb: ${vb.runtimeType}: ${vb.length}');
  //    print('*****      values: (${e.values.length})${e.values}');
      print('*****    vfLength: ${e.vfLength}');
      print('*****        size: ${e.sizeInBytes}');
  //    print('*****     vfBytes: (${e.vfBytes.lengthInBytes})${e.vfBytes}');
    }
    final u8 = vb.buffer.asUint8List(vb.offsetInBytes, vb.lengthInBytes);
    final u8Length = u8.lengthInBytes;
    final vLIB = vb.lengthInBytes;
    assert(u8Length == vLIB, 'u8Length: $u8Length vLIB: $vLIB');
    final vLength = e.values.length * e.sizeInBytes;
    assert(vLength == vb.lengthInBytes, 'vLength: $vLength vLIB: $vLIB');

  }
  if (e.tag.code ==  kPixelData && e is IntBase) {
    if (!_separateBulkdata || e.vfLength < _bdThreshold) {
      final bytes = (e.fragments == null) ? e.vfBytes : e.fragments.bulkdata;
      (e.values.isEmpty)
      ? sb.writeln('["${e.hex}", "${e.vrId}", []]$comma')
      : sb.writeln('["${e.hex}", "${e.vrId}", ["InlineBinary", '
                       '"${BASE64.encode(bytes)}"]]$comma');
    } else {
      final url = _bdList.add(e.code, e.vfBytes);
      sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
    }
  } else {
    throw new ArgumentError('$e is not PixelData');
  }
}

void _writeText(Element e, Indenter sb, String comma) {
  assert(e is Text);
  if (!_separateBulkdata || e.vfLength < _bdThreshold) {
    sb.writeln('["${e.hex}", "${e.vrId}", ["${e.values}"]]$comma');
  } else {
    final url = _bdList.add(e.code, e.vfBytes);
    sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
  }
}

void _writeStringList(Element e, Indenter sb, String comma) {
  assert(e is StringBase, '$e is not StringBase');
  final List<String> v = e.values;
  if (v.isEmpty) {
    sb.writeln('["${e.hex}", "${e.vrId}", []]$comma');
  }
  final nList = new List<String>(v.length);
  var vfLength = 0;
  for (var i = 0; i < v.length; i++) {
    final s = v.elementAt(i);
    vfLength += s.length;
    nList[i] = '"$s"';
    vfLength += nList.length - 1;
  }
  if (!_separateBulkdata || vfLength < _bdThreshold) {
    sb.writeln('["${e.hex}", "${e.vrId}", [${nList.join(', ')}]]$comma');
  } else {
    final url = _bdList.add(e.code, e.vfBytes);
    sb.writeln('["${e.hex}", "${e.vrId}", ["BulkDataUri", "$url"]]$comma');
  }
}
