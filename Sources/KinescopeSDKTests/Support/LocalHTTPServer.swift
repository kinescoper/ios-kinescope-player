import Foundation
import Network

/// Minimal loopback HTTP/1.1 server for integration tests: one request per connection.
final class LocalHTTPServer {

    struct Request {
        let method: String
        let path: String
        let headers: [String: String]

        func header(_ name: String) -> String? {
            headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
        }
    }

    struct Response {
        let status: Int
        let contentType: String
        let body: Data

        static func notFound() -> Response {
            Response(status: 404, contentType: "text/plain", body: Data())
        }
    }

    private let listener: NWListener
    private let queue = DispatchQueue(label: "LocalHTTPServer")
    private let handler: (Request) -> Response
    private let lock = NSLock()
    private var receivedRequests = [Request]()

    var requests: [Request] {
        lock.lock()
        defer { lock.unlock() }
        return receivedRequests
    }

    private(set) var port: UInt16 = 0

    var baseURL: URL {
        URL(string: "http://127.0.0.1:\(port)")!
    }

    init(handler: @escaping (Request) -> Response) throws {
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        listener = try NWListener(using: parameters)
        self.handler = handler
    }

    func start() throws {
        let ready = DispatchSemaphore(value: 0)
        listener.stateUpdateHandler = { state in
            if case .ready = state {
                ready.signal()
            }
        }
        listener.newConnectionHandler = { [weak self] connection in
            self?.serve(connection)
        }
        listener.start(queue: queue)
        guard ready.wait(timeout: .now() + 5) == .success, let port = listener.port?.rawValue else {
            throw URLError(.cannotConnectToHost)
        }
        self.port = port
    }

    func stop() {
        listener.cancel()
    }

    // MARK: - Private

    private func serve(_ connection: NWConnection) {
        connection.start(queue: queue)
        receive(on: connection, buffer: Data())
    }

    private func receive(on connection: NWConnection, buffer: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 64 * 1024) { [weak self] data, _, isComplete, error in
            guard let self else {
                return
            }
            var buffer = buffer
            if let data {
                buffer.append(data)
            }
            if let headerEnd = buffer.range(of: Data("\r\n\r\n".utf8)),
               let request = Self.parse(buffer.subdata(in: buffer.startIndex..<headerEnd.lowerBound)) {
                lock.lock()
                receivedRequests.append(request)
                lock.unlock()
                send(handler(request), on: connection)
            } else if isComplete || error != nil {
                connection.cancel()
            } else {
                receive(on: connection, buffer: buffer)
            }
        }
    }

    private func send(_ response: Response, on connection: NWConnection) {
        var head = "HTTP/1.1 \(response.status) Status\r\n"
        head += "Content-Type: \(response.contentType)\r\n"
        head += "Content-Length: \(response.body.count)\r\n"
        head += "Connection: close\r\n\r\n"
        connection.send(content: Data(head.utf8) + response.body, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    private static func parse(_ data: Data) -> Request? {
        guard let text = String(data: data, encoding: .utf8) else {
            return nil
        }
        var lines = text.components(separatedBy: "\r\n")
        let requestLine = lines.removeFirst().split(separator: " ")
        guard requestLine.count >= 2 else {
            return nil
        }
        var headers = [String: String]()
        for line in lines {
            guard let separator = line.firstIndex(of: ":") else {
                continue
            }
            let name = String(line[..<separator])
            let value = line[line.index(after: separator)...].trimmingCharacters(in: .whitespaces)
            headers[name] = value
        }
        let path = String(requestLine[1]).components(separatedBy: "?")[0]
        return Request(method: String(requestLine[0]), path: path, headers: headers)
    }

}
