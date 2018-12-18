//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'package:core/core.dart';

// ignore_for_file: public_member_api_docs
// ignore_for_file: only_throw_errors

class DatasetConverter {
  final RootDataset sourceRDS;
  final RootDataset targetRDS;
  final _exceptions = <String>[];
  Dataset currentSDS;
  Dataset currentTDS;
  int nElements = 0;

  DatasetConverter(this.sourceRDS) : targetRDS =  TagRootDataset.empty();

  /// Converts any [RootDataset] to a [TagRootDataset]
  TagRootDataset convert({bool keepFmi = true}) {
    currentSDS = sourceRDS;
    currentTDS = targetRDS;
    log
      ..debug('sourceRDS: ${sourceRDS.total} elements')
      ..debug('    ${sourceRDS.summary}')
      ..debug('Convert FMI');

    nElements = 0;
    if (keepFmi) _convertFmi(sourceRDS, targetRDS);

    log.debug('Convert Root Dataset');
    nElements = 0;
    _convertDataset(sourceRDS, targetRDS);

    log
      ..debug('   Summary: ${targetRDS.summary}')
      ..debug('     Count: $nElements')
      ..debug('Exceptions: ${_exceptions.join('\n')}');
    return targetRDS;
  }

  void _convertFmi(RootDataset sRds, RootDataset tRds) {
    log
      ..debug('  count: $nElements')
      ..debug('  rootBDS FMI: ${sRds.fmi.length}')
      ..debug('  rootTDS FMI: ${tRds.fmi.length}');
    if (targetRDS.fmi.isNotEmpty) throw 'bad targetRDS: $tRds';
    for (var e in sRds.fmi.elements) {
      final te = _convertElement(sRds, e);
      tRds.fmi[te.code] = te;
      if (te == null) throw 'null TE';
    }
    log.debug('  count: $nElements');
  }

  void _convertDataset(RootDataset sRds, RootDataset tRds) {
    log.debug('  count: $nElements');
    if (tRds.isNotEmpty) throw 'bad rootTds: $tRds';
    for (var e in sRds.elements) {
      final te = _convertElement(sRds, e);
      tRds.add(te);
      if (te == null) throw 'null TE';
    }
  }


  Element _convertElement(Dataset ds, Element e) {
    final te = (e is SQ)
               ? _convertSQ(e)
               : TagElement.fromValues(e.code, e.vrIndex, e.values, ds);
    nElements++;
    return te;
  }

  SQ _convertSQ(SQ sq) {
    final parentSDS = currentSDS;
    final parentTDS = currentTDS;

    // add try {} catch {} finally {}
    final tItems =  List<TagItem>(sq.items.length);
    for (var i = 0; i < sq.items.length; i++) {
      currentSDS = sq.items.elementAt(i);
      currentTDS =  TagItem.empty(parentTDS, sq);
      _convertDataset(currentSDS, currentTDS);
      tItems[i] = currentTDS;
    }

    currentSDS = parentSDS;
    currentTDS = parentTDS;

    final tagSQ =  SQtag(parentTDS, sq.tag, tItems);
    for (var item in tItems) item.sequence = tagSQ;
    return tagSQ;
  }

  static TagRootDataset fromByteRootDataset(ByteRootDataset rds,
          {bool keepFmi = true}) =>
       DatasetConverter(rds).convert(keepFmi: keepFmi);
}
