<strong>Open DICOM<em>web</em> Project</strong>

# Checking and Converting Value Representations

DICOM Value Representations (VR) define the valid values for an Element. VRs
correspond to Data Types in programming languages.

Each DICOM _Tag_ defines the _Value Representations_ (VR) that are valid
for it. Almost all Tags define a single valid VR. These Tags are called
_NormalVR_ Tags. For these Tags, checking Elements for a valid VR requires
a simple comparison. If the Tag VR is the same as the Element VR, then
the Element has a valid VR.

However, a few Tags define multiple VRs that are valid. These Tags are
called _SpecialVR_ Tags. For SpecialVR Tags, checking Elements for a
valid VR requires comparing the Element's VR with each of the Tag VRs.
If the Element VR matches one of the Tag VRs, then the Element has a
valid VR.

Finally, there is the _Unknown_ VR (UN), that is valid for any Tag. If
a Tag has a VR of UN then it is valid by definition. This VR is equivalent
to the _Object_ type in many programming languages. In that sense UN
is a super VR. All other VRs are a subtype of this VR.

Elements with VR UN are problematic. While the Element  is valid by
definition, it contains no information about the validity of the values.
UN conveys no information about the type of values contained in the
Element. The values might be integers, floating point numbers, or strings.

DICOM does not defined any Tags with a UN of VR.

The following is a simple algorithm for determining that an Element
has a valid VR. The variables

    bool checkVR(Tag tag, Element e) {
      if (e.vr == UN) return true;
      if (tag is TagNormal && e.vr == tag.vr) return true;
      if (tag is TagSpecial && tag.vr.contains(e.vr) return true;
      return false;
    }
or written more simply:

    bool checkVR(Tag tag, Element e) {
      if ((e.vr == UN ||
         (tag is TagNormal && e.vr == tag.vr) ||
         (tag is TagSpecial && tag.vr.contains(e.vr))) return true;
      return false;
    }

### Special VRs

There are only four types of SpecialVRs:

1. OB or OW
    - Different type
    - Same element size - 1 vs 2
    - Same Value Field Length field size - 4
    - Same maximum Value Field Length - 2^31 - 2
2. US or SS
    - Different type
    - Same element size - 2
    - Same Value Field Length field size - 2
    - Same maximum Value Field Length - 2^16
3. US or OW
    - Same type
    - Same element size - 2
    - Different Value Field Length field size - 2 vs 4
    - Different maximum Value Field Length - 2^16 vs 2^31-2
4. US or SS or OW
    - Different type
    - Same element size - 2
    - Different Value Field Length field size - 2 vs 2 vs 4
    - Different maximum Value Field Length - 2^16 vs 2^16 vs 2^31-2

Notice that these are all Integer VRs, but each one represents

## Converting the Value Representations

There are several cases where a parser may want to convert the VR
of an Element:

    1. If the Element VR is UN and The Tag is a NormalVR Tag, then
       the parser might want to convert the Element to the stronger
       VR defined by the Tag.

    2. If the Element VR is UN and The Tag is a SpecialVR Tag, then
       the parser should leave the Element VR as UN, because it
       cannot determine a stronger UN.

    2. If the Tag is a SpecialVR Tag and the Element VR is invalid
       then the converter has a choice of either:

        - Do not change Element VR, or
        - Change the Element VR to UN.

## Specific Tags

(0018,9810), Zero Velocity Pixel Value, ZeroVelocityPixelValue, USSS, 1
(0022,1452), Mapped Pixel Value, MappedPixelValue, USSS, 1
(0028,0071), Perimeter Value, USSS, 1, RET
(0028,0104), Smallest Valid Pixel Value, SmallestValidPixelValue, USSS, 1, RET
(0028,0105), Largest Valid Pixel Value, USSS, 1, RET
(0028,0106), Smallest Image Pixel Value, USSS, 1
(0028,0107), Largest Image Pixel Value, USSS, 1
(0028,0108), Smallest Pixel Value in Series, USSS, 1
(0028,0109), Largest​Pixel​Value​In​Series, USSS, 1
(0028,0110), Smallest​Image​Pixel​Value​In​Plane, USSS, 1, RET
(0028,0111), Largest Image Pixel Value in Plane, US or SS, 1, RET
(0028,0120), Pixel Padding Value, US or SS, 1
(0028,0121), Pixel Padding Range Limit, US or SS, 1
(0028,1100)
Gray Lookup Table Descriptor
US or SS
3
RET
(0028,1101)
Red Palette Color Lookup Table Descriptor
US or SS
3
(0028,1102)
Green Palette Color Lookup Table Descriptor
US or SS
3
(0028,1103)
Blue Palette Color Lookup Table Descriptor
US or SS
3
(0028,1104)
Alpha Palette Color Lookup Table Descriptor
US
3
(0028,1111)
Large Red Palette Color Lookup Table Descriptor
US or SS
4
RET
(0028,1112)
Large Green Palette Color Lookup Table Descriptor
US or SS
4
RET
(0028,1113)
Large Blue Palette Color Lookup Table Descriptor
US or SS
4
RET

