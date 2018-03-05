// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/utilities/dataset_by_group.dart';

// ignore_for_file: only_throw_errors

typedef Element ElementFrom(Element e);

typedef Element ElementMaker<V>(Tag tag, List<V> values, int vrIndex,
    [int vfLengthField]);

typedef Item ItemMaker(Dataset parent, SQ sq);

class DatasetConverterByGroup {
  final RootDataset rSds;
  final RootDataset rTds;

  Dataset currentSds;
  Dataset currentTds;
  int sIndex = 0;
  int tIndex = 0;

  DatasetConverterByGroup(this.rSds) : rTds = new RootDatasetByGroup.empty();

  RootDatasetByGroup find() {
    currentSds = rSds;
    currentTds = rTds;
    log
      ..debug('Finder In:')
      ..debug('  Source RDS count: $rSds')
      ..debug('  Target RDS count: $rTds');
    _findFmi();
    findInRootDataset();
    log
      ..debug('Finder Out:')
      ..debug('Source RDS count: $sIndex total: ${rSds.total}')
      ..debug('Target RDS count: $tIndex total: ${rSds.total}');
    return rTds;
  }

  // Does not handle SQ or Private
  void _findFmi() {
    for (var e in rSds.fmi.elements)
      if (e.isPrivate) rTds.fmi[e.code] = e;
    sIndex += rSds.fmi.length;
    tIndex += rTds.fmi.length;
  }

  void findInRootDataset() => findInDataset(0);

  void findInDataset(int dsNumber) {
    GroupBase currentGroup;
    PrivateSubgroup currentSubgroup;
    var currentGNumber = 0;
    var currentSGNumber = 0;
//    sIndex += currentSds.elements.length;
    for (var e in currentSds.elements) {
      //  log.debug1('* $e');
      final gNumber = e.group;
      final tag = e.tag;
      assert(tag.group == gNumber);
      sIndex++;
      if (gNumber < currentGNumber) throw 'Error: e';
      if (gNumber > currentGNumber) {
 //       assert(e is! SQ, '$e');
        if (currentGNumber > 0) log.up;
        currentGNumber = gNumber;
        currentGroup = (gNumber.isEven)
            ? new PublicGroup(gNumber)
            : new PrivateGroup(gNumber);

        if (currentTds is ItemByGroup ) {
          (currentTds as ItemByGroup).addGroup(currentGroup);
        } else if (currentTds is RootDatasetByGroup) {
          (currentTds as RootDatasetByGroup).addGroup(currentGroup);
        } else {
          throw 'bad dataset: $currentTds';
        }
        log
          ..debug2('${hex16(gNumber)} $currentGroup')
          ..down;
      }
      if (currentGroup is PrivateGroup && tag is PrivateTag) {
        assert(e.isPrivate);
        tIndex++;

        if (tag.elt < 10) {
          currentSGNumber == 0;
          log.debug1('00 $e');
          if (tag is GroupLengthPrivateTag) {
            final tag = new GroupLengthPrivateTag(e.code, e.vrIndex);
            currentGroup.gLength = new GLtag(tag, e.values);
          } else {
            final tag = new IllegalPrivateTag(e.code, e.vrIndex);
            currentGroup.illegal
                .add(TagElement.make(tag, e.values, e.vfLengthField));
          }
        } else if (tag is PCTag) {
          final sgNumber = tag.sgNumber;
          log.debug1('${hex8(sgNumber)} $e');
          if (currentSGNumber == 0) currentSGNumber = sgNumber;
          final sg = new PrivateSubgroup(currentGroup, sgNumber, e);
          currentSubgroup = sg;
          currentGroup.subgroups[sgNumber] = sg;
        } else if (tag is PDTag) {
//          print(currentGroup.subgroups);
          final sgNumber = tag.sgNumber;
//          print('sgNumber: ${hex8(sgNumber)} currentSGNumber: '
//              '${hex8(currentSGNumber)}');
//          print('currentSubgroup: $currentSubgroup');

          if (sgNumber != currentSubgroup.sgNumber) {
            log
              ..up
              ..debug1('  ${hex8(sgNumber)}')
              ..down;
            var sg = currentGroup[sgNumber];
            if (sg == null) {
              log.warn('Subgroup $sg with no creator');
              final creator = PCevr.makeEmptyPrivateCreator(e.code, e.vrIndex);
              sg = new PrivateSubgroup(currentGroup, sgNumber, creator);
              currentGroup.subgroups[sgNumber] = sg;
            }
            currentSubgroup = sg;
            currentSGNumber = sgNumber;

          } else {
            currentSubgroup.addPD(e);
          }
          log.debug1(e);

          if (e is SQ) {
            assert(
                currentGroup is PrivateGroup && e.isPrivate && tag.isPrivate);
            final thisGNumber = currentGNumber;
            final privateSQ = findGroupsInSequence(e);
            currentGNumber = thisGNumber;
            currentSubgroup.members[sgNumber] = privateSQ;
          }
        } else {
          throw 'Not Private: $e';
        }
      } else if (currentGroup is PublicGroup && tag is PTag) {
        log.debug1(e);
        if (e is SQ) {
          tIndex++;
          assert(currentGroup is PublicGroup && e.isPublic && tag.isPublic);
          final thisGNumber = currentGNumber;
          final publicSQ = findGroupsInSequence(e);
          currentGNumber = thisGNumber;
          currentGroup.add(publicSQ);
        }
      } else {
        throw 'Not Public or Private: $e';
      }
    }
    log.up;
  }

  SQ findGroupsInSequence(SQ sq) {
    log.down;
    final psq = SQtag.from(sq);
    final parentSds = currentSds;
    final parentTds = currentTds;

    for (var i = 0; i < sq.items.length; i++) {
      currentSds = sq.items.elementAt(i);
      currentTds = new ItemByGroup(currentTds);
      log
        ..debug1('DS: $i')
        ..down;
      findInDataset(i);
      log
        ..debug3('$currentTds')
        ..up;
    }
    currentSds = parentSds;
    currentTds = parentTds;
    log.up;
    return psq;
  }
}

class SQStack extends StackBase<SQ> {
  @override
  final int limit;
  SQStack([this.limit = 100]);
}

class PrivateGroupStack extends StackBase<PrivateGroup> {
  @override
  final int limit;
  PrivateGroupStack([this.limit = 100]);
}

class SQGroupStack extends StackBase<PrivateGroup> {
  @override
  final int limit;
  SQGroupStack([this.limit = 100]);
}
