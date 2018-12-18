//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

// ignore_for_file: public_member_api_docs
// ignore_for_file: only_throw_errors

class ElementOffsets {
	int index = 0;
  List<int> starts = <int>[];
  List<int> ends = <int>[];
  List<Element> elements = <Element>[];

  ElementOffsets();

  // Enhancement: before release remove debugging.
  // Note: this does not compare elements!
  @override
  bool operator ==(Object other) {
    var ok = true;

    if (other is ElementOffsets) {
      if (length != other.length) {
        ok = false;
        log.debug('Length not equal: $length != ${other.length}');
      }
      final len = (length > other.length) ? other.length : length;

      for (var i = 0; i < len; i++) {
        if (starts[i] != other.starts[i] || ends[i] != other.ends[i]) {
          final end = (len < i + 10) ? len : i + 10;
          for (var j = i; j < end; j++) {
            ok = false;
            log
              ..debug('$i: ${starts[i]} other: ${other.starts[i]}')
              ..debug('$i: ${ends[i]} other: ${other.ends[i]}')
              ..debug('$i:  this: ${elements[i]}')
              ..debug('$i: other: ${other.elements[i]}');
          }
        }
      }
      return ok;
    }
    return false;
  }

  @override
  int get hashCode => global.hasher.nList(elements);

  int get length => elements.length;

  void add(int start, int end, Element e) {
    starts.add(start);
    ends.add(end);
    elements.add(e);
    index++;
  }

  int get reserveSlot {
	  final current = length;
  	add(-1, -1, null);
  	index++;
  	return current;
  }

  bool insertAt(int index, int start, int end, Element e) {
  	if (index >= starts.length) throw 'Invalid Insert at $index';
  	if (elements[index] != null) throw 'Invalid Insert at $index - '
			  'element[$index] = ${elements[index]} which is not null : $e ';

  	starts[index] = start;
	  ends[index] = end;
	  elements[index] = e;
	  return true;
  }



  @override
  String toString() {
    final sb =  StringBuffer('ElementOffsets:\n');
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

  static final ElementOffsets kEmpty =  ElementOffsets();
}
