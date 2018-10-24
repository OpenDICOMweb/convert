//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.
//
import 'dart:io';
import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:converter/src/binary/base/writer/writer.dart';
import 'package:converter/src/binary/base/writer/subwriter.dart';
import 'package:converter/src/binary/tag/writer/tag_subwriter.dart';
import 'package:converter/src/encoding_parameters.dart';

/// The [TagWriter] writes [Dataset]s in canonical form.
///     - There are no [kUndefinedLength] value fields, and thus,
///       no [kSequenceDelimiter]s or [kItemDelimiter]s, except
///       for Compressed Pixel Data which must have a [kUndefinedLength]
///       [Item].
///     - All padding is done with valid padding characters,
///       i.e. [kNull](0) for UI and [kSpace](32) for all other String Elements
///     - All Fragments in Pixel Data are removed.
// Urgent Jim: what about the Basic Offset Table?
///     - All [Element]s with a VR of UN have there VR replaced with the
///       correct VR if known. Some Private Elements may have unknown VRs.
///     - Implicit Little Endian and Explicit Big Endian Transfer Syntaxes
///       are replaced with Explicit Little Endian.
///     - Times and DateTimes are written with full accuracy. For example,
///       a time of "10" will be written as "100000", and a dateTime of
///       "1960" will be written as "19600101000000", missing parts of
///       date or time are written as "01" or "00" respectively.
///     -

/// A [class] for writing a [TagRootDataset] to a [Uint8List].
/// Supports encoding all [TransferSyntax]es.
class TagWriter extends Writer {
  @override
  final EvrSubWriter evrSubWriter;

  /// Creates a [TagWriter] where index = 0.
  TagWriter(TagRootDataset rds,
      {EncodingParameters eParams = EncodingParameters.kCanonical,
      TransferSyntax outputTS,
      bool doLogging = false})
      : evrSubWriter = TagEvrSubWriter(rds, eParams,
            outputTS: outputTS, doLogging: doLogging);

  @override
  IvrSubWriter get ivrSubWriter =>
      _ivrSubWriter ??= TagIvrSubWriter.from(evrSubWriter);
  IvrSubWriter _ivrSubWriter;

  /// Writes the [TagRootDataset] to a [Uint8List], and returns the [Uint8List].
  static Bytes writeBytes(TagRootDataset rds,
      {EncodingParameters eParams = EncodingParameters.kCanonical,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkRootDataset(rds);
    final writer = TagWriter(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
    return writer.writeRootDataset();
  }

  /// Writes the [TagRootDataset] to a [Uint8List], and then writes the
  /// [Uint8List] to the [File]. Returns the [Uint8List].
  static Bytes writeFile(TagRootDataset rds, File file,
      {EncodingParameters eParams = EncodingParameters.kCanonical,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkFile(file);
    final bytes = writeBytes(rds,
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
    file.writeAsBytesSync(bytes.asUint8List());
    return bytes;
  }

  /// Creates a empty [File] from [path], writes the [TagRootDataset]
  /// to a [Uint8List], then writes the [Uint8List] to the [File], and
  /// returns the [Uint8List].
  static Bytes writePath(TagRootDataset ds, String path,
      {EncodingParameters eParams = EncodingParameters.kCanonical,
      TransferSyntax outputTS,
      bool doLogging = false}) {
    checkPath(path);
    return writeFile(ds, File(path),
        eParams: eParams, outputTS: outputTS, doLogging: doLogging);
  }
}
