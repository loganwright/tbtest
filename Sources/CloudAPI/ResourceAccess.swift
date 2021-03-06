import Vapor

public struct ResourceAccess<T: Content> {
    public let token: Token
    public let baseUrl: String
    public let container: Container

    init(token: Token, baseUrl: String, on container: Container) {
        self.token = token
        self.baseUrl = baseUrl
        self.container = container
    }

    public func view() -> Future<T> {
        let response = send(.GET, to: baseUrl)
        return response.become(T.self)
    }

    public func view(id: String) -> Future<T> {
        let url = self.baseUrl.trailSlash + id
        let response = send(.GET, to: url)
        return response.become(T.self)
    }

    public func list(query: String? = nil) -> Future<[T]> {
        let url = query.flatMap { baseUrl + "?" + $0 } ?? baseUrl
        let response = send(.GET, to: url)
        return response.become([T].self)
    }

    public func create<U: Content>(_ content: U) -> Future<T> {
        let response = send(.POST, to: baseUrl, with: content)
        return response.become(T.self)
    }

    public func update<U: Content>(id: String, with content: U) -> Future<T> {
        let url = self.baseUrl.trailSlash + id
        let response = send(.PATCH, to: url, with: content)
        return response.become(T.self)
    }

    public func replace(id: String, with content: T) -> Future<T> {
        let url = self.baseUrl.trailSlash + id
        let response = send(.PUT, to: url, with: content)
        return response.become(T.self)
    }

    public func delete(id: String) -> Future<Void> {
        let url = self.baseUrl.trailSlash + id
        let response = send(.DELETE, to: url)
        return response.validate().void()
    }
}

extension ResourceAccess {
    private func send<C: Content>(
        _ method: HTTPMethod,
        to url: URLRepresentable,
        with content: C
    ) -> Future<Response> {
        return send(method, to: url) { try $0.content.encode(content) }
    }

    private func send(
        _ method: HTTPMethod,
        to url: URLRepresentable,
        beforeSend: (Request) throws -> () = { _ in }
    ) -> Future<Response> {
        // Headers
        var headers = HTTPHeaders()
        headers.add(name: .authorization, value: "Bearer \(token.key)")
        headers.add(name: .contentType, value: "application/json")

        let client = FoundationClient.default(on: container)
        let response = client.send(method, headers: headers, to: url, beforeSend: beforeSend)
        return response.map { response in
//            print("Got response:\n\(response)\n\n***")
            return response
        }
    }
}

extension Content {
    public static func Access(with token: Token, baseUrl url: String, on container: Container) -> ResourceAccess<Self> {
        return ResourceAccess<Self>(token: token, baseUrl: url, on: container)
    }
}
