// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/common.dart';
import 'package:dictionary/dictionary.dart';

import 'element.dart';
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
abstract class Dataset {
  static final Logger log = new Logger('Dataset', watermark: Severity.debug);
  ByteData _bd;
  final Dataset parent;
  final Map<int, Element> eLUTable;
  final bool hadUndefinedLength;
  final Map<int, Element> dupLUTable = <int, Element>{};

  Dataset(this._bd, this.parent, this.eLUTable,
      {this.hadUndefinedLength = false});

  Element operator [](int code) => eLUTable[code];

  //TODO: what to do about duplicate elements.
  @override
  bool operator ==(Object o) {
    if (o is Dataset &&
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

  //Urgent: make sure this works.
  @override
  int get hashCode => Hash.k3(parent, hadUndefinedLength, eLUTable);

  Iterable get elements => eLUTable.values;

  Iterable get duplicates => dupLUTable.values;

  int get length => eLUTable.length;

  bool get isRoot => parent == null;

  RootDataset get root => (isRoot) ? this : parent.root;

  TransferSyntax get transferSyntax =>
      (isRoot) ? transferSyntax : root.transferSyntax;

  bool get isExplicitVR =>
      (transferSyntax != null) &&
      !(transferSyntax == TransferSyntax.kImplicitVRLittleEndian);

  bool get hasValidTransferSyntax => transferSyntax != null;

  bool get hasDuplicates => dupLUTable.length > 0;

  int get total {
    int count = 0;
    for (Element e in elements) {
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

  void add(int code, Element e1) {
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
}

class RootDataset extends Dataset {
  TransferSyntax _ts;

  RootDataset(ByteData bd, [bool hadUndefinedLength = true])
      : super(bd, null, <int, Element>{},
      hadUndefinedLength: hadUndefinedLength);

  int get smallFileThreshold => 1024;

  /// [true] if the source of this [RootDataset] had length < 1024.
  /// the last [Element] of the [Dataset].
  bool get wasShortFile => (_wasShortFile == null) ? false : _wasShortFile;
  bool _wasShortFile;
  set wasShortFile(bool v) => _wasShortFile ??= v;

  bool get hasFMI =>
      (eLUTable[kFileMetaInformationGroupLength] != null) ? true : false;

  /// [true] if the source of this [RootDataset] had a
  /// DICOM preamble and prefix.
  bool get hadPrefix => (_hadPrefix == null) ? false : _hadPrefix;
  bool _hadPrefix;
  set hadPrefix(bool v) => _hadPrefix ??= v;

  /// [true] if the source of this [RootDataset] had trailing zeros following
  /// the last [Element] of the [Dataset].
  bool get hadTrailingZeros =>
      (_hadTrailingZeros == null) ? false : _hadTrailingZeros;
  bool _hadTrailingZeros;
  set hadTrailingZeros(bool v) => _hadTrailingZeros ??= v;

  /// [true] if the source of this [RootDataset] had data that
  /// was not successfully parsed.
  bool get hadParsingErrors =>
      (_hadParsingErrors == null) ? false : _hadParsingErrors;
  bool _hadParsingErrors;
  set hadParsingErrors(bool v) => _hadParsingErrors ??= v;

  /// [true] if the source of this [RootDataset] had one or more
  /// [Element]s with undefined length that had delimiters followed
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

  /// Returns [true] if the [Dataset] being read has an
  /// Explicit VR Transfer Syntax.
  @override
  bool get isExplicitVR =>
      transferSyntax != TransferSyntax.kImplicitVRLittleEndian;

  // **** Getters and Methods related to the source [ByteData].
  ByteData get bd => _bd;

  final ByteData _emptySourceByteData = new ByteData(0);
  ByteData removeByteData() => _bd = _emptySourceByteData;

  //TODO:
  //DatasetTagged convertToTaggedDataset() {}

  bool _tsIsReady = false;
  bool tsIsNowReady() => _tsIsReady = true;

  // Can't use the full form until the Transfer Syntax has been established.
  @override
  String toString() =>
    (_tsIsReady)
   ? '$runtimeType: FMI($hasFMI) TS($transferSyntax), '
        'elements(${eLUTable.length}), duplicates(${dupLUTable.length})'
  : '$runtimeType: FMI($hasFMI) elements(${eLUTable.length})';
}

class Item extends Dataset {
  Element _sq;

  Item(ByteData e, Dataset parent, Map<int, Element> elements,
      [bool hadUndefinedLength = false])
      : super(e, parent, elements, hadUndefinedLength: hadUndefinedLength);

  void addSQ(Element sq) {
    assert(sq is EVRSequence || sq is IVRSequence);
    assert(_sq == null);
    _sq = sq;
  }
}
