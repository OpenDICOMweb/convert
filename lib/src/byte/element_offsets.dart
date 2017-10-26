// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:element/element.dart';
import 'package:system/core.dart';

class ElementOffsets {
  List<int> starts = <int>[];
  List<int> ends = <int>[];
  List<Element> elements = <Element>[];

  ElementOffsets();

  // Enhancement: before release remove debugging.
  // Note: this does not compare elements!
  @override
  bool operator ==(Object other) {
    var result = true;

    if (other is ElementOffsets) {
  //    log.debug('ElementOffsets0 $length');
  //    log.debug('ElementOffsets0 ${other.length}');
      if (length != other.length) {
        result = false;
        log.debug('Length not equal: $length != ${other.length}');
      }
      final len = (length > other.length) ? other.length : length;
      for (var i = 0; i < len; i++) {
        if (starts[i] != other.starts[i] || ends[i] != other.ends[i]) {
          final end = (len < i + 10) ? len : i + 10;
          for(var j = i; j < end; j++) {
            result = false;
            log..debug('$i: ${starts[i]} other: ${other.starts[i]}')
            ..debug('$i: ${ends[i]} other: ${other.ends[i]}')
            ..debug('$i: ${elements[i]} other: ${other.elements[i]}');
            return false;
          }
        }
      }
  //    log.debug('ElementOffsets equal: $result');
      return result;
    }
    return false;
  }

  @override
  int get hashCode => system.hasher.nList(elements);

  int get length => elements.length;

  void add(int start, int end, Element e) {
    starts.add(start);
    ends.add(end);
    elements.add(e);
  }

  @override
  String toString() {
    final sb = new StringBuffer('ElementOffsets:\n');
    final sWidth = '${starts.last}'.length;
    final eWidth = '${ends.last}'.length;
    for (var i = 0; i < elements.length; i++) {
	    final start = '${starts[i]}'.padLeft(sWidth);
	    final end = '${ends[i]}'.padLeft(eWidth);
	    final e = elements[i];
      sb.write('  $start - $end: $e\n');
    }
    sb.write('  Total: $length\n');
    return sb.toString();
  }
}
