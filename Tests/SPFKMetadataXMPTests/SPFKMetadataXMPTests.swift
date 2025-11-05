import Foundation
import SPFKTesting
import Testing

let resources = BundleResources(bundleURL: Bundle.module.bundleURL)

func xml(named name: String) throws -> String {
    let url = resources.resource(named: name)
    return try String(contentsOf: url, encoding: .utf8)
}
