import Foundation

extension URLSession: NetworkLoader {
    public func dataTask(for request: URLRequest,
                         completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        dataTask(with: request, completionHandler: completion).resume()
    }
}
