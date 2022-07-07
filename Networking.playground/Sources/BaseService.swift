import Foundation

public protocol BaseServiceProtocol {
    func request<T: Decodable>(with requestObject: RequestObject,
                               decoder: JSONDecoder) async throws -> T
}

public final class BaseService: NSObject, BaseServiceProtocol {
    
    var urlSession: NetworkLoader
    
    public init(urlSession: NetworkLoader = URLSession.shared) {
        self.urlSession = urlSession
    }
    
    public func request<T: Decodable>(with requestObject: RequestObject,
                                      decoder: JSONDecoder) async throws -> T {
        let urlRequest = try requestObject.getUrlRequest()
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
            request(with: urlRequest, decoder: decoder) { (result: Result<T, Error>) in
                switch result {
                case .success(let value):
                    continuation.resume(returning: value)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func request<T: Decodable>(with urlRequest: URLRequest,
                                       decoder: JSONDecoder,
                                       completion: @escaping (Result<T, Error>) -> Void) {
        urlSession.dataTask(for: urlRequest) { [weak self] data, response, error in
            guard let self = self else { return }
            do {
                let result: T = try self.handle(response, with: decoder, with: data)
                completion(.success(result))
            } catch let resultError {
                completion(.failure(resultError))
            }
        }

    }
    
    private func handle<T: Decodable>(_ response: URLResponse?,
                                      with decoder: JSONDecoder,
                                      with data: Data?) throws -> T {
        guard let httpData = data else {
            if let response = response as? HTTPURLResponse,
               let httpStatus = response.httpStatus, !httpStatus.httpStatusType.isSuccess {
                throw AppError.httpError(status: httpStatus)
            }
            throw AppError.badResponse
        }
        
        do {
            return try decoder.decode(T.self, from: httpData)
        } catch DecodingError.keyNotFound {
            throw AppError.mappingFailed
        } catch {
            throw AppError.unknown(error: error as NSError)
        }
    }
}

extension BaseService: URLSessionTaskDelegate { }
