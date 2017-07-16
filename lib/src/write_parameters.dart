// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu>
// See /[package]/AUTHORS file for other contributors.

//Urgent: finish
class WriteParameters {
  final bool doConvertUndefinedLengths;
  final bool doRemoveNoZeroDelimiterLengths;
  final bool doFixPaddingErrors;
  final bool doRemoveFragments;

  const WriteParameters(
      {this.doConvertUndefinedLengths = false,
      this.doRemoveNoZeroDelimiterLengths = false,
      this.doFixPaddingErrors = false,
      this.doRemoveFragments = false});

  static const kNoChange = const WriteParameters(
      doConvertUndefinedLengths: false,
      doRemoveNoZeroDelimiterLengths: false,
      doFixPaddingErrors: false,
      doRemoveFragments: false);

  static const kCanonical = const WriteParameters(
      doConvertUndefinedLengths: true,
      doRemoveNoZeroDelimiterLengths: true,
      doFixPaddingErrors: true,
      doRemoveFragments: true);
}
