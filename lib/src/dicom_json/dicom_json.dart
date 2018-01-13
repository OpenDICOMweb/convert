// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'json_encoder.dart';
import 'json_type.dart';

class DicomJson {

  /// Encode a [Study], [Series], or [Instance].
  static String encode(JsonType type, Entity entity) {
    if (entity is Study) return encodeStudy(type, entity);
    if (entity is Series) return encodeSeries(type, entity);
    if (entity is Instance) return encodeInstance(type, entity);
    throw new ArgumentError('$entity is not of type $Entity');
  }

  /// Encode a [Study].
  static String encodeStudy(JsonType type, Study study, [JsonEncoder encoder]) {
    if (encoder == null) encoder = new JsonEncoder(type);
    for (Series series in study)
      encoder.encodeSeries(series);
    return encoder.output;
  }

  /// Encode a [Series].
  static String encodeSeries(JsonType type, Series series, [JsonEncoder encoder]) {
    if (encoder == null) encoder = new JsonEncoder(type);
    for (Instance instance in series)
      encoder.encodeInstance(instance);
    return encoder.output;
  }

  /// Encode an [Instance].
  static String encodeInstance(JsonType type, Instance instance, [JsonEncoder encoder]) {
    if (encoder == null) encoder = new JsonEncoder(type);
    encoder.encodeInstance(instance);
    return encoder.output;
  }


}

