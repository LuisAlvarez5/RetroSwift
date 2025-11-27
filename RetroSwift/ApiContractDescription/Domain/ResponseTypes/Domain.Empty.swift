import Foundation

public protocol EmptyResponseDecodable: Decodable {
    init()
}

extension Domain {
    public struct Empty: EmptyResponseDecodable {
        public init() {}
    }
}
