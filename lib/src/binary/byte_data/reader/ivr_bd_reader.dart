// Copyright (c) 2016, 2017, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'package:core/core.dart';

import 'package:convert/src/binary/base/reader/debug/log_read_mixin.dart';
import 'package:convert/src/binary/base/reader/ivr_reader.dart';
import 'package:convert/src/binary/byte_data/reader/evr_bd_reader.dart';
import 'package:convert/src/utilities/decoding_parameters.dart';
import 'package:convert/src/utilities/element_offsets.dart';

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class IvrBDReader extends IvrReader<int> {
  final bool isEvr = false;
  @override
  final ReadBuffer rb;
  @override
  final BDRootDataset rds;
  final DecodingParameters dParams;
  final bool reUseBD;

  @override
  Dataset cds;

  /// Creates a new [IvrBDReader].
  IvrBDReader(Bytes bytes, this.rds,
      {this.dParams = DecodingParameters.kNoChange, this.reUseBD = false})
      : rb = new ReadBuffer(bytes),
        cds = rds {
    print('rds: $rds');
  }

  /// Creates a new [EvrBDReader].
  IvrBDReader._(Bytes bytes, this.rds, this.dParams, this.reUseBD)
      : rb = new ReadBuffer(bytes),
        cds = rds {
    print('rds: $rds');
  }

  IvrBDReader.from(EvrBDReader reader)
      : rb = reader.rb,
        dParams = reader.dParams,
        rds = reader.rds,
        cds = reader.cds,
        reUseBD = reader.reUseBD {
    print('rds: $rds');
  }

//  static final BDElementMaker make = Ivr.make;

  @override
  List<Element> get elements => cds.elements;

  @override
  Item makeItem(Dataset parent,
          [SQ sequence, Map<int, Element> eMap, Bytes bd]) =>
      new BDItem.fromBD(parent, sequence, eMap ?? <int, Element>{}, bd);
}

/// A decoder for Binary DICOM (application/dicom).
/// The resulting [Dataset] is a [BDRootDataset].
class IvrLoggingBDReader extends IvrBDReader with LogReadMixin {
  @override
  final ParseInfo pInfo;
  @override
  final ElementOffsets offsets;

  /// Creates a new [IvrLoggingBDReader].
  IvrLoggingBDReader(Bytes bd, BDRootDataset rds,
      {DecodingParameters dParams = DecodingParameters.kNoChange,
      bool reUseBD = true})
      : pInfo = new ParseInfo(rds),
        offsets = new ElementOffsets(),
        super._(bd, rds, dParams, reUseBD);

  IvrLoggingBDReader.from(EvrLoggingBDReader reader)
      : pInfo = new ParseInfo(reader.rds),
        offsets = new ElementOffsets(),
        super.from(reader);
}
