// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:core/core.dart';
import 'decoder.dart';
import 'encoder.dart';

class Dicom {

  static Uint8List encodeSync(Entity entity) {
    if (entity is Study) return encodeStudySync(entity);
    if (entity is Series) return encodeSeriesSync(entity);
    if (entity is Instance) return encodeInstanceSync(entity);
    throw new ArgumentError('$entity is not of type $Entity');
  }

  static Uint8List encodeStudySync(Study study) {
    for (Series s in study) {

    }
  }

  static Uint8List encodeSeriesSync(Series series) {
    for(Instance instance in series) {

    }
  }

  static Uint8List encodeInstanceSync(Instance instance) {

  }

  //TODO: add async methods

}
