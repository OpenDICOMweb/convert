# DICOM APath
Ordered keypath-value representation of DICOM instances for big data and machine learning

## Background

The DICOM binary metadata format improves the basic key/value paradigma in three ways:

* attributes are ordered within lists in function of 4-byte tags identifying each attribute.
* an attribute can be multivalued,
* an attribute can be the root of an array of enclosed ordered lists of attributes

A translation of the binary model to XML facilitated the discrete access to any attribute of the root ordered list,
or of enclosed ones, thanks to XPath. The XML schema also introduced an alternative indexing by means of keywords,
which are not ordered alphabetically within the ordered list.

Another translation of the binary model to JSON simplified the parsing of subsets of metadata in QIDO
responses using ecmascript (javascript) and the many other languages which support maps (also called
associative array, or dictionary).

Both the XML and JSON translations are text-based representations derived from the explicit binary syntax.
They replace the binary structuring glue (prefix, signature, group length, value length, paddings, item
and sequence beginning and end tags, etc) by textual markup.

Data typing is also simplified with the use of generic text-based types: UTF-8 string, base64 ascii
string and number, instead of the variety of data types in the DICOM binary representation. The original
data type initials are written as a property of the attribute in order to facilitate backward translation
to the binary representation. This is why we stated earlier that XML and JSON traductions are derived from
the explicit binary syntax.

No doubt these new representations were a great improvement for human readability and use over the web.

But on the other hand, text tags and keywords, text markup, the additional layer of JSON object description
and generic datatypes are counter productive for big data and machine learning tasks, which are performed
orders of magnitude faster on size- and indexation- optimized flat keypath-value ordered lists.

With big data and machine learning in mind, and also pacs design, we postulate the creation of a new
representation of DICOM instances as an ordered flat list of keypath-value pairs. We call it "APath"
(Attribute Path). The asonance of "APath" with "XPath" is on purpose.

The APath representation can be translated back and forth from and to binary, XML and JSON representations.

## Tags in ascending order
In DICOM representations, the attributes shall be ordered in tag ascending order. This rule is currently
originating very few benefits:

* group 2 comes first,
* text encoding of the root dataset is defined before any other attributes,
* pixels come last.

In a serialization of these representations, the order is disrupted by the enclosure of encapsulated
ordered lists containing attributes of lower tag than the current tag in the root list.

The benefits associated to the ascending order of tags of attributes can only be ripped after parsing a
DICOM serialized object and creating in memory related structures for each of the root and enclosed dataset,
as is the case when using XPath.

The requirement of ascending order of tags of attributes is excelent for fast discrete access to attributes
or range of attributes. We just need to define a representation which makes the better use of it than the
existing ones. This occurs when we replace the tag of an attribute by a tag path, that is a concatenation
of the context tags, at the left, with the actual attribute tag. We call this APath (=AttributePath).

### ASCII tag path
The tag paths in APath can be written in ASCII or in binary. An ASCII tag path is represented as follows:

* Encapsulated attributes are treated in accordance to the DICOM QIDO-RS filter format, which defines
aaaaaaaa.bbbbbbbb as the attribute designed by tag bbbbbbbb included in the (first) item of sequence
designed by tag aaaaaaaa;
* aaaaaaaa.bbbbbbbb represents the complex concept of the attribute, but not its place within an item
or a list of values. We append the latter information with a "$" (dollar) after the conceptual part.
For instance aaaaaaaa.bbbbbbbb$2.1 means the first value of attribute bbbbbbbb of item 2 of the sequence aaaaaaaa;
* If the attribute contains a numeric array, we do not repeat the complete tagpath for each of the
items of the array. Instead we use one tagpath terminated by an asterisk instead of the index of the value.
For instance aaaaaaaa.bbbbbbbb$2.* means all the values of attribute bbbbbbbb of item 2 of the sequence aaaaaaaa;
* In most cases the sequence contains a unique item containing a monovalued attribute. For them, the
appendix may be omitted. For instance aaaaaaaa.bbbbbbbb equals aaaaaaaa.bbbbbbbb$1.1;
* The data type may be appended with a "~" (tilde). The information relative to the datatype comes last,
after the conceptual part and the eventual positional part. This appendix is optional, unless:

    * the attribute is an empty sequence,
    * the attribute is an empty item,
    * the attribute in the dictionary DICOM supports more than one data type,
    * the attribute is not present in the dictionary DICOM.

* The sequence start tag only appears as a placeholder for empty sequence. Else it doesn't appear. It is
represented with a zero in the positional part, a datatype "SQ" and a corresponding null value. For instance,
aaaaaaaa$0~SQ . This markup is necessary in order to register an empty sequence type 2.
* In the same way, an empty item start tag is represented with its item number in the positional part,
followed by the datatype "SQ" and corresponding null value. For instance, aaaaaaaa$1~SQ (1 being the number
of the item).

### some reflexions on the ASCII tag path
* The tag path relates the attribute not only to its syntactical definition in part 6 of the standard, but also
to its complete semantics (including participation in Information Object Definition, Information Element and
Module of Information) as defined in part 3 of the standard.

