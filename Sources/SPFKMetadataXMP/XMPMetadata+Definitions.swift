// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/SPFKMetadataXMP

extension XMPMetadata {
    /// https://www.adobe.io/xmp/docs/XMPNamespaces/
    enum Element: String {
        /// https://www.w3.org/TR/rdf-syntax-grammar/
        case rdf = "rdf:RDF"
        case description = "rdf:Description"

        case bag = "rdf:Bag"
        case li = "rdf:li"
        case seq = "rdf:Seq"
        case alt = "rdf:Alt"

        /// Adobe XMP Basic namespace
        case creatorTool = "xmp:CreatorTool"
        case createDate = "xmp:CreateDate"

        /// XMP Dynamic Media namespace
        /// https://www.adobe.io/xmp/docs/XMPNamespaces/xmpDM/

        case audioChannelType = "xmpDM:audioChannelType"
        case audioSampleRate = "xmpDM:audioSampleRate"

        case videoFrameRate = "xmpDM:videoFrameRate"
        case videoFieldOrder = "xmpDM:videoFieldOrder"

        // https://www.adobe.io/xmp/docs/XMPNamespaces/XMPDataTypes/Track/
        case tracks = "xmpDM:Tracks"
        case markers = "xmpDM:markers"

        case trackType = "xmpDM:trackType"
        case trackName = "xmpDM:trackName"

        case startTimecode = "xmpDM:startTimecode"

        case startTimeScale = "xmpDM:startTimeScale"

        case startTimeSampleSize = "xmpDM:startTimeSampleSize"

        case duration = "xmpDM:duration"

        /// A timecode set by the user. When specified, it is used instead of the startTimecode.
        case altTimecode = "xmpDM:altTimecode"

        case title = "dc:title"

        enum Timecode: String {
            case timeFormat = "xmpDM:timeFormat"
            case timeValue = "xmpDM:timeValue"
        }

        /*
         <xmpDM:duration rdf:parseType="Resource">
             <xmpDM:value>77077</xmpDM:value>
             <xmpDM:scale>1/24000</xmpDM:scale>
         </xmpDM:duration>

         https://www.adobe.io/xmp/docs/XMPNamespaces/XMPDataTypes/Time/
         */
        enum Time: String {
            case value = "xmpDM:value"
            case scale = "xmpDM:scale"
        }

        enum Marker: String {
            /// Comment, Chapter
            case type = "xmpDM:type"
            case name = "xmpDM:name"
            case comment = "xmpDM:comment"
            case startTime = "xmpDM:startTime"
            case duration = "xmpDM:duration"
        }
    }
}
