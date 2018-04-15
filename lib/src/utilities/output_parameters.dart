//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

typedef String OutputRegex(RegExp rexp);

typedef String OutputPathFrom(String inputPath);

const int k1MB = 1024 * 1024;

//Urgent: finish if useful
class OutputParameters {
  /// The [TransferSyntax] for the encoded output. If null
  /// the output will have the same [TransferSyntax] as the Root
  /// Dataset. If the [TransferSyntax] of the Root Dataset is
  /// null then it defaults to [Explicit VR Little Endian].
  final TransferSyntax outputTS;

  /// If true errors will throw; otherwise, they return null.
  /// The default is true.
  final bool throwOnError;

  // The length of the initial output ByteData buffer.
  final int bufferLength;

  /// The path where the encoded data should be written.
  /// If [outPath] is null the encoded data is not written;
  /// it is just returned as the value of the encoder.
  final String outPath;

  final bool reUseBD;

  // Move to output utils.
  //RegExp _inRegexp;

  //RegExp _outRegexp;

  const OutputParameters(
      { this.outPath,
        this.outputTS,
        this.throwOnError = true,
        this.bufferLength = k1MB,

        this.reUseBD = false});

  static const OutputParameters kDefault = const OutputParameters();

  static const OutputParameters kCanonical = const OutputParameters(
    throwOnError: true,
    bufferLength: 1024 * 1024,

    //TODO: complete
    reUseBD: true,);


}