//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'package:bytes_dicom/bytes_dicom.dart';
import 'package:core/core.dart';
import 'package:core/vf_fragments.dart';

// ignore_for_file: public_member_api_docs

mixin TagReaderMixin {
  RootDataset get rds;
  Dataset get cds;
  DicomReadBuffer get rb;

  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
          BytesDicom bytes, int fmiEnd) =>
      TagRootDataset(fmi, eMap, path, bytes, fmiEnd);

  Item makeItem(Dataset parent,
          [SQ sequence, Map<int, Element> eMap, BytesDicom bytes]) =>
      TagItem(parent, sequence, eMap ?? <int, Element>{}, bytes);

  Element fromBytes(BytesDicom bytes, Dataset ds, {bool isEvr}) =>
      TagElement.fromBytes(bytes, ds, isEvr: isEvr);

  Element maybeUndefinedFromBytes(BytesDicom bytes, Dataset ds,
          [TransferSyntax ts]) =>
      TagElement.maybeUndefinedFromBytes(bytes, ds);

  Element sqFromBytes(Dataset parent,
          [Iterable<Item> items, BytesDicom bytes]) =>
      SQtag(parent, Tag.lookup(bytes.code), items);

  Element pixelDataFromBytes(BytesDicom bytes,
          [TransferSyntax ts, VFFragmentList _]) {
    switch (bytes.vrIndex) {
      case kOBIndex:
        return OBtagPixelData.fromBytes(bytes);
      case kOWIndex:
        return OWtagPixelData.fromBytes(bytes);
      case kUNIndex:
        return UNtagPixelData.fromBytes(bytes);
      default:
        return badVRIndex(bytes.vrIndex, null, -1);
    }
  }

  Element fromValues<V>(int code, int vrIndex, List<V> vList) =>
      TagElement.fromValues(code, vrIndex, vList, cds);
}
