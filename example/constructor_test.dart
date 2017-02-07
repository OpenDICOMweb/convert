// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.


class A  {
  final List<int> value;
  A(this.value);
  static A make(List<int> value) => new A(value);
}

class Z  {
  final List<String> value;
  Z(this.value);
  static A make(List<int> value) => new A(value);
}

Map<int, Type> typeMap = {0: A, 25: Z};

Map<int, Function> funcMap = {0: A.make, 25: Z.make};

//This doesn't work
//Base create(int id, value) => new (map[i])(value);

// This does


