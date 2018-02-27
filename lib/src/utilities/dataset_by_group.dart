// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

// ignore_for_file: only_throw_errors

/// A Dataset containing only private [Element]s or Sequences ([SQ])
/// containing only private [Element]s.
abstract class DatasetByGroup {
  bool hasPrivate;
  // A map that can contain PublicGroup or PrivateGroup
  Map<int, GroupBase> get groups;

  int keyToIndex(int key) => key;

  String get info {
    final sb = new Indenter('$runtimeType: ${groups.length}')..down;
    for (var group in groups.values) sb.writeln('${group.info}');
    sb.up;
    return '$sb';
  }

  void add(Element e) {
    final gNumber = e.group;
    if (gNumber.isOdd) hasPrivate = true;
    groups[e.group].add(e);
  }

  void addGroup(GroupBase group) => groups[group.gNumber] = group;

  String format(Formatter z) =>
      z.fmt('$runtimeType: ${groups.length} Groups', this);
}

class RootDatasetByGroup extends MapRootDataset with DatasetByGroup {
  @override
  final Map<int, GroupBase> groups;

  RootDatasetByGroup.empty([String path = '', ByteData bd, int fmiEnd = 0])
      : groups = <int, GroupBase>{},
        super.empty(path, bd, fmiEnd);
}

/// A Dataset containing only private [Element]s or Sequences ([SQ])
/// containing only private [Element]s.
class ItemByGroup extends MapItem with DatasetByGroup {
  @override
  final Map<int, GroupBase> groups;

  ItemByGroup(Dataset parent, [SQ sq])
      : groups = <int, GroupBase>{},
        super.empty(parent, sq);

  @override
  int keyToIndex(int key) => key;

  @override
  String get info {
    final sb = new Indenter('$runtimeType: ${groups.length}')..down;
    for (var group in groups.values) sb.writeln('${group.info}');
    sb.up;
    return '$sb';
  }
}

abstract class GroupBase {
  int get gNumber;
  Map<int, dynamic> get members;
  String get info;

  void add(Element e);
}

/// A [PublicGroup] can only contain Sequences ([SQ]) that
/// contain Public pElement]s.
class PublicGroup implements GroupBase {
  @override
  final int gNumber;
  List<SQ> sequences = <SQ>[];
  List<SQ> privateSQs = <SQ>[];

  @override
  Map<int, Element> members = <int, Element>{};

  PublicGroup(this.gNumber) : assert(gNumber.isEven);

  @override
  String get info {
    final sb = new Indenter('$runtimeType(${hex16(gNumber)}): '
        '${members.values.length}')
      ..down;
    members.values.forEach(sb.writeln);
    log.up;
    return '$sb';
  }

  @override
  void add(Element e0) {
    // members[e.code] = new SQtag.from(sq);
    members[e0.code] = e0;
    if (e0 is SQ) {
      sequences.add(e0);
      for (var item in e0.items)
        for (var e1 in item.elements) if (e1.group.isOdd) privateSQs.add(e0);
    }
  }

  String format(Formatter z) => z.fmt(
      '$runtimeType(${hex16(gNumber)}): '
      '${members.length} Groups',
      members);

/*
  /// Returns a formatted [String]. See [Formatter].
  String format(Formatter z) {
    final s = z.fmt('${hex16(gNumber)} $this Members: ${members.length}');
    final sb = new StringBuffer(s);
    z.down;
    sb.write(z.fmt('Groups', members));
    z.up;
    return sb.toString();
  }
*/

  @override
  String toString() =>
      '$runtimeType(${hex16(gNumber)}) ${members.values.length} members';
}

/// The Tag (gggg,iiii) has Group Number (i.e. gggg).
/// A [PrivateGroup] is a group of [Element]s that all have the same
/// Private Group Number. An [Element] is a [PrivateGroup] if its
/// Group Number, i.e. the _gggg_ part of (gggg,eeee), is an odd
/// number, and 0x07 < _gggg_ < 0xFFFE.
///
/// Each [PrivateGroup] contains a set of [PrivateSubgroup]s.
class PrivateGroup implements GroupBase {
  /// The Group number for this group
  @override
  final int gNumber;

  /// The Group Length Element for this [PrivateGroup].  This
  /// Private [Element] is retired and normally is not present.
  Element gLength;

  /// Illegal elements between gggg,0001 - gggg,000F
  List<Element> illegal = [];

  /// A [Map] from ```subgroupNumber``` to [PrivateSubgroup].
  final Map<int, PrivateSubgroup> subgroups = <int, PrivateSubgroup>{};

  var _currentSGNumber = 0;
  PrivateSubgroup _currentSubgroup;

  PrivateGroup(this.gNumber) : assert(gNumber.isOdd);

  /// Returns the [PrivateSubgroup] that corresponds with.
  PrivateSubgroup operator [](int pdCode) => subgroups[Tag.toElt(pdCode)];

  @override
  Map<int, PrivateSubgroup> get members => subgroups;

  @override
  String get info {
    final sb = new Indenter('$runtimeType(${hex16(gNumber)}): '
        '${members.values.length}')
      ..down;
    for (var sg in members.values) sb.writeln(sg.info);
    log.up;
    return '$sb';
  }

  /// Returns _true_ if [code] has a Group number equal to [gNumber].
  bool inGroup(int code) => Tag.toGroup(code) == gNumber;

