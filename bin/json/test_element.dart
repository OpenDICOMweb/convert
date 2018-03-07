// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.
// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See the AUTHORS file for other contributors.

import 'package:core/server.dart';
import 'package:convert/convert.dart';

void main() {
  Server.initialize(
      name: 'test_element', level: Level.info, throwOnError: true);

  final sb = new JsonWriter.empty();
  final pn =
      TagElement.make(PTag.kPatientName, <String>['Jim^Philbin'], kPNIndex);
  sb.writeElement(pn);
  print("e:\n '$sb'");

  final sh = TagElement.make(PTag.kReferringPhysicianTelephoneNumbers,
      <String>['406', '678', '123'], kSHIndex);
  sb.writeElement(sh);
  print("e:\n '$sb'");

  final ss = TagElement.make(PTag.kTagAngleSecondAxis, <int>[-1], kSSIndex);
  sb.writeElement(ss);
  print("e:\n '$sb'");

  final fd =
      TagElement.make(PTag.kFrameAcquisitionDuration, <double>[-4.4], kFDIndex);
  sb.writeElement(fd);
  print("e:\n '$sb'");

  final jsonArray = '''
{ 
${sb.toString()}
}''';
  print(jsonArray);
}
