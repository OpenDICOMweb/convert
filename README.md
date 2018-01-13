Open DICOM<em>web<em> SDK
## Convert
Version: 0.5.1

**Note**: _This is a work in progress and not complete._

An Open DICOMweb package providing encoders/decoders for converting
between different DICOM representations (media types) to the Open
DICOMweb in-memory Study model.

### Supported Media Types and Codecs

* application/dicom (DicomCodec)
* application/dicom+json (DicomJsonCodec)
* application/dicom+xml (DicomXmlCodec - future?)


### Default Top-Level Encoders/Decoders

* Dicom.encode and Dicom.decode
* DicomJson.encode and DicomJson.decode (TBD)
* DicomXml.encode and Dicom.xml.decode (TBD)
* HTML.encode (TBD)

## Libraries

This package contains the following libraries:

* [bytebuf] - Reading/writing data from/to a byte stream.
* [dicom] - A DICOM media type (binary) encoder/decoder.
* [dicom+json] - A DICOM+JSON media type encoder/decoder

In Progress

* [mint] - A MINT media type encoder/decoder
* [mint+json] - A MINT+JSON media type encoder/decoder
* [mint+html] - A MINT+HTML media type encoder



### Usage

A simple usage example:

    import 'package:dcm_convert/convert.dart';


    // Read binary DICOM file and decode into Study Model
    List<int> bytes = new File('foo.dcm').readAsBytes();
    Study study = Dicom.decode(bytes);

    // Encode Study model into JSON and write to file
    List<int> json = DicomJson.encode(study);
    new File('foo.json').writeAsBytes(json);

### _TODO_

* DICOM+JSON Encoder/Decoder
* MINT Encoder/Decoder
* MINT+json Encoder/Decoder
* MINT+HTML

### Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[bytebuf]:  https://github.com/OpenDICOMweb/convert/blob/master/lib/bytebuf.dart
[dicom]:  https://github.com/OpenDICOMweb/convert/blob/master/lib/dicom.dart
[dicom+json]:  https://github.com/OpenDICOMweb/convert/blob/master/lib/dicom_json.dart
[mint]:  https://github.com/OpenDICOMweb/convert/blob/master/lib/mint.dart
[mint+json]:  https://github.com/OpenDICOMweb/convert/blob/master/lib/mint_json.dart
[mint+html]: https://github.com/OpenDICOMweb/convert/blob/master/lib/mint_html.dart
[tracker]: https://github.com/OpenDICOMweb/convert/issues
