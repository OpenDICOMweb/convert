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

abstract class Dataset {
  static final Logger log = new Logger('Dataset', watermark: Severity.info);
  final ByteData bd;
  final Dataset parent;
  final  Map<int, Element> eLUTable;
  final bool hadUndefinedLength;
  final Map<int, Element> dupLUTable= <int, Element>{};

  Dataset(this.bd, this.parent, this.eLUTable,
      [this.hadUndefinedLength = false]);

  Element operator [](int code) {
    log.debug('[] hex ${toHex32(code)} dec $code');
    var e = eLUTable[code];
    if (e != null) {
      log.debug('[] code ${toHex32(code)} e.dcm(${e.dcm}) [${e.code}] $e');
      log.debug('elements: $eLUTable');
    }
    return e;
  }

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

  bool get isRoot => false;

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
    if (code == null) throw 'add';
    //  log.debug('e1.AsList: ${e1.asList}');
    //  int e1CodeA = e1.code;
    // log.debug('e1CodeA: ${e1.code}');
    // log.debug('add: code(${toHex32(code)}=$code): e1.code(${e1.code})');
    log.debug('add0 e1.code(${toHex32(e1.code)}[${e1.code}]');
    var e0 = eLUTable[code];
    if (e0 != null) {
      log.debug('[] e.dcm(${e0.dcm}) [${e0.code}] $e0');
      log.debug('Error: Duplicate Element - 1st: $e1, 2nd: $e0');
      dupLUTable[e1.code] = e1;
    } else {
      //  log.debug('e1: $e1');
      //  log.debug('add:code(${toHex32(code)}[$code]');
      log.debug('add1 e1.code(${toHex32(e1.code)}[${e1.code}]');
      eLUTable[code] = e1;
      //  var e2 = elements[e1.code];
      var e3 = eLUTable[code];
      //  log.debug('e1CodeB: ${e1.code}');
      // log.debug('e1.AsList: ${e1.asList}');
      //  if (e3.code != code)
      //   throw 'elements problem: code($code) e1(${e1.code}) e3(${e3.code})';
      if (e1.code != e3.code) throw 'elements problem: e1($e1) e3($e3)';
    }
    log.debug('elements: ${this.info}');
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
  TransferSyntax _transferSyntax;

  RootDataset(ByteData bd, [bool hadUndefinedLength = true])
      : super(bd, null, <int, Element>{}, hadUndefinedLength);

  @override
  bool get isRoot => parent == null;

  bool get isFMIPresent =>
      (eLUTable[kFileMetaInformationGroupLength] != null) ? true : false;

  @override
  TransferSyntax get transferSyntax => _transferSyntax ??= _getTS();

  TransferSyntax _getTS() {
    var e = eLUTable[kTransferSyntaxUID];
    if (e == null) return null;
    return TransferSyntax.lookup(e.asString);
  }

  /// Returns [true] if the [Dataset] being read has an
  /// Explicit VR Transfer Syntax.
  @override
  bool get isExplicitVR =>
      transferSyntax != TransferSyntax.kImplicitVRLittleEndian;

  @override
  String toString() => '$runtimeType: FMI($isFMIPresent) TS'
      '($transferSyntax), '
      'elements($length), duplicates(${dupLUTable.length})';
}

class Item extends Dataset {
  Element _sq;

  Item(ByteData e, Dataset parent, Map<int, Element> elements,
      [bool hadUndefinedLength = false])
      : super(e, parent, elements, hadUndefinedLength);

  void addSQ(Element sq) {
    assert(sq is EVRSequence || sq is IVRSequence, 'Invalid Type');
    assert(_sq == null);
    _sq = sq;
  }
}
