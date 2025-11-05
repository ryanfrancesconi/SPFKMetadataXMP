// Copyright Ryan Francesconi. All Rights Reserved. Revision History at https://github.com/ryanfrancesconi/SPFKMetadataXMP

import AEXML
import CoreMedia
import Foundation
import OTCore
import SPFKMetadataXMPC
import SPFKTime
import SPFKUtils
import TimecodeKit

public struct XMPMetadata: Equatable {
    public static func == (lhs: XMPMetadata, rhs: XMPMetadata) -> Bool {
        lhs.frameRate == rhs.frameRate &&
            lhs.markers == rhs.markers &&
            lhs.nominalFrameRate == rhs.nominalFrameRate &&
            lhs.audioSampleRate == rhs.audioSampleRate &&
            lhs.audioChannelType == rhs.audioChannelType &&
            lhs.videoFrameSize == rhs.videoFrameSize &&
            lhs.videoFieldOrder == rhs.videoFieldOrder &&
            lhs.startTimecodeResolved == rhs.startTimecodeResolved &&
            lhs.trackName == rhs.trackName &&
            lhs.trackType == rhs.trackType
    }

    public private(set) var document: AEXMLDocument

    /*
     <dc:title>
         <rdf:Alt>
             <rdf:li xml:lang="x-default">HELLO</rdf:li>
         </rdf:Alt>
     </dc:title>
     */
    public var title: String?

    public var frameRate: TimecodeFrameRate? {
        startTimecode?.frameRate ?? estimatedFrameRate
    }

    public private(set) var markers: [Marker]?

    /*
     <xmpDM:videoFrameRate>25.000000</xmpDM:videoFrameRate>
     */
    public private(set) var nominalFrameRate: Float?

    private var estimatedFrameRate: TimecodeFrameRate? {
        guard let fps = nominalFrameRate else { return nil }
        return TimecodeFrameRate(fps: fps)
    }

    /*
     <xmp:CreatorTool>Adobe Premiere Pro 2022.0 (Macintosh)</xmp:CreatorTool>
     */
    public private(set) var creatorTool: String?

    /*
     <xmp:CreateDate>2021-12-04T22:13:58Z</xmp:CreateDate>
     */
    public private(set) var createDate: String?

    /*
     <xmpDM:audioSampleRate>48000</xmpDM:audioSampleRate>
     */
    public private(set) var audioSampleRate: Double?

    /*
     <xmpDM:audioChannelType>Stereo</xmpDM:audioChannelType>
     */
    public private(set) var audioChannelType: String?

    /*
     <xmpDM:videoFrameSize rdf:parseType="Resource">
         <stDim:w>1920</stDim:w>
         <stDim:h>1080</stDim:h>
         <stDim:unit>pixel</stDim:unit>
     </xmpDM:videoFrameSize>
     */
    public private(set) var videoFrameSize: CGSize?

    /*
     <xmpDM:videoFieldOrder>Progressive</xmpDM:videoFieldOrder>
     */
    public private(set) var videoFieldOrder: String?

    /*
     the timecode of the first frame of video in the file, as obtained from the device control.

     <xmpDM:startTimecode rdf:parseType="Resource">
         <xmpDM:timeFormat>25Timecode</xmpDM:timeFormat>
         <xmpDM:timeValue>00:00:00:00</xmpDM:timeValue>
     </xmpDM:startTimecode>

     23976Timecode
     24Timecode,
     25Timecode,
     2997DropTimecode (semicolon delimiter),
     2997NonDropTimecode,
     30Timecode,
     50Timecode,
     5994DropTimecode,
     5994NonDropTimecode,
     60Timecode,
     */
    public private(set) var startTimecode: Timecode?

    /*
     A timecode set by the user. When specified, it is used instead of the startTimecode.

     <xmpDM:altTimecode rdf:parseType="Resource">
         <xmpDM:timeValue>00:00:00:00</xmpDM:timeValue>
         <xmpDM:timeFormat>25Timecode</xmpDM:timeFormat>
     </xmpDM:altTimecode>
     */
    private(set) var altTimecode: Timecode?

    public var startTimecodeResolved: Timecode? {
        altTimecode ?? startTimecode
    }

    public private(set) var startTimeScale: CMTimeScale?
    public private(set) var startTimeSampleSize: CMTimeValue?
    public private(set) var duration: TimeInterval?
    public private(set) var trackName: String?
    public private(set) var trackType: String?

    /// Create a XMPMetadata struct by passing it a URL to a file
    /// - Parameter path: the file to open
    public init(url: URL) throws {
        try self.init(path: url.path)
    }

    /// Create a XMPMetadata struct by passing it a path to a file
    /// - Parameter path: the file to open
    public init(path: String) throws {
        guard let xmlString = XMPWrapper.parse(path) else {
            throw NSError(description: "Failed to find an XMP chunk in the file: " + path)
        }

        try self.init(xml: xmlString)
    }

    /// Create a XMPMetadata struct by passing it a XMP xml string
    /// - Parameter xml: a valid xml string
    public init(xml: String) throws {
        let doc = try AEXMLDocument(xml: xml)
        self.init(document: doc)
    }

