// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

import 'dart:typed_data';

import 'package:common/constants.dart';
import 'package:common/logger.dart';
import 'package:common/number.dart';
import 'package:core/core.dart';
import 'package:path/path.dart' as path;

import 'dcm_writer.dart';

//TODO: create extensible write buffers

/// Encoder for DICOM File Format octet streams (Uint8List)
/// [DcmEncoder] reads DICOM SOP Instances and returns a [Dataset].
/// TODO: finish doc
class DcmEncoder extends DcmWriter {
  //TODO: make the buffer grow and shrink adaptively.
  static const int defaultLengthInBytes = 10 * kMB;
  static final Logger log = new Logger("DcmEncoder", watermark: Severity.debug);
  final String filePath;

  /// Creates a new [DcmEncoder]
  DcmEncoder({int lengthInBytes = defaultLengthInBytes, this.filePath = ""})
      : super(lengthInBytes: lengthInBytes) {
    log.debug('Encoder(${Int.toKB(lengthInBytes)}): $this');
  }

  DcmEncoder.toFile(String filePath, [int lengthInBytes = defaultLengthInBytes])
      : filePath = path.normalize(filePath),
        super(lengthInBytes: lengthInBytes);

  //DcmEncoder.fromList(List<int> list, [this.filePath = ""]) : super.fromList(list);

  //TODO: make this a Tr?ansferSyntax
  //TODO: where used
  //static const TransferSyntax littleEndian =
  //   TransferSyntax.kImplicitVRLittleEndian;

  //TODO: only handles SOP Instances for now
  void writeInstance(Instance instance) {
    log.down;
    log.debug('$wbb writeInstance: ${instance.info}');
    writeRootDataset(instance.dataset);
    log.debug('$wee writeInstance.end');
    log.up;
  }

  //TODO: only handles SOP Instances for now
  void writeSeries(Series series) {
    List<Instance> instances = series.instances;
    for (int i = 0; i < instances.length; i++) writeInstance(instances[i]);
  }

  //TODO: only handles SOP Instances for now
  void writeStudy(Study study) {
    List<Instance> instances = study.instances;
    for (int i = 0; i < instances.length; i++) writeInstance(instances[i]);
  }

  Uint8List encodeEntity(Entity entity) {
    log.debug('entity: $entity');
    if (entity is Instance) {
      writeInstance(entity);
    } else if (entity is Series) {
      writeSeries(entity);
    } else if (entity is Study) {
      writeStudy(entity);
    } else {
      throw "Unknown Entity: $entity";
    }
    return new Uint8List.view(bytes.buffer, 0, writeIndex);
  }

  static Uint8List encode(Entity entity) {
    log.debug('DcmEncoder.encode: $entity');
    int lengthIB = entity.dataset.lengthInBytes;
    log.debug('DcmDecoder.endode: length($lengthIB)');
    var encoder = new DcmEncoder(lengthInBytes: lengthIB);
    log.debug('Encoder: $encoder');
    return encoder.encodeEntity(entity);
  }

  static Uint8List encodeDataset(RootTDataset rds) {
    log.debug('DcmEncoder.encodeDataset: $rds');
    int lengthIB = rds.lengthInBytes;
    log.debug('DcmDecoder.endodeDataset: length($lengthIB)');
    var encoder = new DcmEncoder(lengthInBytes: lengthIB);
    log.debug('Encoder: $encoder');
    encoder.writeDataset(rds);
    return encoder.bytes;
  }
}
