// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:system/server.dart';
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
