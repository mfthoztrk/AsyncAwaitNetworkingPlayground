import Foundation

public protocol NetworkLoader {
    func dataTask(for request: URLRequest, completion: @escaping (Data?, URLResponse?, Error?) -> Void)
}
