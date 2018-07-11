## TODO

1.	Read/write byte and compare byte for byte
2.	Add coerce function to convert blanks to empty list for all elements
3.	When converting from byte to tag trim all whitespace.
4.	Build Validator for Byte Datasets
5.	Define private creator & private data format
   a.	Creator (gggg,00cc): [token, group, default subgroup] 
   b.	Data (gggg,ccdd):
       [creator, group, index, keyword, name, vr, vm, isRetired, type, condition] 
6.	Test removeAllPrivate
7.	Test removeSafePrivate
8.	Test remove group
 
0. Look for de-identified tag and allow looser verification.
1. Add DICOM+JSON
2. Add MINT+JSON
3. Cleanup or remove examples
4. Move Compare files and Compare Bytes elsewhere
5. Change to standard 'dart:convert' format
6. Create an abstract classes BufferBase, DecodeBufferBase, and DecoderBase
7. Create an abstructure structure like:
    1. bufferBase
    2. ReaderBase
    3. WriterBase
    4. ReaderWriterBase
 

