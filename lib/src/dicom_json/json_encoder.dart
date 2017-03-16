// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

import '../bytebuf/bytebuf.dart';

//TODO: Add type variable for [Element<E>] once [Dataset] supports it.
/// Encoder for DICOM File Format octet streams (Uint8List)
/// [JsonEncoder] reads dicom+json SOP Instances and returns a [RootDataset].

/// An extension to ByteBuf used for encoding JSON.
///
/// Creates DICOM+JSON media type strings.
class JsonEncoder extends ByteBuf {
  //*** Constructors ***
  //TODO: what should the default length be

  /// Creates a new [JsonEncoder], where [readIndex] = [writeIndex] = 0.
  JsonEncoder([int lengthInBytes = ByteBuf.defaultLengthInBytes])
      : super.writer(lengthInBytes);

  //TODO: explain use case for this.
  /// Creates a new writable [JsonEncoder] from the [Uint8List] [bytes].
  JsonEncoder.from(JsonEncoder buf, [int offset = 0, int length])
      : super.from(buf, offset, length);

  /// Creates a [Uint8List] with the same length as the elements in [list],
  /// and copies over the elements.  Values are truncated to fit in the list
  /// when they are copied, the same way storing values truncates them.
  JsonEncoder.fromList(List<int> list) : super.fromList(list);

  /// Returns a view of [this].
  JsonEncoder.view(ByteBuf buf, [int offset = 0, int length])
      : super.view(buf, offset, length);

  //**** Methods that Return new [ByteBuf]s.  ****
  //TODO: these next three don't do error checking and they should
  /// Creates a new [ByteBuf] that is a view of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  @override
  JsonEncoder writeView(int offset, int length) =>
      new JsonEncoder.view(this, offset, length);

  //Flush?
  /// Creates a new [ByteBuf] that is a view of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  //@override
  //DcmWriteBuf writeSlice(int offset, int length) =>
  //    new DcmWriteBuf.internal(bytes, offset, offset, length);

  //Flush?
  /// Creates a new [ByteBuf] that is a [sublist] of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
//  @override
  // JsonEncoder sublist(int start, int end) =>
  //     super.sublist(start, end);

  void encode(Study study) {
    Formatter fmt = new Formatter();
    for (Series series in study.series.values)
      for (Instance instance in series.instances.values)
        writeInstance(instance, fmt);
  }

  /// Write a DICOM Instance in dicom+json media type.
  void writeInstance(Instance instance, Formatter fmt) {
    writeString('[\n');
    fmt.down;
    writeDataset(instance.dataset, fmt);
    fmt.up;
    writeString('\n]\n');
  }

  /// Each Dataset is an Array of Elements, and each Element is an Object
  /// in the following format:
  ///     "tag" : {
  ///         "vr": "XX",
  ///         "value": [ values ]
  ///         }
  ///     }
  void writeDataset(Dataset ds, Formatter fmt) {
    for (Element e in ds.map.values) {
      fmt.down;
      writeString('\n$fmt"${e.tag.hex}": {'
          '\n$fmt"vr": "${e.vr.id}",'
          '\n$fmt"Value": [\n');
      writeValues(e, fmt);
      writeString('\n$fmt]\n$fmt\}');
      fmt.up;
    }
  }

  /// Write [e]s [List] of values.
  ByteBuf writeValues(Element e, Formatter fmt) {
    String s;
    //  if ((e is OB) || (e is OD) || (e is OF) || (e is OL) || (e is OW) || (e is UN)) {
    if ((e is IntBase) || (e is FloatBase)) {
      s = e.base64FromBytes(e.bytes);
    } else {
      s = e.asString;
    }
    return writeString(s);
  }

  /* Flush after write values is tested
  String uint8ToBase64String(List<int> iList) {
    var list = new Uint8List(iList.length);
    for(int i = 0; i < list.length; i++)
      list[i] = iList[i];
    return BASE64.encode(list);
  }

  String int16ToBase64String(List<int> iList) {
    var list = new Int16List(iList.length);
    for(int i = 0; i < list.length; i++)
      list[i] = iList[i];
    return BASE64.encode(list.buffer.asUint8List());
  }

  String uint16ToBase64String(List<int> iList) {
    var list = new Uint16List(iList.length);
    for(int i = 0; i < list.length; i++)
      list[i] = iList[i];
    return BASE64.encode(list.buffer.asUint8List());
  }

  String int32ToBase64String(List<int> iList) {
    var list = new Int32List(iList.length);
    for(int i = 0; i < list.length; i++)
      list[i] = iList[i];
    return BASE64.encode(list.buffer.asUint8List());
  }

  String uint32ToBase64String(List<int> iList) {
    var list = new Uint32List(iList.length);
    for(int i = 0; i < list.length; i++)
      list[i] = iList[i];
    return BASE64.encode(list.buffer.asUint8List());
  }

  String float32ToBase64String(List<double> dList) {
    var list = new Float32List(dList.length);
    for(int i = 0; i < list.length; i++)
      list[i] = dList[i];
    return BASE64.encode(list.buffer.asUint8List());
  }

  String float64ToBase64String(List<double> dList) {
    var list = new Float64List(dList.length);
    for(int i = 0; i < list.length; i++)
      list[i] = dList[i];
    return BASE64.encode(list.buffer.asUint8List());
  }
  */

  /// Write an [SQ] [Element] in JSON.
  void writeSequence(Element e, Formatter fmt) {}

  /// Note: empty items are represented as empty JSON objects "{}".
  void writeItem(Item item, Formatter fmt) {}

  /// Write a [PrivateGroup]
  void writePrivateGroup(PrivateGroup group, Formatter fmt) {}
}
