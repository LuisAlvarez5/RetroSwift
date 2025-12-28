import Foundation

open class Domain {
    let transport: HttpTransport

    public init(transport: HttpTransport) {
        self.transport = transport
    }

    open func perform<Request, Response: Decodable>(
        request: Request,
        to endpoint: EndpointDescribing,
        customHeaders: [String: String]? = nil
    ) async throws -> Response {
        let requestBuilder = HttpRequestParams.Builder()
        requestBuilder.set(httpMethod: endpoint.method)
        requestBuilder.set(path: endpoint.path)

        try Mirror(reflecting: request)
            .children
            .compactMap { child in
                guard let paramName = child.label,
                      let param = child.value as? HttpRequestParameter
                else { return nil }
                return (paramName, param)
            }
            .forEach { (paramName: String, param: HttpRequestParameter) in
                try param.fillHttpRequestFields(forParameterWithName: paramName, in: requestBuilder)
            }

        if let customHeaders {
            requestBuilder.add(headerParams: customHeaders)
        }

        let requestParams = try requestBuilder.buildRequestParams()
        let operationResult = try await transport.sendRequest(with: requestParams)
        let responseData = try operationResult.response.get()

        if responseData.isEmpty {
            if Response.self is EmptyResponseDecodable.Type || Domain.isEitherWithEmptyResponse(Response.self) {
                return try JSONDecoder().decode(Response.self, from: Domain.emptyJsonData)
            }
        }

        do {
            return try JSONDecoder().decode(Response.self, from: responseData)
        } catch let decodingError as DecodingError {
            let errorDescription = Domain.describeDecodingError(decodingError, data: responseData)
            print("[RetroSwift] Decoding error: \(errorDescription)")
            throw decodingError
        }
    }
}

private extension Domain {
    static func describeDecodingError(_ error: DecodingError, data: Data) -> String {
        let jsonPreview = String(data: data.prefix(500), encoding: .utf8) ?? "Unable to preview"
        
        switch error {
        case .keyNotFound(let key, let context):
            return """
            Key '\(key.stringValue)' not found.
            Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))
            Debug: \(context.debugDescription)
            JSON preview: \(jsonPreview)
            """
        case .typeMismatch(let type, let context):
            return """
            Type mismatch for type '\(type)'.
            Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))
            Debug: \(context.debugDescription)
            JSON preview: \(jsonPreview)
            """
        case .valueNotFound(let type, let context):
            return """
            Value of type '\(type)' not found.
            Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))
            Debug: \(context.debugDescription)
            JSON preview: \(jsonPreview)
            """
        case .dataCorrupted(let context):
            return """
            Data corrupted.
            Path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))
            Debug: \(context.debugDescription)
            JSON preview: \(jsonPreview)
            """
        @unknown default:
            return "Unknown decoding error: \(error.localizedDescription)"
        }
    }
}

private extension Domain {
    static let emptyJsonData = Data("{}".utf8)
}