  @override
  void add(Element e) {
    assert(e.isPrivate);
    final tag = e.tag;
    if (tag is PrivateTag) {
      final sgNumber = tag.sgNumber;
      log.debug('currentSGIndex $_currentSGNumber sgNumber $sgNumber');
      if (_currentSGNumber < sgNumber) {
        // privateSubgroupOutOfOrder(_currentSubgroupNumber, sgNumber, e);
        throw 'Private Subgroup out of order: '
            'current($_currentSGNumber) e($sgNumber): $e';
      } else if (sgNumber > _currentSGNumber) {
        _getNewSubgroup(sgNumber);
      }
      if (tag is PCTag) {
        _currentSubgroup.creator = e;
      } else if (tag is PDTag) {
/*        if (e is SQ) {
          add(e);
        } else {*/
          _currentSubgroup.addPD(e);
 //       }
      } else if (tag is GroupLengthPrivateTag) {
        if (gLength != null)
          throw 'Duplicate Group Length Element: 1st: $gLength 2nd: e';
        gLength ?? e;
      } else if (tag is IllegalPrivateTag) {
        illegal.add(e);
      } else {
        throw '**** Internal Error: $e';
      }
    }
    log.debug('Non-Private Element: $e');
  }

  void _getNewSubgroup(int sgNumber, [Element creator]) {
    assert(creator.tag is PCTag || creator == null);
    _currentSGNumber = sgNumber;
    _currentSubgroup = new PrivateSubgroup(this, sgNumber, creator);
    subgroups[sgNumber] = _currentSubgroup;
    _currentSubgroup.creator = creator;
  }

  bool addCreator(Element pc) {
    if (pc.tag is PCTag) {
      final PCTag tag = pc.tag;
      final sg = new PrivateSubgroup(this, tag.sgNumber, pc);
      subgroups[tag.sgNumber] = sg;
      return true;
    }
    return false;
  }

  bool addNoCreator(Element pd) {
    if (pd.tag is! PDTag) log.error('Invalid Private Data Element: $pd');
    if (pd.tag is PDTag) {
      final PDTag tag = pd.tag;
      final sg = new PrivateSubgroup(this, tag.sgNumber, null);
      subgroups[tag.sgNumber] = sg;
      return true;
    }
    return false;
  }

  String format(Formatter z) => z.fmt(
      '$runtimeType(${hex16(gNumber)}): ${subgroups.length} Subroups',
      subgroups);

/*
  /// Returns a formatted [String]. See [Formatter].
  String format(Formatter z) {
    final sb = new StringBuffer('${hex16(gNumber)} $this Subgroups: '
        '${subgroups.length}');
    z.down;
    sb.write(z.fmt(members));
    z.up;
    return sb.toString();
  }
*/

  @override
  String toString([String prefix = '']) =>
      '$runtimeType(${hex16(gNumber)}): ${subgroups.values.length} creators';
}

/// A [PrivateSubgroup] is a group of Private Elements that have the
/// same Private Creator (see PS3.5).
///
/// Unlike other Private Elements, [PrivateCreator]s extends the
/// [LO] [Element]. All [PrivateCreator]s must have only
/// 1 value, which is a [String] that is an identifier for the
/// [PrivateSubgroup].
///
/// _Note_: The [PrivateCreator] read from an encoded Dataset might
/// have a VR of UN, but it will be converted to LO Element when created.
class PrivateSubgroup {
  final PrivateGroup group;

  /// An integer between 0x10 and 0xFF inclusive. If a PCTag Code is denoted
  /// (gggg,00ii), and a PDTag Code is denoted (gggg,iioo) then the Sub-Group
  /// Index corresponds to ii.
  final int sgNumber;

  final Map<int, Object> members;

  factory PrivateSubgroup(PrivateGroup group, int sgNumber, Element _creator) {
    final tag = _creator.tag;
    return (_creator.group == group.gNumber &&
            Tag.pcSubgroup(_creator.code) == sgNumber)
        ? new PrivateSubgroup._(group, sgNumber, _creator)
        : invalidTagError(tag, LO);
  }

  PrivateSubgroup._(this.group, this.sgNumber, [this._creator])
      : members = <int, Element>{};

  // The Private Creator for this subgroup.
  Element get creator => _creator;
  Element _creator;
  set creator(Element e) {
    assert(e.tag is PCTag);
    if (creator != null)
      throw 'Duplicate Subgroup Creator($sgNumber) 1st: $creator 2nd: $e';
    _creator ??= e;
  }

  PCTag get tag => _creator.tag;

  int get groupNumber => group.gNumber;

  String get info {
    final sb = new Indenter('$runtimeType(${hex16(sgNumber)}): '
        '${members.values.length}')
      ..down;
    members.values.forEach(sb.writeln);
    log.up;
    return '$sb';
  }

  Element lookup(int code) => (code == creator.index) ? creator : members[code];

  void add(Element e) {

  }
  void addPD(Element pd) {
    final code = pd.code;
    if (Tag.isValidPDCode(code, _creator.code)) {
      members[code] = pd;
    } else {
      throw 'Invalid PD Element: $pd';
    }
  }

  /// Returns a Private Data [Element].
  Element lookupData(int code) => members[code];

  String format(Formatter z) => z.fmt(
      '$runtimeType(${hex16(sgNumber)}): ${members.length} Subroups $_creator',
      members);

/*
  /// Returns a formatted [String]. See [Formatter].
  String format(Formatter z) {
    final sb = new StringBuffer('${hex16(sgNumber)} $this Subgroups: '
        '${members.length}');
    z.down;
    sb.write(z.fmt(members));
    z.up;
    return sb.toString();
  }
*/

  @override
  String toString() => '${hex8(sgNumber)} $runtimeType: '
      '$creator Members: ${members.length}';
}
