import Foundation

final class SessionDataTask: URLSessionDataTask {

    // MARK: - Types

    typealias Completion = (Data?, Foundation.URLResponse?, Error?) -> Void

    // MARK: - Initializers

    init(session: Session, request: URLRequest, completionHandler: Completion? = nil) {
        self.session = session
        self.request = request
        self.completionHandler = completionHandler
    }

    // MARK: - Properties

    unowned var session: Session
    private let request: URLRequest
    private let completionHandler: Completion?
    private var interaction: Interaction?

    override var originalRequest: URLRequest? {
        return request
    }
    override var currentRequest: URLRequest? {
        return interaction?.request ?? request
    }
    override var response: Foundation.URLResponse? {
        return interaction?.response
    }

    // MARK: - URLSessionTask

    var _state: URLSessionTask.State?
    override var state: URLSessionTask.State {
        return _state ?? .suspended
    }

    override func cancel() {
    }

    override func resume() {
        guard let interaction = session.interactionForRequest(request) else {
            session.task(self, didCompleteWithError: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil))
            return
        }

        self.interaction = interaction

        let session = self.session

        if let completion = completionHandler {
            session.delegateQueue.addOperation {
                completion(interaction.responseData, interaction.response, nil)
            }
        }

        if let data = interaction.responseData {
            session.delegateQueue.addOperation {
                session.dataTask(self, didReceiveData: data)
            }
        }

        session.delegateQueue.addOperation {
            session.task(self, didCompleteWithError: nil)
        }
    }
}
