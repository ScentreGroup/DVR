import Foundation

struct Interaction {

    // MARK: - Initializers

    init(request: URLRequest, response: Foundation.URLResponse, responseData: Data? = nil) {
        self.request = request
        self.response = response
        self.responseData = responseData
    }

    // MARK: - Properties

    let request: URLRequest
    let response: Foundation.URLResponse
    let responseData: Data?
}

extension Interaction {
    init?(_ har: HTTPArchive.Log.Entry) {
        guard let request = URLRequest(har) else {
            return nil
        }
        guard let response = HTTPURLResponse(har) else {
            return nil
        }
        let responseData = Data(har.response.content)
        self.init(request: request, response: response, responseData: responseData)
    }
}
