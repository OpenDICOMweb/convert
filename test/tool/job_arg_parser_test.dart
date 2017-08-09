// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'package:dcm_convert/tools.dart';
import 'package:test/test.dart';

void main() {

  const List<String> args0 = const <String> ['foo/bar -o foo/bar/output/ -d'];

  JobArgs results = JobArgs.parse(args0);
  group('Tag Job ArgParser', () {


    test('test', () {
      
    });
    
  });

}