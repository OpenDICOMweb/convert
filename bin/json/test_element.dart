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

import 'package:core/core.dart';

import 'package:convert/src/json/writer/dicom_writer.dart';

void main() {

  final sb = new Indenter();
  final pn =
      TagElement.make(PTag.kPatientName, <String>['Jim^Philbin'], kPNIndex);
  var s = writeElement(pn, isLast: true);
  print("s: '$s'");

  final sh =
  TagElement.make(PTag.kReferringPhysicianTelephoneNumbers,
                      <String>['406', '678', '123'],
                      kSHIndex);
  s = writeElement(sh, isLast: true);
  print("s: '$s'");


  final ss = TagElement.make(PTag.kTagAngleSecondAxis, <int>[-1], kSSIndex);
  s = writeElement(ss, isLast: true);

  print("s: '$s'");

  final fd = TagElement.make(PTag.kFrameAcquisitionDuration, <double>[-4.4],
                                 kFDIndex);
  s = writeElement(fd, isLast: true);
  sb.write(s);
  print("s: '$s'");

  final jsonArray = '''
[ 
  ${sb.toString()}
]
  
''';
  print(jsonArray);
}
