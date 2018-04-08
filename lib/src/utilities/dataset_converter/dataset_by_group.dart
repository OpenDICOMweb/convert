// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

// ignore_for_file: only_throw_errors

/// A Dataset containing only private [Element]s or Sequences ([SQ])
/// containing only private [Element]s.
abstract class DatasetByGroup {
  bool hasPrivate;
  // A map that can contain PublicGroup or PrivateGroup
  Map<int, GroupBase> get groups;
  Iterable<Element> get elements;

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

  RootDatasetByGroup.empty([String path = '', Bytes bytes, int fmiEnd = 0])
      : groups = <int, GroupBase>{},
        super.empty(path, bytes, fmiEnd);

  @override
  void addGroup(GroupBase group) => groups[group.gNumber] = group;
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
  void addGroup(GroupBase group) => groups[group.gNumber] = group;
}
