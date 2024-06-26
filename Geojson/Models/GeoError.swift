//
//  GeoError.swift
//  Geojson
//
//  Created by Jack Finnis on 08/05/2023.
//

import Foundation
import CoreGPX
import RCKML
import AEXML

enum GeoError: Error {
    case fileType
    case fileMoved
    case fileCurrupted
    case fileEmpty
    case geoJSON
    case kml(KMLError)
    case aexml(AEXMLError)
    case nsxml(XMLParser.ErrorCode?)
    case gpx(Error)
    
    var message: String {
        switch self {
        case .fileType:
            return "Only following file types can be imported:\n\(GeoFileType.allFileExtensions.map { "." + $0 }.joined(separator: ", "))"
        case .fileMoved:
            return "This file has been moved or deleted. Please try importing it again."
        case .fileCurrupted:
            return "This file has been corrupted. Please try importing it again."
        case .fileEmpty:
            return "This file does not contain any points, lines or polygons."
        case .geoJSON:
            return "This file contains invalid geojson."
        case .kml(let error):
            return error.description
        case .aexml(let error):
            return "Unable to parse this KML file: \(error.description)"
        case .nsxml(let error):
            let message = error == nil ? "Unknown error code." : "Error code \(error!.rawValue)."
            return "Unable to parse this KML file: " + message
        case .gpx(let error):
            return handleGPXError(error)
        }
    }
    
    var fileType: GeoFileType? {
        switch self {
        case .geoJSON:
            return .geojson
        case .kml(_), .aexml(_), .nsxml:
            return .kml
        case .gpx(_):
            return .gpx
        default: return nil
        }
    }
    
    func handleGPXError(_ error: Error) -> String {
        if let error = error as? GPXError.coordinates {
            switch error {
            case .invalidLatitude(let dueTo):
                switch dueTo {
                case .underLimit:
                    return "This file contains a latitude under -90˚"
                case .overLimit:
                    return "This file contains a latitude over 90˚"
                }
            case .invalidLongitude(let dueTo):
                switch dueTo {
                case .underLimit:
                    return "This file contains a longitude under -180˚"
                case .overLimit:
                    return "This file contains a longitude under 180˚"
                }
            }
        } else if let error = error as? GPXError.parser {
            switch error {
            case .unsupportedVersion:
                return "This GPX file is of an unsupported version number."
            case .issueAt(let line, let error):
                return "This GPX file contains an error at line \(line): \(error.localizedDescription)"
            case .fileIsNotGPX:
                return "This file contains invalid GPX data."
            case .fileIsNotXMLBased:
                return "This file contains invalid GPX data."
            case .fileDoesNotConformSchema:
                return "This file contains invalid GPX data."
            case .fileIsEmpty:
                return "This file is empty."
            case .multipleErrorsOccurred(let errors):
                return errors.map(handleGPXError).joined(separator: " ")
            }
        } else {
            return "This file contains invalid GPX data."
        }
    }
}

extension KMLError {
    var description: String {
        switch self {
        case .xmlTagMismatch:
            return "This KML file contains an xml type mismatch."
        case .coordinateParseFailed:
            return "This KML file contains an invalid coordinate."
        case .missingRequiredElement(let elementName):
            return "This KML file is missing a required element: \(elementName)."
        case .unknownFileExtension(let fileExtension):
            return "This KML file has an invalid extension: \(fileExtension)."
        case .kmzReadError:
            return "This file contains invalid KML data."
        case .kmzWriteError:
            return "This file contains invalid KML data."
        case .couldntConvertStringData:
            return "This file contains invalid KML data."
        }
    }
}

extension AEXMLError {
    var description: String {
        switch self {
        case .elementNotFound:
            return "Element not found."
        case .rootElementMissing:
            return "Root element missing."
        case .parsingFailed:
            return "Parsing failed."
        }
    }
}
