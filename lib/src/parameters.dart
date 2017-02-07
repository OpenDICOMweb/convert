// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Author: Jim Philbin <jfphilbin@gmail.edu> -
// See the AUTHORS file for other contributors.

//TODO: implement these for all conversions
/// A Set of parameters passed to a converter.
class Parameters {
  final bool allowWhiteSpaceTrimming = false;
  final bool padToEvenLength = true;
  final bool allowAttributeModification = false;
  final bool includeOriginalAttributesSequence = true;
}
