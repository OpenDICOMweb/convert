// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';
import 'encoder.dart';

//TODO: figure out what the best allocation size is two avoid splitting the buffer.



class Dicom {

  /// Encode a [Study], [Series], or [Instance].
  static DcmEncoder  encode(Entity entity) {
    if (entity is Study) return encodeStudy(entity);
    if (entity is Series) return encodeSeries(entity);
    if (entity is Instance) return encodeInstance(entity);
    throw new ArgumentError('$entity is not of type $Entity');
  }

  /// Encode a [Study].
  static DcmEncoder encodeStudy(Study study, [DcmEncoder encoder]) {
     if (encoder == null) encoder = new DcmEncoder();
    for (Series s in study)
      encodeSeries(s, encoder);
    return encoder;
  }

  /// Encode a [Series].
  static DcmEncoder  encodeSeries(Series series, [DcmEncoder encoder]) {
    for(Instance instance in series)
      encodeInstance(instance, encoder);
    return encoder;
  }

  /// Encode an [Instance].
  static DcmEncoder  encodeInstance(Instance instance, [DcmEncoder encoder]) =>
    encoder.encodeSopInstance(instance);

}
