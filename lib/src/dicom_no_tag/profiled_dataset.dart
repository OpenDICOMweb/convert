// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:dictionary/dictionary.dart';
import 'package:core/core.dart';

import 'byte_dataset.dart';
import 'byte_element.dart';

class TaggedDataset extends RootByteDataset {
  RootByteDataset original;

  TaggedDataset.fromByteDataset(this.original, {bool replaceAllUids = true})
      : super.fromDataset(original);

  static TaggedDataset convertToTaggedDataset(RootByteDataset rds) {
    RootDataset rds1 = new RootDataset();

    for (ByteElement e in rds.elements) {
      if (e.group.isEven) {
        Tag tag = PTag.lookupCode(e.code, e.vr, true);
        rds1[e.code] = new Element(tag);
      } else {
        _convertPrivateGroup(rds, e);
      }
    }
  }

  static void _convertPrivateGroup(RootByteDataset rds, ByteElement e) {

  }
}

class ProfiledDataset extends RootByteDataset {
  RootByteDataset original;

  ProfiledDataset(this.original, {bool replaceAllUids = true})
      : super.fromDataset(original);

  static toProfiledDataset(RootByteDataset rds) {

  }


  static UI replaceUid(int code, Uid uid) {
    ByteElement ui = original[code];
    if (vr != VR.kUI) throw 'Not a UI Element';
  }
}


Element convertElement(ByteElement be) {
  VR vr = be.vr.make();
}
