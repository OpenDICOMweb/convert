# Package Design Notes

Convert is a package that encodes/decodes different DICOM media types.
## General Principle

_The Entities, Datasets, and Elements that result from decoding the same Study, Series, or Instance should be exactly the same._

### Specific Notes

1. Anything that is related only to the media type should be handled by the encoder/decoder.

    Examples include:

    - VR
    - Value Field Padding for 2-byte boundary
    - Pixel Data Fragments

2. Decoders should remove any padding from Value Fields.

3. Encoders should add any padding to Value Fields.

