import Foundation

final class Transport {

    // MARK: - Private Properties

    private let session: URLSession
    private let completionQueue: DispatchQueue

    // MARK: - Lifecycle

    init(session: URLSession = .init(configuration: .default), completionQueue: DispatchQueue = .main) {
        self.session = session
        self.completionQueue = completionQueue
    }

    // MARK: - Public Methods

    /// Perform request with composite response
    ///
    /// Example of expected response:
    /// ```
    ///{
    ///  "meta":  //some struct
    ///  "data": // some struct or array
    ///}
    ///```
    func perform<D: Codable, M: Codable>(request: URLRequest, completion: @escaping (Result<MetaResponse<D, M>, Error>) -> Void) {
        execute(request: request, completion: completion) { data in
            try JSONDecoder.default().decode(MetaResponse<D, M>.self, from: data)
        }
    }

    /// Perform request with simple response
    ///
    /// Example of expected response:
    /// ```
    ///{
    ///  "data": // some struct or array
    ///}
    ///```
    func perform<D: Codable>(request: URLRequest, completion: @escaping (Result<D, Error>) -> Void) {
        execute(request: request, completion: completion) { data in
            try JSONDecoder.default().decode(Response<D>.self, from: data).data
        }
    }

    /// Perform request with raw data response
    func performRaw(request: URLRequest, completion: @escaping (Result<Data, Error>) -> Void) {
        execute(request: request, completion: completion) { $0 }
    }

    /// Perform fetch request with json response
    ///
    /// Example of expected response:
    /// ```
    ///{
    ///  // some struct or array
    ///}
    ///```
    func performFetch<D: Codable>(request: URLRequest, completion: @escaping (Result<D, Error>) -> Void) {
        execute(request: request, completion: completion) { data in
            try JSONDecoder.default().decode(D.self, from: data)
        }
    }

}

// MARK: - Private Methods

private extension Transport {

    /// Every response ends in exactly one completion call: a transport error, a `KinescopeHTTPError`
    /// for any non-2xx status (with or without a body), a decoding error or the decoded value.
    func execute<T>(request: URLRequest,
                    completion: @escaping (Result<T, Error>) -> Void,
                    decode: @escaping (Data) throws -> T) {
        let completionQueue = self.completionQueue
        session.dataTask(with: request) { data, response, error in
            let result = Transport.makeResult(request: request,
                                              data: data,
                                              response: response,
                                              error: error,
                                              decode: decode)
            if case .failure(let error) = result {
                Kinescope.shared.logger?.log(error: error, level: KinescopeLoggerLevel.network)
            }
            completionQueue.async {
                completion(result)
            }
        }.resume()
    }

    static func makeResult<T>(request: URLRequest,
                              data: Data?,
                              response: URLResponse?,
                              error: Error?,
                              decode: (Data) throws -> T) -> Result<T, Error> {
        if let error {
            return .failure(error)
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(URLError(.badServerResponse))
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            let serverError = data.flatMap { try? JSONDecoder.default().decode(ServerErrorWrapper.self, from: $0) }?.error
            return .failure(KinescopeHTTPError(statusCode: httpResponse.statusCode,
                                               url: httpResponse.url ?? request.url,
                                               message: serverError?.message,
                                               detail: serverError?.detail))
        }
        return Result { try decode(data ?? Data()) }
    }

}

// MARK: - Defaults

fileprivate extension JSONDecoder {
    
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        return dateFormatter
    }()

    static func `default`() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

}
