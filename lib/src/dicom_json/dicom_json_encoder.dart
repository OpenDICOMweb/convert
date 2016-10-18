// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:bytebuf/bytebuf.dart';
import 'package:core/core.dart';

/// Encoder for DICOM File Format octet streams (Uint8List)
/// [DcmEncoder] reads DICOM SOP Instances and returns a [DatasetSop].


/// An extension to ByteBuf used for encoding JSON.
///
/// Creates DICOM+JSON media type strings.
class DcmJsonEncoderByteBuf extends ByteBuf {

  //*** Constructors ***
  //TODO: what should the default length be

  /// Creates a new [DcmEncoderByteBuf] of [maxCapacity], where
  ///  [readIndex] = [writeIndex] = 0.
  factory DcmJsonEncoderByteBuf([int lengthInBytes = ByteBuf.defaultLengthInBytes]) {
    if (lengthInBytes == null)
      lengthInBytes = ByteBuf.defaultLengthInBytes;
    if ((lengthInBytes < 0) || (lengthInBytes > ByteBuf.maxMaxCapacity))
      ByteBuf.invalidLength(lengthInBytes);
    return new DcmJsonEncoderByteBuf.internal(new Uint8List(lengthInBytes), 0, 0, lengthInBytes);
  }

  //TODO: explain use case for this.
  /// Creates a new writable [DcmJsonEncoderByteBuf] from the [Uint8List] [bytes].
  factory DcmJsonEncoderByteBuf.fromByteBuf(DcmJsonEncoderByteBuf buf, [int offset = 0, int length]) {
    length = (length == null) ? buf.bytes.length : length;
    if ((length < 0) || ((offset < 0) || ((buf.bytes.length - offset) < length)))
      ByteBuf.invalidOffsetOrLength(offset, length, buf.bytes);
    return new DcmJsonEncoderByteBuf.internal(buf.bytes, offset, length, length);
  }

  /// Creates a new writable [DcmJsonEncoderByteBuf] from the [Uint8List] [bytes].
  factory DcmJsonEncoderByteBuf.fromUint8List(Uint8List bytes, [int offset = 0, int length]) {
    length = (length == null) ? bytes.length : length;
    if ((length < 0) || ((offset < 0) || ((bytes.length - offset) < length)))
      ByteBuf.invalidOffsetOrLength(offset, length, bytes);
    return new DcmJsonEncoderByteBuf.internal(bytes, offset, length, length);
  }

  /// Creates a [Uint8List] with the same length as the elements in [list],
  /// and copies over the elements.  Values are truncated to fit in the list
  /// when they are copied, the same way storing values truncates them.
  factory DcmJsonEncoderByteBuf.fromList(List<int> list) =>
      new DcmJsonEncoderByteBuf.internal(new Uint8List.fromList(list), 0, list.length, list.length);

  factory DcmJsonEncoderByteBuf.view(ByteBuf buf, [int offset = 0, int length]) {
    length = (length == null) ? buf.bytes.length : length;
    if ((length < 0) || ((offset < 0) || ((buf.bytes.length - offset) < length)))
      ByteBuf.invalidOffsetOrLength(offset, length, buf.bytes);
    Uint8List bytes = buf.bytes.buffer.asUint8List(offset, length);
    return new DcmJsonEncoderByteBuf.internal(bytes, offset, length, length);
  }

  /// Internal Constructor: Returns a [._slice from [bytes].
  DcmJsonEncoderByteBuf.internal(Uint8List bytes, int readIndex, int writeIndex, int length)
      : super.internal(bytes, readIndex, writeIndex, length);

  //**** Methods that Return new [ByteBuf]s.  ****
  //TODO: these next three don't do error checking and they should
  /// Creates a new [ByteBuf] that is a view of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  @override
  DcmJsonEncoderByteBuf writeSlice(int offset, int length) =>
      new DcmJsonEncoderByteBuf.internal(bytes, offset, length, length);

  //Flush?
  /// Creates a new [ByteBuf] that is a view of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  //@override
  //DcmWriteBuf writeSlice(int offset, int length) =>
  //    new DcmWriteBuf.internal(bytes, offset, offset, length);

  /// Creates a new [ByteBuf] that is a [sublist] of [this].  The underlying
  /// [Uint8List] is shared, and modifications to it will be visible in the original.
  @override
  DcmJsonEncoderByteBuf sublist(int start, int end) =>
      new DcmJsonEncoderByteBuf.internal(bytes, start, end - start, end - start);


  void encode(Study study) {
    Prefixer fmt = new Prefixer();
    for (Series series in study.series.values)
      for (Instance instance in series.instances.values)
        writeInstance(instance, fmt);
  }

  void writeInstance(Instance instance, Prefixer fmt) {
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
  void writeDataset(Dataset ds, Prefixer fmt) {
    for(Element e in ds.eMap.values) {
      fmt.down;
      writeString('\n$fmt"${tagToHex(e.tag)}": {'
                      '\n$fmt"vr": "${e.vr.name}",'
                      '\n$fmt"Value": [\n');
      writeValues(e, fmt);
      writeString('\n$fmt]\n$fmt\}');
      fmt.up;
    }
  }

  ByteBuf writeValues(Element e, Prefixer fmt) {
    String s;
    if ((e is OB) || (e is OD) || (e is OF) || (e is OL) || (e is OW) || (e is UN)) {
      s = e.base64;
    } else {
      s = e.valuesString;
    }
    return writeString(s);
  }

  /*
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

  void writeSequence(Element e, Prefixer fmt) {

  }

  /// Note: empty items are represented as empty JSON objects "{}".
  void writeItem(Item item, Prefixer fmt) {

  }

  void writePrivateGroup(Element e, Prefixer fmt) {

  }


}