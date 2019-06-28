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

mixin ByteReaderMixin {
  RootDataset get rds;
  Dataset get cds;
  DicomReadBuffer get rb;

  RootDataset makeRootDataset(FmiMap fmi, Map<int, Element> eMap, String path,
          BytesElement bytes, int fmiEnd) =>
      ByteRootDataset(fmi, eMap, path, bytes, fmiEnd);

  Item makeItem(Dataset parent,
          [SQ sequence, Map<int, Element> eMap, BytesElement bytes]) =>
      ByteItem(parent, sequence, eMap ?? <int, Element>{}, bytes);

  Element fromBytes(BytesElement bytes, Dataset ds, {bool isEvr}) =>
      BytesElement.fromBytes(bytes, ds, isEvr: isEvr);

  Element maybeUndefinedFromBytes(BytesElement bytes, Dataset ds) =>
      BytesElement.makeMaybeUndefinedFromBytes(bytes, ds);

  Element pixelDataFromBytes(BytesElement bytes,
      [TransferSyntax ts, VFFragmentList fragments]) {
    switch (bytes.vrIndex) {
      case kOBIndex:
        return OBbytesPixelData.fromBytes(bytes, ts, fragments);
      case kOWIndex:
        return OWbytesPixelData.fromBytes(bytes, ts, fragments);
      case kUNIndex:
        return UNbytesPixelData.fromBytes(bytes, ts, fragments);
      default:
        return badVRIndex(bytes.vrIndex, null, -1, bytes.tag);
    }
  }

  Element sqFromBytes(Dataset parent,
          [Iterable<Item> items, BytesElement bytes]) =>
      SQbytes.fromBytes(parent, items, bytes);

  Element fromValues<V>(int code, int vrIndex, List<V> vList) =>
      BytesElement.fromValues(code, vrIndex, vList, isEvr: true, ds: cds);
}