* The URL safe and URL sub-delim characters which were chosen allow the use of a tag path without
escaping within an URL.

* The ASCII value of the separators and alphanumeric segments make sure that when a clasification occurs,
the primary conceptual and secundary positional orders are respected both at the same time in the tag path.

* A DICOM instance is represented in APath as one flat indexed collection. This allows the use of very efficient
algorithms, including binary tree, in the search of a specific attribute.

### ASCII tag path range
The tag path range is the primitive way to use tag-paths in filters.

* "-" (hyphen) articulates the lower and upper boundaries of a range of tag-paths.
* ".+" (dot plus) at the end of the conceptual part of an upper boundary limit pushes the limit up to the
highest possible tag path sharing that root. For instance -aaaaaaaa.+ is an upper boundary which will include
aaaaaaaa.bbbbbbbb
* When there is nothing after the hyphen or no hyphen at all, the parser creates an implicit upper bound
equal to the lower one followed by ".+"

00100010 is equal to 00100010.+ This include every posible tag-path pointing to the patient name

    * 00100010 (concept)
    * 00100010$1 (concept+position)
    * 00100010$1~PN (concept+position+datatype)
    * 00100010~PN (concept+datatype)

* .+ alone means a range including all tag-paths of the dataset.

It is worth observing that this syntaxis is regex-friendly. All but the dots are normal characters.
Dot represents any character at this position in the tag-path. Dot plus captures everything.

### Binary tag path
The ASCII tag path can be represented in a savvy binary variant.

* Simple tag path are represented by one or more sequence(s) of 4 bytes. For instance, 00101002.00100020
would be represented by the bytes 0x00 0x10 0x10 0x02 0x00 0x10 0x00 0x20. This representation is independent
of big or little endings which apply to short of long numeric values.
* In case the tag path also contains a positional part, we append a byte 0xFF and then the positional part as
one or more sequence(s) of 4 bytes, Each of the groups of 4 bytes correspond to the same group in the conceptual
part and is written as big endian 4 bytes unsigned integer, that is with the most significative bytes first.
* If the tag path ends with the datatype, the binary variant ends also with the two bytes corresponding to the
ascii representation of the datatype.

