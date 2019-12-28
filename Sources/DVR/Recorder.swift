import Foundation

#if canImport(Alamofire)
import Alamofire

protocol RecorderWriter {
    func write(har: HTTPArchive) throws
}

public class Recorder {
    init(writer: RecorderWriter) {
        self.writer = writer
    }

    let writer: RecorderWriter

    private var requestTasks: [URLSessionTask] = []
    private var responseDatasByRequestTask: [URLSessionTask: Data] = [:]

    func write() {
        var har = HTTPArchive(log: HTTPArchive.Log(version: "v1", entries: []))

        for task in requestTasks {
            guard let request = task.originalRequest, let response = task.response else {
                continue
            }
            har.log.entries.append(HTTPArchive.Log.Entry(request: request, response: response))
        }

        try? writer.write(har: har)
    }
}

class RecorderPathWriter: RecorderWriter {
    init(path: String) {
        self.path = path
    }

    let path: String

    func write(har: HTTPArchive) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(har)
        try data.write(to: URL(fileURLWithPath: path))
    }
}

extension Recorder: EventMonitor {

    public func request(_ request: Request, didCreateTask task: URLSessionTask) {
        requestTasks.append(task)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        responseDatasByRequestTask[dataTask] = data
    }

    public func requestDidFinish(_ request: Request) {
        write()
    }

}

extension Recorder {
//    public convenience init?(testResource: String) {
//        guard let testBundle = Bundle.allBundles.first(where: { $0.bundlePath.hasSuffix(".xctest") }) else {
//            return nil
//        }
//        self.init(resource: testResource, in: testBundle)
//    }
//
//    public convenience init?(resource: String, in bundle: Bundle) {
//        guard let bundleResourcePathbundle.resourcePath
//        guard let path = bundle.path(forResource: resource, ofType: nil) else {
//            return nil
//        }
//        self.init(path: path)
//    }
    public convenience init(path: String) {
        self.init(writer: RecorderPathWriter(path: path))
    }
}

#endif

//    private func persist(_ interactions: [Interaction]) {
//        defer {
//            abort()
//        }

// Create directory
//        let outputDirectory = (self.outputDirectory as NSString).expandingTildeInPath
//        let fileManager = FileManager.default
//        if !fileManager.fileExists(atPath: outputDirectory) {
//            do {
//              try fileManager.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true, attributes: nil)
//            } catch {
//              print("[DVR] Failed to create cassettes directory.")
//            }
//        }

//        let cassette = Cassette(name: cassetteName, interactions: interactions)

// Persist


//        do {
//            let outputPath = ((outputDirectory as NSString).appendingPathComponent(cassetteName) as NSString).appendingPathExtension("json")!
//            let data = try JSONSerialization.data(withJSONObject: cassette.dictionary, options: [.prettyPrinted])
//
//            // Add trailing new line
//            guard var string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
//                print("[DVR] Failed to persist cassette.")
//                return
//            }
//            string = string.appending("\n") as NSString
//
//            if let data = string.data(using: String.Encoding.utf8.rawValue) {
//                try? data.write(to: URL(fileURLWithPath: outputPath), options: [.atomic])
//                print("[DVR] Persisted cassette at \(outputPath). Please add this file to your test target")
//                return
//            }
//
//            print("[DVR] Failed to persist cassette.")
//        } catch {
//            print("[DVR] Failed to persist cassette.")
//        }
//    }
