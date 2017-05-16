// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:collection';
import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:dictionary/dictionary.dart';

import 'byte_element.dart';
import 'utils.dart';

// Issue: If study is modified
//  1. Replace FMI
//  2. Replace all SOPInstanceUids with UuidUids
//
//
// Issue: flags
//  1. add flag doReplaceUndefinedLength
//  2. add flag doReplaceNonZeroDelimiterLengths
//  3. add flag doFixWrongPadding
//  4. add flag doRemoveFragments
abstract class ByteDataset extends MapBase {
  static final Logger log = new Logger('Dataset', watermark: Severity.debug);
  final ByteDataset parent;
  final Map<int, ByteElement> eLUTable;
  final Map<int, ByteElement> dupLUTable;
  final bool hadUndefinedLength;
  ByteData _bd;

  ByteDataset.empty(this.parent)
      : this.eLUTable = <int, ByteElement>{},
        this.dupLUTable = <int, ByteElement>{},
        this.hadUndefinedLength = true;

  ByteDataset.fromByteData(this._bd, this.parent, this.eLUTable,
      {this.hadUndefinedLength = false})
      : dupLUTable = <int, ByteElement>{};

  ByteDataset._(
      this.parent, this.eLUTable, this.dupLUTable, this.hadUndefinedLength);

  ByteElement operator [](int code) => eLUTable[code];

  /// Two [ByteDataset]s are [==] if they have the same [parent], [eLUTable], and
  /// [hadUndefinedLength]. Note: Duplicate [ByteElement]s are currently ignored.
  @override
  bool operator ==(Object o) {
    if (o is ByteDataset &&
        parent == o.parent &&
        hadUndefinedLength == o.hadUndefinedLength &&
        eLUTable.length == o.eLUTable.length) {
      for (int code in eLUTable.keys) {
        if (eLUTable[code] != o.eLUTable[code]) return false;
        return true;
      }
    }
    return false;
  }

  operator []=(int code, ByteElement e) => eLUTable[code] = e;

  //Urgent: make sure this works.
  @override
  int get hashCode => Hash.k3(parent, hadUndefinedLength, eLUTable);

  Iterable get keys => eLUTable.keys;
  Iterable get elements => eLUTable.values;
  Iterable get values => elements;

  void clear() => eLUTable.clear();
  ByteElement remove(int code) => eLUTable.remove(code);

  Iterable get duplicates => dupLUTable.values;

  int get length => eLUTable.length;

  bool get isRoot => parent == null;

  RootByteDataset get root => (isRoot) ? this : parent.root;

  TransferSyntax get transferSyntax =>
      (isRoot) ? transferSyntax : root.transferSyntax;

  bool get isExplicitVR =>
      (transferSyntax != null) &&
      !(transferSyntax == TransferSyntax.kImplicitVRLittleEndian);

  bool get hasValidTransferSyntax => transferSyntax != null;

  bool get hasDuplicates => dupLUTable.length > 0;

  int get total {
    int count = 0;
    for (ByteElement e in elements) {
      if (e is EVRSequence) {
        count += e.total;
      } else if (e is IVRSequence) {
        count += e.total;
      } else {
        count += 1;
      }
    }
    return count;
  }

  String get info {
    var out = '$this\n';
    eLUTable.forEach((code, e) {
      out += '    ${toDcm(code)}: $e\n';
    });
    return out;
  }

  void add(int code, ByteElement e1) {
    var e0 = eLUTable[code];
    if (e0 != null) {
      log.error('Error: Duplicate Element - 1st: $e1, 2nd: $e0');
      dupLUTable[e1.code] = e1;
    } else {
      eLUTable[code] = e1;
    }
  }

  /// Returns a formatted [String]. See [Formatter].
  String format(Formatter z) {
    String out = '${z(this)}\n';
    //  z.down;
    out = z.fmt('Elements(${eLUTable.length})', eLUTable.values);
    //  z.up;
    return out;
  }

  @override
  String toString() => '$runtimeType: elements($length), '
      'duplicates(${dupLUTable.length})';

  static Map<int, ByteElement> copyLut(Map<int, ByteElement> old) {
    var newLUT = <int, ByteElement>{};
    for (ByteElement e in old.values) newLUT[e.code] = e;
    return newLUT;
  }

}

class RootByteDataset extends ByteDataset {
  TransferSyntax _ts;

  RootByteDataset.fromByteData(ByteData bd, {bool hadUndefinedLength = true})
      : super.fromByteData(bd, null, <int, ByteElement>{},
            hadUndefinedLength: hadUndefinedLength);

