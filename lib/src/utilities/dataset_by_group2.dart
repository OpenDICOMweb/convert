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

  var _currentSGNumber = 0;
  PrivateSubgroup _currentSubgroup;

  @override
  void add(Element e) {
    assert(e.isPrivate);
    final tag = e.tag;
    if (tag is PrivateTag) {
      final sgNumber = tag.sgNumber;
  //    log.debug('currentSGIndex $_currentSGNumber sgNumber $sgNumber');
      assert(_currentSGNumber < sgNumber);
      if (tag is PDTag) {
        if (sgNumber > _currentSGNumber) {
          _currentSGNumber = sgNumber;
          var sg = subgroups[sgNumber];
          sg ??= new PrivateSubgroup.noCreator(this, sgNumber, e.code);
          _currentSubgroup = sg;
        }
        _currentSubgroup.add(e);
      } else if (e is PC) {
        assert(tag is PCTag);
        final sg = new PrivateSubgroup(this, sgNumber, e);
        sg ?? log.error('Invalid Private Data Element: $e');
        subgroups[sgNumber] = sg;
      } else if (tag is GroupLengthPrivateTag) {
        assert(gLength == null);
        gLength = e;
      } else if (tag is IllegalPrivateTag) {
        illegal.add(e);
      } else {
        throw '**** Internal Error: $e';
      }
    }
    log.debug('Non-Private Element: $e');
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
/// Unlike other Private Elements, PrivateCreators extends the
/// [LO] [Element]. All PrivateCreators must have only
/// 1 value, which is a [String] that is an identifier for the
/// [PrivateSubgroup].
///
/// _Note_: The PrivateCreator read from an encoded Dataset might
/// have a VR of UN, but it will be converted to LO Element when created.
class PrivateSubgroup {
  final PrivateGroup parent;

  /// An integer between 0x10 and 0xFF inclusive. If a PCTag Code is denoted
  /// (gggg,00ii), and a PDTag Code is denoted (gggg,iioo) then the Sub-Group
  /// Index corresponds to ii.
  final int sgNumber;
  final String id;
  final PC creator;

  final Map<int, Object> members;

/*
  factory PrivateSubgroup(PrivateGroup group, int sgNumber, PC creator) {
    final tag = creator.tag;
    return (creator.group == group.gNumber &&
            Tag.pcSubgroup(creator.code) == sgNumber)
        ? new PrivateSubgroup._(group, sgNumber, creator)
        : invalidTagError(tag, LO);
  }
*/

  PrivateSubgroup(this.parent, this.sgNumber, this.creator)
      : assert(creator is PC),
        id = creator.id,
        members = <int, Element>{};

  PrivateSubgroup.noCreator(this.parent, this.sgNumber, int pdCode)
      : creator = PCtag.makeEmptyPrivateCreator(pdCode, kLOIndex),
        id = '',
        members = <int, Element>{};

  int get groupNumber => parent.gNumber;

  String get info {
    final sb = new Indenter('$runtimeType(${hex16(sgNumber)}): '
        '${members.values.length}')
      ..down;
    members.values.forEach(sb.writeln);
    log.up;
    return '$sb';
  }

  Element lookup(int code) => (code == creator.code) ? creator : members[code];

  void add(Element pd) {
    if (!Tag.isValidPDCode(pd.code, creator.code))
      throw 'Invalid PD Element: $pd';
    members[pd.code] = pd;
  }

  /// Returns a Private Data [Element].
  Element lookupData(int code) => members[code];

  String format(Formatter z) => z.fmt(
      '$runtimeType(${hex16(sgNumber)}): ${members.length} Subroups $creator',
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
