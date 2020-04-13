import Foundation

extension RangeReplaceableCollection {
    mutating func removeFirst(where predicate: (Element) -> Bool) -> Element? {
        for index in indices {
            let element = self[index]
            if predicate(element) {
                remove(at: index)
                return element
            }
        }
        return nil
    }
}

public struct Cassette {

    // MARK: - Initializers

    public init(har: HTTPArchive) {
        self.har = har
    }

    // MARK: - Properties

    private var har: HTTPArchive

    // MARK: - Functions

    mutating func removeFirstInteractionForRequest(_ request: URLRequest) -> Interaction? {
        guard let entry = har.log.entries.removeFirst(where: { entry in
            guard let entryRequest = URLRequest(entry.request) else {
                return false
            }

            // Note: We don't check headers right now
            if entryRequest.httpMethod == request.httpMethod && entryRequest.url == request.url && entryRequest.httpBody == request.httpBody  {
                return true
            }
            return false
        }) else {
            return nil
        }
        return Interaction(entry)
    }
}

extension Cassette {
    public init?(testResource: String) {
        guard let testBundle = Bundle.allBundles.first(where: { $0.bundlePath.hasSuffix(".xctest") }) else {
            return nil
        }
        self.init(resource: testResource, in: testBundle)
    }

    public init?(resource: String, in bundle: Bundle) {
        guard let path = bundle.path(forResource: resource, ofType: nil) else {
            return nil
        }
        self.init(path: path)
    }

    public init?(url: URL) {
        guard url.isFileURL else {
            return nil
        }
        self.init(path: url.path)
    }

    public init?(path: String) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let har = try decoder.decode(HTTPArchive.self, from: data)
            self.init(har: har)
        } catch {
            return nil
        }
    }
}
