import Foundation

public struct HTTPArchive: Codable {
    public struct Log: Codable {
        public struct Entry: Codable {
            public struct Request: Codable {
                public struct PostData: Codable {
                    public var mimeType: String
                    public var text: String
                    public var encoding: String?
                }

                public var httpVersion: String?
                public var method: String
                public var url: String
                public var headers: [Header]
                public var postData: PostData?
            }

            public struct Response: Codable {
                public struct Content: Codable {
                    public var mimeType: String
                    public var text: String
                    public var encoding: String?
                }

                public var httpVersion: String?
                public var status: Int
                public var headers: [Header]
                public var content: Content
            }

            public struct Header: Codable {
                public var name: String
                public var value: String
            }

            public var request: Request
            public var response: Response
        }

        public var version: String
        public var entries: [Entry]
    }

    public var log: Log
}

extension HTTPArchive.Log.Entry {
    init(request: URLRequest, requestData: Data? = nil, response: URLResponse, responseData: Data? = nil) {
        self.request = Request(request, requestData)
        self.response = Response(response, responseData)
    }
}

extension HTTPArchive.Log.Entry.Request {
    init(_ request: URLRequest, _ requestData: Data? = nil) {
//        self.httpVersion =
        self.method = request.httpMethod ?? ""
        self.url = request.url?.absoluteString ?? ""
        self.headers = request.allHTTPHeaderFields?.map({ (element) in
            let (name, value) = element
            return HTTPArchive.Log.Entry.Header(name: name, value: value)
        }) ?? []
        self.postData = PostData(request, requestData)
    }
}

extension HTTPArchive.Log.Entry.Request.PostData {
    init?(_ request: URLRequest, _ requestData: Data? = nil) {
        return nil
    }
}

extension HTTPArchive.Log.Entry.Response {
    init(_ response: URLResponse, _ responseData: Data? = nil) {
//        self.httpVersion =
        self.status = (response as? HTTPURLResponse)?.statusCode ?? 0
        self.headers = (response as? HTTPURLResponse)?.allHeaderFields.compactMap({ (element) in
            guard case let (name as String, value as String) = element else {
                return nil
            }
            return HTTPArchive.Log.Entry.Header(name: name, value: value)
        }) ?? []
        self.content = Content(response, responseData)
    }
}

extension HTTPArchive.Log.Entry.Response.Content {
    init(_ response: URLResponse, _ responseData: Data? = nil) {
        self.mimeType = response.mimeType ?? ""
        if mimeType.starts(with: "text/") {
    //        self.encoding =
            self.text = responseData.flatMap({ String(data: $0, encoding: .utf8) }) ?? ""
        } else {
            self.encoding = "base64"
            self.text = responseData?.base64EncodedString() ?? ""
        }
    }
}

extension URLRequest {
    init?(_ entry: HTTPArchive.Log.Entry) {
        self.init(entry.request)
    }
    init?(_ request: HTTPArchive.Log.Entry.Request) {
        guard let url = URL(string: request.url) else {
            return nil
        }
        self.init(url: url)
        httpMethod = request.method
        for header in request.headers {
            addValue(header.value, forHTTPHeaderField: header.name)
        }
        if let postData = request.postData {
            httpBody = Data(postData)
        }
    }
}

extension HTTPURLResponse {
    convenience init?(_ entry: HTTPArchive.Log.Entry) {
        guard let url = URL(string: entry.request.url) else {
            return nil
        }
        let statusCode = entry.response.status
        let httpVersion = entry.response.httpVersion
        let headerFields = entry.response.headers.reduce(into: [String: String]()) { acc, header in
            acc[header.name] = header.value
        }
        self.init(url: url, statusCode: statusCode, httpVersion: httpVersion, headerFields: headerFields)
    }
}

extension Data {
    init?(_ postData: HTTPArchive.Log.Entry.Request.PostData) {
        self.init(har: postData.text, encoding: postData.encoding)
    }

    init?(_ content: HTTPArchive.Log.Entry.Response.Content) {
        self.init(har: content.text, encoding: content.encoding)
    }

    private init?(har text: String, encoding: String?) {
        switch encoding {
        case nil:
            self.init(text.utf8)
        case "base64":
            self.init(base64Encoded: text)
        default:
            return nil
        }
    }
}