  RootByteDataset.empty() : super.empty(null);

  RootByteDataset._(Map<int, ByteElement> eLUT, Map<int, ByteElement> dupLUT,
      bool hadUndefinedLength)
      : super._(null, eLUT, dupLUT, true);

  RootByteDataset.fromDataset(RootByteDataset rds)
      : super._(null, ByteDataset.copyLut(rds.eLUTable),
            ByteDataset.copyLut(rds.dupLUTable), rds.hadUndefinedLength);

  int get smallFileThreshold => 1024;

  /// [true] if the source of this [RootByteDataset] had length < 1024.
  /// the last [ByteElement] of the [ByteDataset].
  bool get wasShortFile => (_wasShortFile == null) ? false : _wasShortFile;
  bool _wasShortFile;
  set wasShortFile(bool v) => _wasShortFile ??= v;

  bool get hasFMI =>
      (eLUTable[kFileMetaInformationGroupLength] != null) ? true : false;

  /// [true] if the source of this [RootByteDataset] had a
  /// DICOM preamble and prefix.
  bool get hadPrefix => (_hadPrefix == null) ? false : _hadPrefix;
  bool _hadPrefix;
  set hadPrefix(bool v) => _hadPrefix ??= v;

  /// [true] if the source of this [RootByteDataset] had trailing zeros following
  /// the last [ByteElement] of the [ByteDataset].
  bool get hadTrailingZeros =>
      (_hadTrailingZeros == null) ? false : _hadTrailingZeros;
  bool _hadTrailingZeros;
  set hadTrailingZeros(bool v) => _hadTrailingZeros ??= v;

  /// [true] if the source of this [RootByteDataset] had data that
  /// was not successfully parsed.
  bool get hadParsingErrors =>
      (_hadParsingErrors == null) ? false : _hadParsingErrors;
  bool _hadParsingErrors;
  set hadParsingErrors(bool v) => _hadParsingErrors ??= v;

  /// [true] if the source of this [RootByteDataset] had one or more
  /// [ByteElement]s with undefined length that had delimiters followed
  /// by a non-zero length field.
  bool get hadNonZeroDelimiterLength =>
      (_hadNonZeroDelimiterLength == null) ? false : _hadNonZeroDelimiterLength;
  bool _hadNonZeroDelimiterLength;
  set hadNonZeroDelimiterLength(bool v) => _hadNonZeroDelimiterLength ??= v;

  String get transferSyntaxString {
    var e = eLUTable[kTransferSyntaxUID];
    return (e == null) ? null : e.asString;
  }

  @override
  TransferSyntax get transferSyntax => _ts ??= _getTS();

  TransferSyntax _getTS() {
    String s = transferSyntaxString;
    if (s != null) _ts = TransferSyntax.lookup(s);
    //   print('*** s: $s, ts: $_ts');
    if (_ts == null) _ts = TransferSyntax.kImplicitVRLittleEndian;
    return _ts;
  }

  bool get hadTransferSyntax => (transferSyntaxString != null &&
      (TransferSyntax.lookup(transferSyntaxString) != null));

  /// Returns [true] if the [ByteDataset] being read has an
  /// Explicit VR Transfer Syntax.
  @override
  bool get isExplicitVR =>
      transferSyntax != TransferSyntax.kImplicitVRLittleEndian;

  // **** Getters and Methods related to the source [ByteData].
  ByteData get bd => _bd;

  final ByteData _emptySourceByteData = new ByteData(0);
  ByteData removeByteData() => _bd = _emptySourceByteData;

  bool _tsIsReady = false;
  bool tsIsNowReady() => _tsIsReady = true;

  // Can't use the full form until the Transfer Syntax has been established.
  @override
  String toString() => (_tsIsReady)
      ? '$runtimeType: FMI($hasFMI) TS($transferSyntax), '
          'elements(${eLUTable.length}), duplicates(${dupLUTable.length})'
      : '$runtimeType: FMI($hasFMI) elements(${eLUTable.length})';
}

class ByteItem extends ByteDataset {
  ByteElement _sq;

  ByteItem.fromByteData(
      ByteData bd, ByteDataset parent, Map<int, ByteElement> elements,
      [bool hadUndefinedLength = false])
      : super.fromByteData(bd, parent, elements,
            hadUndefinedLength: hadUndefinedLength);

  void addSQ(ByteElement sq) {
    assert(sq is EVRSequence || sq is IVRSequence);
    assert(_sq == null);
    _sq = sq;
  }
}
