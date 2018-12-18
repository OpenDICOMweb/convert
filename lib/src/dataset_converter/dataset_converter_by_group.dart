//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:converter/src/dataset_converter/dataset_by_group.dart';

// ignore_for_file: public_member_api_docs
// ignore_for_file: only_throw_errors

class DatasetConverterByGroup {
  final RootDatasetByGroup rSds;
  final RootDatasetByGroup rTds;

  DatasetByGroup currentSds;
  DatasetByGroup currentTds;
  int sIndex = 0;
  int tIndex = 0;

  DatasetConverterByGroup(this.rSds) : rTds =  RootDatasetByGroup.empty();

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
    for (var e in rSds.fmi.elements) if (e.isPrivate) rTds.fmi[e.code] = e;
    sIndex += rSds.fmi.length;
    tIndex += rTds.fmi.length;
  }

  void findInRootDataset() => findInDataset(0, null);

  void findInDataset(int dsNumber, Dataset sqParent) {
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
            ?  PublicGroup(e, sqParent)
            :  PrivateGroup(e);

        if (currentTds is DatasetByGroup) {
          currentTds.addGroup(currentGroup);
        } else if (currentTds is RootDatasetByGroup) {
          currentTds.addGroup(currentGroup);
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
          currentSGNumber = 0;
          log.debug1('00 $e');
        } else if (tag is PCTag) {
          final sgNumber = tag.sgNumber;
          log.debug1('${hex8(sgNumber)} $e');
          if (currentSGNumber == 0) currentSGNumber = sgNumber;
          final sg =  PrivateSubgroup(currentGroup, sgNumber);
          currentSubgroup = sg;
          currentGroup.subgroups[sgNumber] = sg;
        } else if (tag is PDTag) {
          final sgNumber = tag.sgNumber;
          if (sgNumber != currentSubgroup.sgNumber) {
            log
              ..up
              ..debug1('  ${hex8(sgNumber)}')
              ..down;
            var sg = currentGroup[sgNumber];
            if (sg == null) {
              log.warn('Subgroup $sg with no creator');
//           final creator = PCtag.makeEmptyPrivateCreator(e.code, e.vrIndex);
              sg =  PrivateSubgroup(currentGroup, sgNumber);
              currentGroup.subgroups[sgNumber] = sg;
            }
            currentSubgroup = sg;
            currentSGNumber = sgNumber;
          } else {
            currentSubgroup.addData(e, sqParent);
          }
          log.debug1(e);

          if (e is SQ) {
            assert(
                currentGroup is PrivateGroup && e.isPrivate && tag.isPrivate);
            final thisGNumber = currentGNumber;
            final privateSQ = findGroupsInSequence(sqParent, e);
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
          final publicSQ = findGroupsInSequence(sqParent, e);
          currentGNumber = thisGNumber;
          currentGroup.add(publicSQ, sqParent);
        }
      } else {
        throw 'Not Public or Private: $e';
      }
    }
    log.up;
  }

  SQ findGroupsInSequence(Dataset sqParent, SQ sq) {
    log.down;
    final psq = SQtag.from(sqParent, sq);
    final parentSds = currentSds;
    final parentTds = currentTds;

    for (var i = 0; i < sq.items.length; i++) {
      final ItemByGroup sItem = sq.items.elementAt(i);
      currentSds = sItem;
      final ItemByGroup cItem = currentTds;
      final tItem =  ItemByGroup(cItem);
      currentTds = tItem;
      log
        ..debug1('DS: $i')
        ..down;
      findInDataset(i, sqParent);
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
