// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> - 
// See the AUTHORS file for other contributors.

import 'dart:convert';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as path;
import 'package:core/core.dart';

import 'encoder_bytebuf.dart';

/// Encoder for DICOM File Format octet streams (Uint8List)
/// [DcmEncoder] reads DICOM SOP Instances and returns a [DatasetSop].
/// TODO: finish doc
class DcmEncoder extends DcmEncoderByteBuf {
  static final Logger log = new Logger("DcmEncoder");
  final String filePath;

  /// Creates a new [DcmEncoder]
  factory DcmEncoder([int lengthInBytes = 1024 * 1024]) {
    var bytes = new Uint8List(lengthInBytes);
    return new DcmEncoder._(bytes, 0, 0, lengthInBytes);
  }

  factory DcmEncoder.toFile(String filePath) {
    var normalizedPath = path.normalize(filePath);
    //TODO: create extensible encode buffers
    var bytes = new Uint8List(1024 * 1924);
    return  new DcmEncoder._(bytes, 0, bytes.length, bytes.length, normalizedPath);
  }

  factory DcmEncoder.fromUint8List(Uint8List bytes) =>
      new DcmEncoder._(bytes, 0, bytes.length, bytes.length);

  /// Internal Constructor: Returns a [._slice from [bytes].
  DcmEncoder._(Uint8List bytes, int readIndex, int encodeIndex, int length, [this.filePath])
      : super.internal(bytes, readIndex, encodeIndex, length);


  //Enhancement: if the file has a non-zero preamble, have the ability to encode it out if desired.
  /// Write the 128-byte preamble to the DICOM File Format.
  void encodePreamble() {
    Uint8List preamble = new Uint8List(128);
    writeUint8List(preamble);
  }


  /// Write the DICOM Prefix "DICM".
  // The Prefix is equivalent to a magic number that specifies the [Uint8List] is
  // in DICOM File Format. See PS3.10.
  void encodePrefix() {
    const String prefix = "DICM";
    Uint8List bytes = UTF8.encode(prefix);
    writeUint8List(bytes);
  }

  static const littleEndian =
      WKUid.kImplicitVRLittleEndianDefaultTransferSyntaxforDICOM;

  /// Writes the File Meta Information [Fmi] for this [Instance].
  void encodeFmi(Map<int, Element>  fmi) {
    var values = fmi.values;
    for(Element value in values) print('$value\n');
    //for (int i = 0; i < values.length; i++)
    for(Element a in values) {
      encodeElement(a);
    }
  }

  DcmEncoder encodeStudy(Study study) {
    List<Instance> instances = study.instances;
    for (int i = 0; i < instances.length; i++)
      encodeSopInstance(instances[i]);
    return this;
  }

  DcmEncoder encodeSopInstance(Instance instance) {
    //Logger log = new Logger("DcmEncoder.readSopInstance");
    encodePreamble();
    encodePrefix();
    //print('fmiDataset: ${instance.fmi}');
    encodeFmi(instance.fmi);
    //print('instance.aMap: ${instance.aMap}');
    encodeDataset(instance.dataset.eMap);
    return this;
  }

  /// Returns an [Element] or [null].
  ///
  /// This is the top-level entry point for reading a [Dataset].
   DcmEncoder encodeDataset(Map<int, Element> aMap) {
    final Logger log = new Logger("encodeDataset");
    Iterable<Element> values = aMap.values;
    print('encodeDataset: $values');
    for (Element a in values) {
      if (a.tag == kPixelData) {
        log.debug('PixelData: ${tagToHex(a.tag)}, ${a.vr}, length= ${a.values.length}');
        writePixelData(a);
      } else {
        log.debug('${a.vr.name}: ${tagToHex(a.tag)}, ${a.vr}, length= ${a.values.length}');
        encodeElement(a);
      }
    }
    return this;
  }
}



