import Foundation

public final class Session: URLSession {

    // MARK: - Initializers

    public init(configuration: URLSessionConfiguration = .default, cassettes: [Cassette], delegate: URLSessionDelegate? = nil, delegateQueue queue: OperationQueue? = nil) {
        _configuration = configuration
        self.cassettes = cassettes
        _delegate = delegate
        _delegateQueue = queue ?? {
            let queue = OperationQueue()
            queue.name = "com.scentregroup.DVR.Session.delegateQueue"
            queue.maxConcurrentOperationCount = 1
            return queue
        }()
        super.init()
    }

    // MARK: - Properties

    var cassettes: [Cassette]

    // MARK: - URLSession

    private var _configuration: URLSessionConfiguration
    public override var configuration: URLSessionConfiguration {
        return _configuration
    }

    private var _delegate: URLSessionDelegate?
    public override var delegate: URLSessionDelegate? {
        return _delegate
    }

    private var _delegateQueue: OperationQueue
    public override var delegateQueue: OperationQueue {
        return _delegateQueue
    }

    public override func dataTask(with url: URL) -> URLSessionDataTask {
        return _dataTask(with: URLRequest(url: url))
    }

    public override func dataTask(with url: URL, completionHandler: @escaping ((Data?, Foundation.URLResponse?, Error?) -> Void)) -> URLSessionDataTask {
        return _dataTask(with: URLRequest(url: url), completionHandler: completionHandler)
    }

    public override func dataTask(with request: URLRequest) -> URLSessionDataTask {
        return _dataTask(with: request)
    }

    public override func dataTask(with request: URLRequest, completionHandler: @escaping ((Data?, Foundation.URLResponse?, Error?) -> Void)) -> URLSessionDataTask {
        return _dataTask(with: request, completionHandler: completionHandler)
    }

    private func _dataTask(with request: URLRequest, completionHandler: ((Data?, Foundation.URLResponse?, Error?) -> Void)? = nil) -> URLSessionDataTask {
        var modifiedRequest = request
        if let httpAdditionalHeaders = configuration.httpAdditionalHeaders as? [String: String] {
            for (field, value) in httpAdditionalHeaders {
                if modifiedRequest.value(forHTTPHeaderField: field) == nil {
                    modifiedRequest.addValue(value, forHTTPHeaderField: field)
                }
            }
        }
        return SessionDataTask(session: self, request: modifiedRequest, completionHandler: completionHandler)
    }

    public override func downloadTask(with request: URLRequest) -> URLSessionDownloadTask {
        fatalError("unimplemented")
    }

    public override func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, Foundation.URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        fatalError("unimplemented")
    }

    public override func uploadTask(with request: URLRequest, from bodyData: Data) -> URLSessionUploadTask {
        fatalError("unimplemented")
    }

    public override  func uploadTask(with request: URLRequest, from bodyData: Data?, completionHandler: @escaping (Data?, Foundation.URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        fatalError("unimplemented")
    }

    public override func uploadTask(with request: URLRequest, fromFile fileURL: URL) -> URLSessionUploadTask {
        fatalError("unimplemented")
    }

    public override func uploadTask(with request: URLRequest, fromFile fileURL: URL, completionHandler: @escaping (Data?, Foundation.URLResponse?, Error?) -> Void) -> URLSessionUploadTask {
        fatalError("unimplemented")
    }

    public override func invalidateAndCancel() {
    }

    // MARK: - Internal

    func interactionForRequest(_ request: URLRequest) -> Interaction? {
        for var cassette in cassettes {
            if let interaction = cassette.removeFirstInteractionForRequest(request) {
                return interaction
            }
        }
        return nil
    }

    func dataTask(_ task: URLSessionDataTask, didReceiveData data: Data) {
        if let delegate = delegate as? URLSessionDataDelegate {
            delegate.urlSession?(self, dataTask: task, didReceive: data)
        }
    }

    func task(_ task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        if let delegate = delegate as? URLSessionTaskDelegate {
            delegate.urlSession?(self, task: task, didFinishCollecting: metrics)
        }
    }

    func task(_ task: URLSessionTask, didCompleteWithError error: Error?) {
        if let delegate = delegate as? URLSessionTaskDelegate {
            delegate.urlSession?(self, task: task, didCompleteWithError: error)
        }
    }
}

extension Session {
    public convenience init?(configuration: URLSessionConfiguration = .default, cassetteName: String, delegate: URLSessionDelegate? = nil, delegateQueue queue: OperationQueue? = nil) {
        guard let cassette = Cassette(testResource: "\(cassetteName).json") else {
            return nil
        }
        self.init(configuration: configuration, cassettes: [cassette], delegate: delegate, delegateQueue: queue)
    }
}
