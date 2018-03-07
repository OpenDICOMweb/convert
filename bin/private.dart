// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

abstract class Base {
  int _foo;

  @override
  String toString() => '$runtimeType: $_foo';
}

class SuperClass {

  int _foo;
  SuperClass(int bar) : _foo = bar;

  int get foo => _foo;

}

class SubClass extends SuperClass {

  SubClass(int bas) : super(bas);

//  int get foo = _foo;

}

void main() {

  final s0 = new SuperClass(999);
  final s1 = new SubClass(000);

  print('s0: $s0, ${s0.foo}');
  print('s1: $s1, ${s1.foo}');
}