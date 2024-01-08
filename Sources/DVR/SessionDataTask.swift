import Foundation

enum DVRError: Error {
    case interactionNotFound
}

final class SessionDataTask: URLSessionDataTask {

    // MARK: - Types

    typealias Completion = (Data?, Foundation.URLResponse?, NSError?) -> Void


    // MARK: - Properties

    weak var session: Session!
    let request: URLRequest
    let completion: Completion?
    private let queue: DispatchQueue
    private var interaction: Interaction?

    override var response: Foundation.URLResponse? {
        return interaction?.response
    }


    // MARK: - Initializers

    init(session: Session, request: URLRequest, completion: (Completion)? = nil) {
        self.session = session
        self.request = request
        self.completion = completion
        queue = DispatchQueue(label: "com.venmo.DVR.sessionDataTaskQueue", qos: .userInitiated, attributes: [], target: session.delegateQueue.underlyingQueue)
    }


    // MARK: - URLSessionTask

    var _state: URLSessionTask.State?
    override var state: URLSessionTask.State {
        return _state ?? .suspended
    }

    override func cancel() {
        // Don't do anything
    }

    override func resume() {
        if _state == .running {
            return
        }
        
        let cassette = session.cassette

        _state = .running

        // Find interaction
        if let interaction = session.cassette?.interactionForRequest(request) {
            self.interaction = interaction
            queue.async { [weak self] in
                guard let self = self else {
                    fatalError("[DVR] Something has gone horribly wrong.")
                }

                self._state = .completed
                self.session.finishTask(self, interaction: interaction, playback: true)

                // Forward completion
                if let completion = self.completion {
                    completion(interaction.responseData, interaction.response, nil)
                }
            }
            return
        }

        if cassette != nil {
            if let completion = self.completion {
                completion(nil, nil, DVRError.interactionNotFound as NSError)
            }
            return
        }

        // Cassette is missing. Record.
        if session.recordingEnabled == false {
            fatalError("[DVR] Recording is disabled.")
        }

        let task = session.backingSession.dataTask(with: request, completionHandler: { [weak self] data, response, error in

            //Ensure we have a response
            guard let response = response else {
                fatalError("[DVR] Failed to record because the task returned a nil response.")
            }

            guard let self = self else {
                fatalError("[DVR] Something has gone horribly wrong.")
            }

            // Still call the completion block so the user can chain requests while recording.
            self.queue.async { [weak self] in
                guard let self = self else {
                    fatalError("[DVR] Something has gone horribly wrong.")
                }

                self._state = .completed

                // Create interaction
                self.interaction = Interaction(request: self.request, response: response, responseData: data)
                self.session.finishTask(self, interaction: self.interaction!, playback: false)

                self.completion?(data, response, nil)
            }
        })
        task.resume()
    }
}
