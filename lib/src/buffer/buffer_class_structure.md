# ByteList Class Structure

## Mixins
- ByteListGetMixin
- ByteListSetMixin
- UnmodifiableByteListMixin

## ByteList

- ByteListBase
    - UnmodifiableByteList 
      extends ByteListBase with UnmodifiableByteListMixin, ByteListGetMixin
 
        - ReadBuffer
        - LoggingReadBuffer
        - DicomReadBuffer
            - EvrReader
                - EvrBDReader
                - EvrTagReader
            - IvrReader
                - IvrBDReader
                - IvrTagReader               
        - LoggingDicomReadBuffer
            - LoggingEvrReader
                  - LoggingEvrBDReader
                  - LoggingEvrTagReader
            - LoggingIvrReader
                  - LoggingIvrBDReader
                  - LoggingIvrTagReader

    - ByteList
      extends ByteListBase with ByteListGetMixin, ByteListSetMixin
        
    - GrowableByteList
      extends ByteListBase with ByteListGetMixin, ByteListSetMixin

        - WriteBuffer
        - LoggingWriteBuffer
        - DicomWriteBuffer
            - EvrWriter
                - EvrBDWriter
                - EvrTagWriter
            - IvrWriter
                - IvrBDWriter
                - IvrTagWriter               
        - LoggingDicomWriteBuffer
            - LoggingEvrWriter
                  - LoggingEvrBDWriter
                  - LoggingEvrTagWriter
            - LoggingIvrWriter
                  - LoggingIvrBDWriter
                  - LoggingIvrTagWriter
    - UnmodifiableByteList



ByteList
    GrowableByteList
        WriteBuffer

            LoggingWriteBuffer
        DicomWriteBuffer
            LoggingDicomByteBuffer