    /// All Inits go here.
    /// Create a XMPMetadata struct by passing it a valid AEXMLDocument. This isn't an exhaustive parse, but
    /// currently only containing items of interest to us.
    ///
    /// - Parameter doc: an `AEXMLDocument`
    public init(document doc: AEXMLDocument) {
        document = doc

        // <rdf:RDF><<rdf:Description>
        let desc = doc.root[Element.rdf.rawValue][Element.description.rawValue]

        creatorTool = desc[Element.creatorTool.rawValue].value
        createDate = desc[Element.createDate.rawValue].value

        // nominal frame rate as a Float
        if let value = desc[Element.videoFrameRate.rawValue].value?.float {
            nominalFrameRate = value
        }

        // start timecode
        let startTimecodeElement = desc[Element.startTimecode.rawValue]
        if let value = parseTimecode(element: startTimecodeElement) {
            startTimecode = value
        }

        // A timecode set by the user. When specified, it is used instead of the startTimecode.
        let altTimecodeElement = desc[Element.altTimecode.rawValue]
        if let value = parseTimecode(element: altTimecodeElement) {
            altTimecode = value
        }

        audioSampleRate = desc[Element.audioSampleRate.rawValue].value?.double

        audioChannelType = desc[Element.audioChannelType.rawValue].value

        videoFieldOrder = desc[Element.videoFieldOrder.rawValue].value

        // TODO: verify xml DTD spec is always this format
        // tracks location might not be consistent so search for the first occurrence of it
        let trackList = desc.allDescendants { element in
            element.name == Element.tracks.rawValue
        }

        // there can be more than one track
        if let track = trackList.first {
            let list = track[Element.bag.rawValue][Element.li.rawValue]

            trackType = list[Element.trackType.rawValue].value
            trackName = list[Element.trackName.rawValue].value
        }

        // Marker can appear in more than one place
        let markerList = desc.allDescendants { element in
            element.name == Element.markers.rawValue
        }

        var allMarkers = [Marker]()
        for list in markerList {
            if let markerElements = list[Element.seq.rawValue][Element.li.rawValue].all {
                allMarkers += parseMarkers(elements: markerElements) ?? []
            }
        }
        markers = allMarkers

        title = desc[Element.title.rawValue][Element.alt.rawValue][Element.li.rawValue].value

        if let value = desc[Element.startTimeScale.rawValue].value?.int32 {
            startTimeScale = CMTimeScale(value)
        }

        if let value = desc[Element.startTimeSampleSize.rawValue].value?.int32 {
            startTimeSampleSize = CMTimeValue(value)
        }

        let durationElement = desc[Element.duration.rawValue]

        parseDuration(element: durationElement)
    }

    /*
     <xmpDM:duration rdf:parseType="Resource">
         <xmpDM:value>8800</xmpDM:value>
         <xmpDM:scale>1/2500</xmpDM:scale>
     </xmpDM:duration>
     */
    private mutating func parseDuration(element durationElement: AEXMLElement) {
        // Look at this mess
        guard let frameCount = durationElement[Element.Time.value.rawValue].value?.double,
              let scale = durationElement[Element.Time.scale.rawValue].value,
              let frameDuration = CMTimeString.parse(string: scale)?.seconds else {
            return
        }
        duration = frameCount * frameDuration
    }

    private func parseTimecode(element: AEXMLElement) -> Timecode? {
        guard let value = element[Element.Timecode.timeFormat.rawValue].value,
              let timeFormat = TimeFormat(rawValue: value),
              let timeValue: String = element[Element.Timecode.timeValue.rawValue].value else {
            return nil
        }

        guard let timecode = try? Timecode(.string(timeValue), at: timeFormat.frameRate) else { return nil }

        guard timecode.invalidComponents.isEmpty else { return nil }

        return timecode
    }

    /*
     <rdf:li rdf:parseType="Resource">
         <xmpDM:startTime>57</xmpDM:startTime>
         <xmpDM:duration>8</xmpDM:duration>
         <xmpDM:name>h</xmpDM:name>
         <xmpDM:guid>0da28cca-90e6-410f-92f7-ecc84f8bccb6</xmpDM:guid>
         <xmpDM:cuePointParams>
             <rdf:Seq>
                 <rdf:li rdf:parseType="Resource">
                     <xmpDM:key>marker_guid</xmpDM:key>
                     <xmpDM:value>0da28cca-90e6-410f-92f7-ecc84f8bccb6</xmpDM:value>
                 </rdf:li>
             </rdf:Seq>
         </xmpDM:cuePointParams>
     </rdf:li>
     */
    private mutating func parseMarkers(elements: [AEXMLElement]) -> [Marker]? {
        guard let frameRate else {
            Log.error("didn't find a frame rate in xmp data, so unable to setup timing for markers")
            return nil
        }

        var out = [Marker]()

        for element in elements {
            guard let mFrame = element[Element.Marker.startTime.rawValue].value?.int
            else { continue }

            let mName = element[Element.Marker.name.rawValue].value ?? ""
            let mDuration = element[Element.Marker.duration.rawValue].value?.int ?? 0
            let mComment = element[Element.Marker.comment.rawValue].value ?? ""

            let marker = Marker(
                name: mName,
                comment: mComment,
                startFrame: mFrame,
                durationInFrames: mDuration,
                frameRate: frameRate
            )
            out.append(marker)
        }
        return out
    }
}
