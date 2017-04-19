// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:collection';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:dictionary/dictionary.dart';

import 'dataset.dart';
import 'utils.dart';

abstract class Element {
  // The [Element].
  final ByteData e;
  Uint8List _vf;
  var _values;

  Element(this.e);

  // Tag Code Getters
  int get group => e.getUint16(0, Endianness.HOST_ENDIAN);

  int get elt => e.getUint16(2, Endianness.HOST_ENDIAN);

  int get code {
    int group = e.getUint16(0, Endianness.HOST_ENDIAN);
    int elt = e.getUint16(2, Endianness.HOST_ENDIAN);
    return (group << 16) + elt;
  }

  String get groupHex => toHex16(group);

  String get eltHex => toHex16(elt);

  String get dcm => '($groupHex,$eltHex)';

  String get hex => '0x$code';

  // VR Getter

  /// The [VR] of this [Element].
  VR get vr;

  /// The number of bytes from the beginning of the [Element] to the
  /// beginning of the Value Field.
  int get vfOffset;

  // The [Element] as a [Uint8List].
  Uint8List get asList =>
      e.buffer.asUint8List(e.offsetInBytes, e.lengthInBytes);

  // flush
  // Uint8List getVF() =>
  //     e.buffer.asUint8List(e.offsetInBytes + vfOffset, vf.length);

  /// Returns the [int] contained in the Value Field of the [Element] [e].
  int get vfLength;

  bool get wasUndefined => vfLength == 0xFFFFFFFF;

  // The [Element]s Value Field as a [Uint8List].
  Uint8List get vf => _vf ??= e.buffer
      .asUint8List(e.offsetInBytes + vfOffset, e.lengthInBytes - vfOffset);

  // **** Values Getters

  /// The length of the [values] [List].
  int get length => (isBinary) ? vf.length ~/ vr.elementSize : vf.length;

  List get values;

  dynamic get value => (values.length == 1) ? values[0] : null;

  bool get isBinary => vr.isBinary;

  bool get isString => vr.isString;

  /// Returns the Value Field [vf] as a [String] with any zero padding (UIDs)
  /// removed. Space padding is left in place.
  String get asString {
    if (vf.length == 0) return "";
    String s = new String.fromCharCodes(vf);
    int c = s.codeUnitAt(s.length - 1);
    return (c == 0) ? s.substring(0, s.length - 1) : s;
  }

  List<String> get asStringList => asString.split('\\');

  List<int> get vfAsList => (vf.length < 10) ? vf : vf.sublist(0, 10);

  /// Returns a formatted [String]. See [Formatter].
  String format(Formatter z) => '${z(this)}\n';

  @override
  String toString() => '$runtimeType$dcm $vr, vf($vfLength, ${vf.length}) '
      '($length) $vf';
}

class EVRElement extends Element {
  EVRElement(ByteData e) : super(e);

  // VR Getters
  int get vrCode => e.getUint16(4, Endianness.HOST_ENDIAN);

  @override
  VR get vr => vrMap[vrCode];

  String get vrName => vr.asString;

  String get vrHex => '0x${toHex16(vrCode)}';

//  bool get _hasShortVF => vr.hasShortVF;
  @override
  int get vfLength => (vr.hasShortVF)
      ? e.getUint16(6, Endianness.HOST_ENDIAN)
      : e.getUint32(8, Endianness.HOST_ENDIAN);

  @override
  int get vfOffset => (vr.hasShortVF) ? 8 : 12;

  // **** Values

  /// The length of the [values] [List].
  @override
  int get length => (isBinary) ? vf.length ~/ vr.elementSize : vf.length;

  List<num> get asNumList {
    log.debug('vr: $vr');
    if (vr == VR.kUN || vr == VR.kOB) return Uint8.fromBytes(vf, 0, length);
    if (vr == VR.kSS) return Int16.fromBytes(vf, 0, length);
    if (vr == VR.kSL) return Int16.fromBytes(vf, 0, length);
    if (vr == VR.kUS || vr == VR.kOW) return Uint16.fromBytes(vf, 0, length);
    if (vr == VR.kUL || vr == VR.kOL || vr == VR.kAT)
      return _getUint32List(vf, 0, length);
    if (vr == VR.kFL || vr == VR.kOF) return Float32.fromBytes(vf, 0, length);
    if (vr == VR.kFD || vr == VR.kOD) return Float64.fromBytes(vf, 0, length);
    throw 'Unknown Binary VR';
  }

  @override
  List get values => _values ??= _getValues();

  dynamic _getValues([int vLength = -1]) {
    List v = (isBinary) ? asNumList : asStringList;
    if (vLength < 0) return v;
    int len = (v.length <= vLength) ? v.length : vLength;
    v = v.sublist(0, len);
    return '$v...';
  }

  String get type => (isBinary) ? "Binary" : "String";

  String get info => '$this ($length)${_getValues(10)}';

  @override
  String toString() => '$runtimeType$dcm $vr, '
      '(ox${toHex32(vfLength)}, ${vf.length}) ${_getValues(10)}';

