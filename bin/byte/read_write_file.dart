// Copyright (c) 2016, Open DICOMweb Project. All rights reserved.
// Use of this source code is governed by the open source license
// that can be found in the LICENSE file.
// Original author: Jim Philbin <jfphilbin@gmail.edu> -
// See the   AUTHORS file for other contributors.

import 'package:common/common.dart';
import 'package:dcm_convert/data/test_files.dart';

//TODO: fix logger so next two import and the DcmReader lines are not necessary
import 'package:dcm_convert/src/dcm/dcm_reader.dart';
import 'package:dcm_convert/src/dcm/dcm_writer.dart';
import 'package:dcm_convert/src/dcm/byte_read_utils.dart';

String outPath = 'C:/odw/sdk/convert/bin/output/out.dcm';

void main() {
  //TODO: fix logger so next two lines are unnecessary
  DcmReader.log.watermark = Severity.debug2;
  DcmWriter.log.watermark = Severity.debug2;

  // *** Modify the [path0] value to read/write a different file
  var path = 'C:/odw/test_data/6688/12/0B009D38/0B009D3D/4D4E9A56';

  byteReadWriteFileChecked(path);
}
