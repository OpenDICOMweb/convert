// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';

/// A Dataset containing only private [Element]s or Sequences ([SQ])
/// containing only private [Element]s.
abstract class PrivateDataset {

  // A map that can contain PublicGroup or PrivateGroup
  Map<int, GroupBase> get groups;

  int keyToIndex(int key)  => key;

  String get info {
    final sb = new Indenter('$runtimeType: ${groups.length}')..down;
    for (var group in groups.values) sb.writeln('${group.info}');
    sb.up;
    return '$sb';
  }

  void addGroup(GroupBase group) => groups[group.gNumber] = group;

/*
  void add(Element e, [Issues issues]) {
    final group = groups[e.group];
  }
*/

/// Returns a formatted [String]. See [Formatter].
/*
  String format(Formatter z) {
    final sb = new StringBuffer(z.fmt(this));
    z.down;
    sb.writeln(z.fmt('Groups', groups));
    z.up;
    return sb.toString();
  }
*/

/*  @override
  String toString() {
    final seq = (sq == null) ? '' :', SQ = $sq';
    return '$runtimeType: ${groups.length} groups$seq';
  }
 */
}

class PrivateRootDataset extends MapRootDataset with PrivateDataset {
  @override
  final Map<int, GroupBase> groups;
  PrivateRootDataset.empty([String path = '', ByteData bd, int fmiEnd = 0])
      : groups = <int, GroupBase>{},
        super.empty(path, bd, fmiEnd);
}

/// A Dataset containing only private [Element]s or Sequences ([SQ])
/// containing only private [Element]s.
class PrivateItem extends MapItem with PrivateDataset {
  @override
  final Map<int, GroupBase> groups;
  // A map that can contain PublicGroup or PrivateGroup
//  final Map<int, GroupBase> groups = <int, GroupBase>{};

  PrivateItem(Dataset parent, [SQ sq])
      : groups = <int, GroupBase>{},
        super.empty(parent, sq);

  @override
  int keyToIndex(int key)  => key;

  @override
  String get info {
    final sb = new Indenter('$runtimeType: ${groups.length}')..down;
    for (var group in groups.values) sb.writeln('${group.info}');
    sb.up;
    return '$sb';
  }

//  void addGroup(GroupBase group) => groups[group.gNumber] = group;

/*
  @override
  void add(Element e, [Issues issues]) {
    final group = groups[e.group];
  }
*/

  /// Returns a formatted [String]. See [Formatter].
/*
  String format(Formatter z) {
    final sb = new StringBuffer(z.fmt(this));
    z.down;
    sb.writeln(z.fmt('Groups', groups));
    z.up;
    return sb.toString();
  }
*/

/*  @override
  String toString() {
    final seq = (sq == null) ? '' :', SQ = $sq';
    return '$runtimeType: ${groups.length} groups$seq';
  }
 */
}

abstract class GroupBase {
  int get gNumber;
  Map<int, dynamic> get members;
  String get info;

  void add(Element e);

  /// Returns a formatted [String]. See [Formatter].
  //String format(Formatter z) => z.fmt(this, members);
}

/// A [PublicGroup] can only contain Sequences ([SQ]) that
/// contain Public pElement]s.
class PublicGroup extends GroupBase {
  @override
  final int gNumber;
  SQ e;

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
  void add(Element e) {
    final sq = e;
    members[sq.code] = new SQtag.from(sq);
  }

  /// Returns a formatted [String]. See [Formatter].
  String format(Formatter z) {
    final s = z.fmt('${hex16(gNumber)} $this Members: ${members.length}');
    final sb = new StringBuffer(s);
    z.down;
    sb.write(z.fmt('Groups', members));
    z.up;
    return sb.toString();
  }

  @override
  String toString() =>
      '$runtimeType(${hex16(gNumber)}) ${members.values.length} members';
}

/// with Tag Codes (gggg,eeee), where _gggg_ is an odd number,
/// and 0x07 < _gggg_ < 0xFFFE. Each [PrivateGroup] contains a set
/// of [PrivateSubgroup]s.
class PrivateGroup extends GroupBase {
  /// The Group number for this group
  @override
  final int gNumber;
  SQ sq;

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
    for (var sg in members.values) {
      sb.writeln(sg.info);
   /*     ..writeln('${hex8(sg.sgNumber)} ${sg.creator} '
            'Members: ${sg.members.length + 1}')
        ..down
        ..writeln(sg.info);
      */
    }
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
        if (e is SQ) {
          add(e);
        } else {
          _currentSubgroup.addPD(e);
        }
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

  /// Returns a formatted [String]. See [Formatter].
  String format(Formatter z) {
    final sb = new StringBuffer('${hex16(gNumber)} $this Subgroups: '
                                    '${subgroups.length}');
    z.down;
    sb.write(z.fmt(members));
    z.up;
    return sb.toString();
  }

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

  /// The Tag (gggg,iiii) Group Number (i.e. gggg).

  /// An integer between 0x10 and 0xFF inclusive. If a PCTag Code is denoted
  /// (gggg,00ii), and a PDTag Code is denoted (gggg,iioo) then the Sub-Group
  /// Index corresponds to ii.
  final int sgNumber;

  final Map<int, Object> members;

  factory PrivateSubgroup(PrivateGroup group, int sgNumber, Element _creator) {
    final tag = _creator.tag;
//    print('Group: $group sgNumber: $sgNumber creator: $_creator');
    //   if (Tag.isPCCode(_creator.code)) {
    return (_creator.group == group.gNumber &&
            Tag.pcSubgroup(_creator.code) == sgNumber)
        ? new PrivateSubgroup._(group, sgNumber, _creator)
        : invalidTagError(tag, LO);
    //   }
   // log.error('Invalid Creator: $_creator');
   // return null;
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

  /// Adds a Private Data Element to _this_.
  void addPD(Element pd) {
//    print('addPD: PD: $pd creator: $_creator');
    final code = pd.code;
    if (Tag.isValidPDCode(code, _creator.code)) {
      members[code] = pd;
    } else {
      throw 'Invalid PD Element: $pd';
    }
  }

  /// Returns a Private Data [Element].
  Element lookupData(int code) => members[code];

  /// Returns a formatted [String]. See [Formatter].
  String format(Formatter z) {
    final sb = new StringBuffer('${hex16(sgNumber)} $this Subgroups: '
                                    '${members.length}');
    z.down;
    sb.write(z.fmt(members));
    z.up;
    return sb.toString();
  }

  @override
  String toString() => '${hex8(sgNumber)} $runtimeType: '
      '$creator Members: ${members.length}';
}
