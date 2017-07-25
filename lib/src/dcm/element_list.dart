// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:common/logger.dart';
import 'package:core/core.dart';

class ElementList {
  static final log = new Logger('ElementList', watermark: Severity.debug);
  List<int> starts = <int>[];
  List<int> ends = <int>[];
  List<Element> elements = <Element>[];

  ElementList();

  bool operator ==(Object other) {
    bool result = true;

    if (other is ElementList) {
  //    log.debug('ElementList0 $length');
  //    log.debug('ElementList0 ${other.length}');
      if (length != other.length) {
        result = false;
        log.debug('Length not equal: $length != ${other.length}');
      }
      int len = (length > other.length) ? other.length : length;
      for (int i = 0; i < len; i++) {
        if (starts[i] != other.starts[i] || ends[i] != other.ends[i]) {
          result = false;
          log.debug('$i: ${starts[i]} other: ${other.starts[i]}');
          log.debug('$i: ${ends[i]} other: ${other.ends[i]}');
          log.debug('$i: ${elements[i]} other: ${other.elements[i]}');
        }
      }
      log.debug('ElementList equal: $result');
      return result;
    }
    return false;
  }

  int get length => elements.length;

  void add(int start, int end, Element e) {
    starts.add(start);
    ends.add(end);
    elements.add(e);
  }

  String toString() {
    var out = "ElementList:\n";
    var sWidth = '${starts.last}'.length;
    var eWidth = '${ends.last}'.length;
    for (int i = 0; i < elements.length; i++) {
      var start = '${starts[i]}'.padLeft(sWidth);
      var end = '${ends[i]}'.padLeft(eWidth);
      var e = elements[i];
      out += '  $start - $end: $e\n';
    }
    out += '  Total: $length\n';
    return out;
  }
}
