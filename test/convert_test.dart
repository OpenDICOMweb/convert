//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/server.dart' hide group;
import 'package:test/test.dart';

void main() {
	Server.initialize(name: 'convert_test.dart', level: Level.info0);

  group('A group of tests', () {
    //Awesome awesome;

    setUp(() {
      //awesome = new Awesome();
    });

    test('First Test', () {
      //expect(awesome.isAwesome, isTrue);
    });
  });
}