  static const Map<int, VR> vrMap = const <int, VR>{
    0x0000: VR.kInvalid, //no reformat
    0x4541: VR.kAE, 0x5341: VR.kAS, 0x5441: VR.kAT, 0x5242: VR.kBR,
    0x5343: VR.kCS, 0x4144: VR.kDA, 0x5344: VR.kDS, 0x5444: VR.kDT,
    0x4446: VR.kFD, 0x4c46: VR.kFL, 0x5349: VR.kIS, 0x4f4c: VR.kLO,
    0x544c: VR.kLT, 0x424f: VR.kOB, 0x444f: VR.kOD, 0x464f: VR.kOF,
    0x4c4f: VR.kOL, 0x574f: VR.kOW, 0x4e50: VR.kPN, 0x4853: VR.kSH,
    0x4c53: VR.kSL, 0x5153: VR.kSQ, 0x5353: VR.kSS, 0x5453: VR.kST,
    0x4d54: VR.kTM, 0x4355: VR.kUC, 0x4955: VR.kUI, 0x4c55: VR.kUL,
    0x4e55: VR.kUN, 0x5255: VR.kUR, 0x5355: VR.kUS, 0x5455: VR.kUT
  };
}

class EVRSequence extends EVRElement {
  final bool isExplicitVR = true;
  final Dataset parent;
  final List<Item> items;
  final bool hadUndefinedLength;

  EVRSequence(ByteData e, this.parent, this.items, this.hadUndefinedLength)
      : super(e);

  Item operator [](int index) => items[index];

  @override
  List<Item> get values => items;

  //TODO: make sure its not already present
  void add(Item item) => items.add(item);

  @override
  String toString() => '$runtimeType$dcm ${items.length} Items';
}

class IVRElement extends Element {
  IVRElement(ByteData e) : super(e);

  int get vrCode => VR.kUN.code;

  @override
  VR get vr => VR.kUN;

  @override
  int get vfLength => e.getUint32(4, Endianness.LITTLE_ENDIAN);

  @override
  int get vfOffset => 8;

  @override
  List get values => _values ??= vf;

  String get info => '$this ($length)${_getValues(10)}';

  dynamic _getValues([int vLength = -1]) {
    log.debug('getValues: length: (${values.length})');
    if (vLength < 0) return values;
    int len = (values.length <= vLength) ? values.length : vLength;
    return values.sublist(0, len);
  }

  @override
  String toString() => '$runtimeType$dcm $vr, '
      '($vfLength, ${vf.length})'; //${_getValues(10)}';
}

class IVRSequence extends IVRElement {
  final bool isExplicitVR = false;
  final Dataset parent;
  final List<Item> items;
  final bool hadUndefinedLength;

  IVRSequence(ByteData e, this.parent, this.items, this.hadUndefinedLength)
      : super(e);

  Item operator [](int index) => items[index];

  @override
  List<Item> get values => items;

  //TODO: make sure its not already present
  void add(Item item) => items.add(item);

  @override
  String toString() => '$runtimeType$dcm ${items.length} Items';
}

bool _isAligned(int offsetInBytes, int sizeInBytes) =>
    offsetInBytes % sizeInBytes == 0;

//bool _isNotAligned(ByteData bd, int sizeInBytes) => !isAligned(bd);

/// An unaligned Uint32List.  [bd] must be aligned on a 16-bit boundary.
class UnalignedUint32List extends ListBase<int> {
  ByteData bd;

  factory UnalignedUint32List(Uint8List vf, int offsetInBytes, int length) {
    int startIB = vf.offsetInBytes + offsetInBytes;
    assert(vf != null, 'bytes == null');
    assert(_isAligned(vf.offsetInBytes, 2), 'Not aligned on 16-bit boundary');
    var bd0 = vf.buffer.asByteData(startIB, length * 4);
    return new UnalignedUint32List._(bd0);
  }

  UnalignedUint32List._(this.bd);

  @override
  int operator [](int i) => _getUint32(i);

  @override
  void operator []=(int i, int v) => _unsupported();

  @override
  int get length => bd.lengthInBytes ~/ 4;

  @override
  set length(int v) => _unsupported();

  void _unsupported() =>
      throw new UnsupportedError('Unmodifiable UnassignedUint32List');

  int _getUint16(int offset) => bd.getUint16(offset, Endianness.LITTLE_ENDIAN);

  int _getUint32(int i) {
    int offset = i * 4;
    int left = _getUint16(offset) << 16;
    int right = _getUint16(offset + 2);
    return left + right;
  }

  /// Returns an aligned copy of this unaligned list
  Uint32List get copy {
    var v = new Uint32List(length);
    for (int i = 0; i < length; i++) v[i] = _getUint32(i);
    return v;
  }
}

List<int> _getUint32List(Uint8List vf, [int offsetInBytes, int length]) {
  int oib = vf.offsetInBytes + offsetInBytes;
  log.debug('oib($oib), length($length), isAligned(${_isAligned(oib, 4)})');
  if (_isAligned(oib, 4)) {
    return vf.buffer.asUint32List(oib, length);
  } else {
    return new UnalignedUint32List(vf, offsetInBytes, length);
  }
}
