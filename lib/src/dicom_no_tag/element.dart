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
  final ByteData bd;
  Uint8List _vf;
  var _values;

  Element(this.bd);

  @override
  bool operator ==(Object o) {
    if (o is EVRElement && bd.lengthInBytes == o.bd.lengthInBytes) {
      for (int i = 0; i < bd.lengthInBytes; i++)
        if (bd.getUint8(i) != o.bd.getUint8(i)) return false;
      return true;
    }
    return false;
  }

  // **** abstract Getters

  /// The [VR] of this [Element].
  int get vrCode;

  /// The number of bytes from the beginning of the [Element] to the
  /// beginning of the Value Field.
  int get vfOffset;

  /// Returns the [int] contained in the Value Field of the [Element] [bd].
  int get vfLength;

  List get values;

  bool get isExplicitVR;

  // **** Concrete Getters, and Methods

  Uint8List get bytes =>
      bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);

  @override
  int get hashCode => bd.hashCode;

  // Tag Code Getters
  int get group => bd.getUint16(0, Endianness.HOST_ENDIAN);

  int get elt => bd.getUint16(2, Endianness.HOST_ENDIAN);

  int get code {
    int group = bd.getUint16(0, Endianness.HOST_ENDIAN);
    int elt = bd.getUint16(2, Endianness.HOST_ENDIAN);
    return (group << 16) + elt;
  }

  int get lengthInBytes {
    if (vf.length.isOdd) throw "odd length VF error.";
    if (vfLength != kUndefinedLength && vfLength != vf.length)
      throw 'Invalid Length Field error: '
          'vfLength($vfLength) vf.length(${vf.length})';
    // vfOffset is the length of the Element header.
    return vfOffset + vf.length;
  }

  bool get isFMI => code >= 0x00020000 && code <= 0x00020102;

  String get groupHex => toHex16(group);

  String get eltHex => toHex16(elt);

  String get dcm => '($groupHex,$eltHex)';

  String get hex => '0x$code';

  VR get vr => VR.vrMap[vrCode];

  String get vrName => vr.asString;

  String get vrHex => '0x${toHex16(vr.code)}';

  // The [Element] as a [Uint8List].
  Uint8List get asList =>
      bd.buffer.asUint8List(bd.offsetInBytes, bd.lengthInBytes);

  bool get wasUndefined => vfLength == 0xFFFFFFFF;

  // The [Element]s Value Field as a [Uint8List].
  Uint8List get vf => _vf ??= bd.buffer
      .asUint8List(bd.offsetInBytes + vfOffset, bd.lengthInBytes - vfOffset);

  // **** Values Getters

  /// The length of the [values] [List].
  int get length => (isBinary) ? vf.length ~/ vr.elementSize : vf.length;

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
  String toString() => '[${bd.offsetInBytes}]$runtimeType$dcm $vr, '
      '(ox${toHex32(vfLength)}, $vfLength, ${vf.length})  ($length) $vf';
}

class EVRElement extends Element {
  EVRElement(ByteData e) : super(e);

  @override
  bool get isExplicitVR => true;

  @override
  int get vrCode => bd.getUint16(4, Endianness.HOST_ENDIAN);

  @override
  int get vfOffset => (vr.hasShortVF) ? 8 : 12;

  @override
  int get vfLength => (vr.hasShortVF)
      ? bd.getUint16(6, Endianness.HOST_ENDIAN)
      : bd.getUint32(8, Endianness.HOST_ENDIAN);

  @override
  List get values => _values ??= _getValues();

  /// The length of the [values] [List].
  @override
  int get length => (isBinary) ? vf.length ~/ vr.elementSize : vf.length;

  String get type => (isBinary) ? "Binary" : "String";

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

  String get info => '$this ($length)${_getValues(10)}';

  dynamic _getValues([int vLength = -1]) {
    List v = (isBinary) ? asNumList : asStringList;
    if (vLength < 0) return v;
    int len = (v.length <= vLength) ? v.length : vLength;
    v = v.sublist(0, len);
    return '$v...';
  }

  @override
  String toString() => '[${bd.offsetInBytes}]$runtimeType$dcm $vr, '
      '(ox${toHex32(vfLength)}, $vfLength, ${vf.length}) ${_getValues(10)}';

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

class IVRElement extends Element {
  IVRElement(ByteData e) : super(e);

  @override
  bool get isExplicitVR => false;

  @override
  int get vrCode => VR.kUN.code;

  @override
  int get vfOffset => 8;

  @override
  int get vfLength => bd.getUint32(4, Endianness.LITTLE_ENDIAN);

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
      '(ox${toHex32(vfLength)}, $vfLength, ${vf.length}) '; //${_getValues(10)}';
}

abstract class Sequence extends Element {
  final Dataset parent;
  final List<Item> items;
  final bool hadUndefinedLength;

  Sequence(ByteData bd, this.parent, this.items, this.hadUndefinedLength)
      : super(bd);

  Item operator [](int index) => items[index];

  @override
  bool operator ==(Object o) {
    if (o is Sequence &&
        code == o.code &&
        wasUndefined == o.wasUndefined &&
        items.length == o.items.length) {
      for (int i = 0; i < items.length; i++)
        if (items[i] != o.items[i]) return false;
      return true;
    }
    return false;
  }

  //Urgent fix - this is a stop gap
  @override
  int get hashCode => super.hashCode;

  // VR Getters
  @override
  int get vrCode => VR.kSQ.code;

  @override
  List<Item> get values => items;

  int get total {
    int count = 0;
    for (Item item in items) count += item.total;
    return count;
  }

  String get info => '$this ($length)${_getValues()}';

  dynamic _getValues() {
    var out = "";
    for (Item item in items)
      out += '  ${item.info}\n';
    return out;
  }

  //TODO: make sure its not already present
  void add(Item item) => items.add(item);

  @override
  String toString() => '[${bd.offsetInBytes}]$runtimeType$dcm '
      'v(ox${toHex32(vfLength)}, $vfLength, ${vf.length}) '
      ' ${items.length} Items $total Elements';
}

class EVRSequence extends Sequence {
  @override
  final bool isExplicitVR = true;

  EVRSequence(ByteData e, Dataset parent, List<Item> items,
      [bool hadUndefinedLength = false])
      : super(e, parent, items, hadUndefinedLength);

  int get kSQCode => VR.kSQ.code;

  // VR Getters
  @override
  int get vrCode => bd.getUint16(4, Endianness.HOST_ENDIAN);

//  bool get _hasShortVF => vr.hasShortVF;
  @override
  int get vfLength => bd.getUint32(8, Endianness.HOST_ENDIAN);

  @override
  int get vfOffset => 12;
}

class IVRSequence extends Sequence {
  @override
  final bool isExplicitVR = false;

  IVRSequence(ByteData e, Dataset parent, List<Item> items,
      [bool hadUndefinedLength = false])
      : super(e, parent, items, hadUndefinedLength);

  @override
  int get vrCode => VR.kSQ.code;

  @override
  int get vfOffset => 8;

  @override
  int get vfLength => bd.getUint32(4, Endianness.HOST_ENDIAN);
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
