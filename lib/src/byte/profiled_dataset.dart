// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

/* TODO: uncomment when ready to finish
import 'package:dictionary/dictionary.dart';

import 'package:core/byte_dataset.dart';
import 'package:core/core.dart';



RootTDataset convert(RootByteDataset byteDS) {
  RootByteDataset byteDS;
  RootTDataset tagDS;

  TElement convertElement(Element e) {
    int code = e.code;
    if (Tag.isPublicCode(code)) {
      Tag tag = PTag.lookupByCodeCode(e.code, e.vr, true);
      if (e is ByteSQ) {
        return convertSequence(tag, e));
      } else  {
        return TElement.make(tag, e.vfBytes));
      }
    } else if (Tag.isPrivateCreatorCode(code)) {

    } else if (Tag.isPrivateCode(code)) {
      if (Tag.isPrivateCreatorCode(code)) {
        var tag = new PrivateCreator(e);
    }
      convertPrivateGroup(group, e);
    } else {
      throw new InvalidTagError(code);
    }
  }

TElement convertSequence(Tag tag, ByteSQ bSQ) {

    for (ByteItem bItem in bSQ.items) {
       Map<int, TElement> map = <int, TElement>{};
      for(Element e in bItem.elements) {
        if (e is ByteSQ) {
          map.(convertSequence(tag, bSQ));
        } else {
          tagDS.add(convertElement(e));
        }
      }
    }

  }

   PrivateGroup convertPrivateGroup(int group, Element e) {
    int group = e.group;
    PrivateGroup pg = new PrivateGroup(group);

    return pg;
  }

  for (Element e in byteDS.elements)
    tagDS.add(convertElement(e));
}

class ProfiledDataset extends RootByteDataset {
  RootByteDataset original;

  ProfiledDataset(this.original, {bool replaceAllUids = true})
      : super.from(original);

  static toProfiledDataset(RootByteDataset rds) {

  }

  UI replaceUid(int code, Uid uid) {
    Element ui = original[code];
    if (ui.vr != VR.kUI) throw 'Not a UI Element';
  }
}

*/