This binary variant allows clasification performed on the whole tag path read from left to right without the
need to pay attention to what belongs to the conceptual part, positional part or datatype one. There is also
no need to invert the order of any group of bytes (because we write the positional part using big endian order.

The length of the binary variant tag path indicates the presence or not of the positional and datatype parts.
After division by 4:

* modulo 0 indicates that it is purely conceptual
* modulo 1 indicates that half of it is conceptual and half of it is positional (with a 0xFF inbetween)
* modulo 2 indicates that it is conceptual and ends with two bytes informing of the data type
* modulo 3 indicates that it ends with two bytes informing of the data type and is made of two parts
separated by FF for the conceptual and positional information in the tag-path.

## Values
value formats follow Table F.2.3-1. DICOM VR to JSON Data Type Mapping of the DICOM standard, with one
exception: PN, which components are represented in only one string made of segments separated by ^ and =.

## API REST and backend server
APath representation optimized for big data is specified as a generic API made of commands REST con JSON
objects which can easily drive key-value databases. It should be possible to use other types of datastore
backends, but it is supposed that performance would be orders of magnitude faster when the backend is an
ordered key-value database.[[Key-Value databases]](https://github.com/jacquesfauquex/APath/wiki/Key-value-databases)

HTTP methods GET and HEAD are provided to communicate with the key-value database. We also define a method
POST for higher level functions scripts composing atomic GET and HEAD functions to be executed on the server.

### GET
HTTP GET is the basis for actual WADO-RS and QIDO-RS command:

* RetrieveStudy, RetrieveSeries, RetrieveInstance,RetrieveFrame,
* RetrieveBulkdata,
* RetrieveStudyMetadata, RetrieveSeriesMetadata, RetrieveInstanceMetadata,
* RetrieveStudyRendered, RetrieveSeriesRendered, RetrieveInstanceRendered, RetrieveFramesRendered,
* SearchForStudies, SearchForSeries, SearchForInstances

The new GET extends the current QIDO-RS functionality on returned attributes. With the new functionality, it
is posible to return a list of attributes limited to the ones specified in the request (can be cero or more,
a module, or even a complete instance as in a WADO command). The new GET is called with the suffix "/attributes"
appended to the corresponding QIDO-RS path:

* <SERVICE>/studies/attributes?
* <SERVICE>/studies/{StudyInstanceUID}/series/attributes?
* <SERVICE>/series/attributes?
* <SERVICE>/studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/attributes?
* <SERVICE>/studies/{StudyInstanceUID}/instances/attributes?
* <SERVICE>/instances/attributes?

The "Accept" parameter is not necessary in the headers of the request and not taken into account for the response,
which is always Media Type "application/json".

All the parameters are as in QIDO-RS, except for "includefield" which is not allowed. One or two parameters replace
it, eventually:
- "list=" followed by one or more APaths or APath ranges separated with a coma
- "module=" followed by the name of one or more modules, "QIDO-RS", "private", ...

To the parameters "offset" and "limit", we add a parameter "orderby", which accepts an unique Path.

A parameter "dict", which value should be "true", allows to switch on the presence of the "dict" object in the answer.

The response includes:
- a status 204 when no object matching the search filters is found, or 200 in the other case
- a parameter "X-total-count" in the header which contains the total count of items filtered.
- a body made of a unique json object.

### GET response body
The JSON response object is an object made of:

- req, which repeats the request url invoked witout the offset and limit parameters
- resp indicates the range of matches returned, the total count of matches and the request uri for the next page.
- data contains the data of the matches
- dict contains vr, keyword and eventually other information (module, etc) corresponding to the tag paths used
within the data

data in turn contains two or more parallel arrays. Same index items in these arrays correspond to a same dicom
object. The array uids is the reference of the object by means of its uids. If the objects of the response are
studies, the array will contain StudyInstanceUIDs.  If the objects of the response are series,  the array will
contain a composition of StudyInstanceUID and SeriesInstanceUID. If the objects of the response are SOP instances,
the array will contain a composition of StudyInstanceUID, SeriesInstanceUID and SOPInstanceUID.
Data second and following parallel array(s) is(are) either an array called list (corresponding to parameter list
or arrays called moduleX, moduleY, ... (corresponding to one item of the parameter module). These arrays list
or moduleX, moduleY, ... contain one JSON object for each of the DICOM objetcs in the response. The JSON object
is made of two parallel arrays called apath and value which list the attributes and their corresponding values.

The values can be:

- string
- number
- array (in the case of attributes with list of numeric values)
- null (in the case of attribute without value)
- object (in the case of BulkdataURI)

```
{
    "req":  {
        "uri": "http://",
        "date": isodate
    },
    "resp": {
        "offset": 1,
        "limit": 20,
        "count": 100,
        "next": "http://",
        "date": isoDate
    },
    "data": {
        "uids": [
            "studyUID_seriesUID_instanceUID"
        ],
        "list": [
            {
                "apath": [
                    "aaaaaaaa.bbbbbbbb",
                    "cccccccc$.~FD",
                    "dddddddd",
                    "eeeeeeee"
                ],
                "value": [
                    "X^Y",
                    [ 6.5454 , 6.4343 ],
                    null,
                    {"bulkdataURI": "http://"}
                ]
            }
        ],
        "module1": [
            {
                "apath": [],
                "value": []
            }
        ]
    },
    "dict": {
        "tag": ["00100010"],
        "vr": ["PN"],
        "key": ["PatientName"]
    },
    "err": {
        "client": "",
        "server": ""
    }
}
```

### HEAD
Has the same behaviour as GET and also the same response status 200 or 204, but the body is not appened to
the response.

### POST
Sometimes one needs to combine various GET together with conditional and loop logics. If this process is
performed on the server side before returning a unique response to the client, everything is faster and
safer (less information passes through the web). So we use POST to send a script from the client to the
server for execution before receiving an unique response with the data generated by the execution of the
script. [[POST ecmascript]](https://github.com/jacquesfauquex/APath/wiki/POST-ecmascript)

This command is called with the suffix /script instead of /attributes.

* <SERVICE>/studies/script?
* <SERVICE>/studies/{StudyInstanceUID}/series/script?
* <SERVICE>/series/script?
* <SERVICE>/studies/{StudyInstanceUID}/series/{SeriesInstanceUID}/instances/script?
* <SERVICE>/studies/{StudyInstanceUID}/instances/script?
* <SERVICE>/instances/script?

It supports QIDO-RS query parameters ( except for "includefield"). These parameters define the scope allowed
for commands inside the script. No "list" or "module" query parameter is accepted, since these will be present
in the script itself.

A carefull implementation of this service would obviously integrate a PEP (Policy Enforcement Point) or WAF
(Web Application Firewall) as first responder before real processing is performed. The context limited to a
study or a series, or an instance would be a criteria for the evaluation of the authorization. The commands
GET and HEAD inside the ecmascript would not be authorized to reach any resource not authorized by the context
and the QIDO-RS query filter attached to it.

The media type of the POST is "application/ecmascript"

The "Accept" parameter of the request defines the media-type of the response. When "Accept" is not specified,
application/json is the default media-type of the response and returns the data in the format of the GET response.

But the server may accept other media-types in the "Accept" parameter. For instance, it may return a text/xml
a application/dicom+json, a text/html or whatever type the script is able to create.

## COMUNICATION  USE CASES solved with APath

* **discrete access to any attribute of any instance** -> APath syntaxis
* **access to DICOM modules** -> predefined modules in the request
* **versatility of the inclusion of the request in heterogeneous development platform** -> HTTP GET URI format
 without headers nor body
* **easy parsing of the response**  -> one unique json object for responses with attributes found, with no
attributes found, or with error
* **potentially huge response** -> paging from equipotent source using offset and limit like in qido, but
adding also count of the total filtered entries.
* **posibility to continue an aborted loop of requests of page from where it stopped** -> the information
in the object resp makes posible an audit of which pages were downloaded and which ones are lacking.
* **possibility to aggregate the responses of various servers to the same request into one ordered set**