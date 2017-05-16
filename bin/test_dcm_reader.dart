import 'dart:io';

import 'package:common/logger.dart';


import 'package:convertX/dicom_no_tag.dart';
import 'package:convertX/src/dicom_no_tag/byte_dataset.dart';

void main() {
    String path0 = 'C:/odw/sdk/test_tools/test_data/TransferUIDs'
        '/1.2.840.10008.1.2.5.dcm';
    final Logger log = new Logger('dcm_reader_test.dart', watermark: Severity
        .debug);

    //    Uid uid = new Uid();
    File file = new File(path0);
    RootByteDataset rds = DcmReader.readFile(file);
    log.debug('${rds.info}');
    //    Subject subject = new Subject(rds);
    //    Study stu = new Study(subject, uid, rds);
    //    Series ser = new Series(stu, uid, rds);
    //    Instance inst = new Instance(ser, uid, rds);
    //    Instance inst1 = new Instance(ser, uid, rds);
    //    Instance instance = Instance.fromDataset(rds);
    //    log.debug('${instance.info}');
    //    expect(inst == inst1, true);
    //    expect(inst.hashCode == inst1.hashCode, true);
}
