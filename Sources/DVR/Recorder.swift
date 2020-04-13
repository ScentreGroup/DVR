import Foundation

//#if canImport(Alamofire)
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
    private var metricsByRequestTask: [URLSessionTask: URLSessionTaskMetrics] = [:]

    func write() {
        var har = HTTPArchive(log: HTTPArchive.Log(version: "1.2", creator: HTTPArchive.Log.Creator(name: "DVR", version: "0.1", comment: nil), entries: []))

        for task in requestTasks {
            guard let request = task.originalRequest, let response = task.response else {
                continue
            }

            let metrics = metricsByRequestTask[task]
            har.log.entries.append(HTTPArchive.Log.Entry(request: request, response: response, responseData: responseDatasByRequestTask[task], metrics: metrics))
        }

        try? writer.write(har: har)
    }
}

extension Recorder {
    public convenience init(url: URL) throws {
        enum Error: Swift.Error {
            case notFileURL
        }

        guard url.isFileURL else {
            throw Error.notFileURL
        }

        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)

        self.init(writer: RecorderPathWriter(url: url))
    }
}

class RecorderPathWriter: RecorderWriter {
    init(url: URL) {
        self.url = url
    }

    let url: URL

    func write(har: HTTPArchive) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(har)
        try data.write(to: url)
    }
}

extension Recorder: EventMonitor {
    public func request(_ request: Request, didCreateTask task: URLSessionTask) {
        requestTasks.append(task)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        responseDatasByRequestTask[dataTask, default: Data()].append(data)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        metricsByRequestTask[task] = metrics
    }

    public func requestDidFinish(_ request: Request) {
        write()
    }

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        write()
    }
}

//#endif
