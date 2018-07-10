//  Copyright (c) 2016, 2017, 2018,
//  Poplar Hill Informatics and the American College of Radiology
//  All rights reserved.
//  Use of this source code is governed by the open source license
//  that can be found in the odw/LICENSE file.
//  Primary Author: Jim Philbin <jfphilbin@gmail.edu>
//  See the AUTHORS file for other contributors.

import 'package:core/core.dart';

//Urgent: test
class EncodingParameters {
  /// if true Datasets will be allowed to be encoded in IVRLE.
  /// The default is false.
  final bool allowImplicitLittleEndian;

  final TransferSyntax targetTS;
  /// Encodes the Root Dataset even if it does not have any FMI.
  final bool allowMissingFMI;

  /// If true Elements will be checked for valid VR by looking up Tag.
  final bool doCheckVR;
  /// If true, ODW FMI (with clean preamble) will be added or replaced,
  /// undefined lengths will be removed, if RootDS is in Implicit VR it
  /// will be converted to Explicit VR, all fragments will be removed.
  final bool doConvertToNormalForm;

  /// If true, a DICOM File Prefix (PS3.10) will be written, and
  /// DICOM File Meta Information (PS3.10) will be written
  /// even if it wasn't present when the Dataset was decoded (parsed).
  final bool doAddMissingFMI;

  /// If true write ODW FMI into encoded output.
  final bool doUpdateFMI;

  /// If the Root Dataset had a non-zero preamble, replace it with all zeros.
  final bool doCleanPreamble;

  /// Replace any undefined length Elements with defined length, except
  /// for Encapsulated kPixelData.
  final bool doConvertUndefinedLengths;

  /// Remove fragments from encapsulated kPixelData frames.
  final bool doRemoveFragments;

  /// Replace any non-zero end of Value Field delimiter lengths with zero.
  final bool doRemoveNoZeroDelimiterLengths;

  /// Correct any padding error in value fields being output.
  final bool doFixPaddingErrors;

  /// Separates encoded output into Metadata and Bulkdata.
  final bool doSeparateBulkdata;

  /// The number of bytes in a value field at which point it is converted
  /// to Bulkdata.
  final int bulkdataThreshold;

  const EncodingParameters({
    this.allowImplicitLittleEndian = true,
	  this.targetTS,
    this.allowMissingFMI = true,
    this.doCheckVR = true,
    this.doConvertToNormalForm = false,
    this.doSeparateBulkdata = false,
    this.bulkdataThreshold = -1,
    this.doAddMissingFMI = false,
    this.doUpdateFMI = false,
    this.doCleanPreamble = false,
    this.doConvertUndefinedLengths = false,
    this.doRemoveFragments = false,
    this.doRemoveNoZeroDelimiterLengths = false,
    this.doFixPaddingErrors = false,

  });

  static const EncodingParameters kNoChange = const EncodingParameters();

  static const EncodingParameters kCanonical = const EncodingParameters(
      allowImplicitLittleEndian: false,
      allowMissingFMI: false,
      doCheckVR: true,
      doSeparateBulkdata: false,
      bulkdataThreshold: -1,
      doConvertToNormalForm: true,
      doAddMissingFMI: true,
      doUpdateFMI: true,
      doCleanPreamble: true,
      doConvertUndefinedLengths: true,
      doRemoveFragments: true,
      doRemoveNoZeroDelimiterLengths: true,
      doFixPaddingErrors: true);

  static const EncodingParameters kCanonicalWithBulkdata = const EncodingParameters(
      allowImplicitLittleEndian: false,
      allowMissingFMI: false,
      doCheckVR: true,
      doSeparateBulkdata: true,
      bulkdataThreshold: 1024,
      doConvertToNormalForm: true,
      doAddMissingFMI: true,
      doUpdateFMI: true,
      doCleanPreamble: true,
      doConvertUndefinedLengths: true,
      doRemoveFragments: true,
      doRemoveNoZeroDelimiterLengths: true,
      doFixPaddingErrors: true);
}
