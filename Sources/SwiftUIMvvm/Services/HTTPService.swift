//
//  File.swift
//  
//
//  Created by Dao Duy Duong on 29/12/2020.
//

import Foundation
import Alamofire
import Combine

// MARK: - HTTP Endpoint

public protocol HTTPEndpoint {
    var fullURL: URL { get }
    var baseUrl: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameterEncoding: ParameterEncoding { get }
    var shouldIntercept: Bool { get }
    var headers: HTTPHeaders? { get }
    var parameters: [String: Any]? { get }
    var retries: Int { get }
    
    func transformError(_ error: Error) -> Error
}

public extension HTTPEndpoint {
    var fullURL: URL {
        guard let url = URL(string: baseUrl) else {
            return URL(fileURLWithPath: "none")
        }
        return url.appendingPathComponent(path)
    }
    var method: HTTPMethod { .get }
    var parameterEncoding: ParameterEncoding {
        switch method {
        case .get: return URLEncoding.queryString
        default: return JSONEncoding.default
        }
    }
    var shouldIntercept: Bool { false }
    var headers: HTTPHeaders? { nil }
    var parameters: [String: Any]? { nil }
    var retries: Int { 1 }
    
    func transformError(_ error: Error) -> Error { error }
}

// MARK: - HTTP Download Endpoint

public protocol HTTPDownloadEndpoint: HTTPEndpoint {
    var sourceURL: URL { get }
    var destinationURL: URL { get }
}

public extension HTTPDownloadEndpoint {
    var baseUrl: String { "" }
    var path: String { "" }
}

// MARK: - HTTP Upload Endpoint

public protocol HTTPUploadEndpoint: HTTPEndpoint {
    func updateMultipartFormData(_ formData: MultipartFormData)
}

// MARK: - HTTP Service

public enum HTTPServiceError: Error {
    case requestFailed(statusCode: Int, response: Any?)
    case decodingFailed(HTTPEndpoint)
    case unknown(Error?)
}

public class HTTPService {
    
    typealias RetryCompletion = (RetryResult) -> Void
    
    /// Shared instance
    public static let shared = HTTPService()
    
    /// Session configuration
    public var configuration: URLSessionConfiguration {
        sessionManager.sessionConfiguration
    }
    
    private lazy var sessionManager = Session(configuration: URLSessionConfiguration.default)
    
    private init() {}
}

// MARK - Request interceptor

extension HTTPService: RequestInterceptor {
    
    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
    }
}

// MARK: - REST request

public extension HTTPService {
    
    /**
     Call API request with an endpoint
     
     - parameter endpoint: An `HTTPEndpoint` enum.
     - returns: A tuple contains `HTTPURLResponse` and data.
     */
    func requestData(withEndpoint endpoint: HTTPEndpoint) -> AnyPublisher<(HTTPURLResponse, Data), Error> {
        return Future { promise in
            let request = self.sessionManager.request(
                endpoint.fullURL,
                method: endpoint.method,
                parameters: endpoint.parameters,
                encoding: endpoint.parameterEncoding,
                headers: endpoint.headers,
                interceptor: endpoint.shouldIntercept ? self : nil
            ).validate()
            
            request.responseData { dataResponse in
                switch dataResponse.result {
                case .success(let result):
                    if let httpResponse = dataResponse.response {
                        return promise(.success((httpResponse, result)))
                    }
                    
                    promise(.failure(HTTPServiceError.unknown(nil)))
                    
                case .failure(let error):
                    if let statusCode = dataResponse.response?.statusCode,
                       let data = dataResponse.data,
                       let response = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                        return promise(.failure(HTTPServiceError.requestFailed(statusCode: statusCode, response: response)))
                    }
                    
                    promise(.failure(HTTPServiceError.unknown(error)))
                }
            }
        }
        .retry(endpoint.retries)
        .mapError(endpoint.transformError(_:))
        .eraseToAnyPublisher()
    }
    
    /**
     Call API request with an endpoint and transform response into `JSON` object
     
     - parameter endpoint: An `HTTPEndpoint` enum.
     - returns: A tuple contains `HTTPURLResponse` and `JSON` data.
     */
    func requestJSON(withEndpoint endpoint: HTTPEndpoint) -> AnyPublisher<(HTTPURLResponse, Any), Error> {
        return requestData(withEndpoint: endpoint)
            .receive(on: DispatchQueue.global(qos: .background))
            .tryMap {
                do {
                    let JSON = try JSONSerialization.jsonObject(with: $1, options: .allowFragments)
                    return ($0, JSON)
                } catch {
                    throw HTTPServiceError.decodingFailed(endpoint)
                }
            }
            .mapError(endpoint.transformError(_:))
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /**
     Call API request with an endpoint and transform response into a `Decodable` object
     
     - parameter endpoint: An `HTTPEndpoint` enum.
     - returns: `Decodable` object.
     */
    func requestDecodable<M: Decodable>(withEndpoint endpoint: HTTPEndpoint) -> AnyPublisher<M, Error> {
        return requestData(withEndpoint: endpoint)
            .receive(on: DispatchQueue.global(qos: .background))
            .tryMap {
                do {
                    return try JSONDecoder().decode(M.self, from: $1)
                } catch {
                    throw HTTPServiceError.decodingFailed(endpoint)
                }
            }
            .mapError(endpoint.transformError(_:))
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

// MARK: - Download and upload

public extension HTTPService {
    
    /**
     Download from an endpoint
     
     - parameter endpoint: An `HTTPDownloadEndpoint` enum.
     - returns: Downloading progress object.
     */
    func download(withEndpoint endpoint: HTTPDownloadEndpoint) -> AnyPublisher<Progress, Error> {
        return AnyPublisher.create { observer in
            var urlRequest = URLRequest(url: endpoint.sourceURL)
            for (key, value) in endpoint.headers?.dictionary ?? [:] {
                urlRequest.setValue(value, forHTTPHeaderField: key)
            }
            
            let request = self.sessionManager.download(urlRequest) { (temporaryURL, _) in
                do { try FileManager.default.removeItem(at: endpoint.destinationURL) }
                catch {}
                
                return (destinationURL: endpoint.destinationURL, options: .removePreviousFile)
            }
            
            request.downloadProgress { observer.onNext($0) }
            
            request.validate().response(completionHandler: { response in
                switch response.result {
                case .success: observer.onComplete()
                case .failure(let error): observer.onError(HTTPServiceError.unknown(error))
                }
            })
            
            return AnyCancellable { request.cancel() }
        }
        .mapError(endpoint.transformError(_:))
        .eraseToAnyPublisher()
    }
    
    /**
     Upload data to server
     
     - parameter endpoint: An `HTTPUploadEndpoint` enum to upload.
     - returns: Uploaded progress object.
     */
    func upload(withEndpoint endpoint: HTTPUploadEndpoint) -> AnyPublisher<Progress, Error> {
        return AnyPublisher.create { observer in
            let request = self.sessionManager.upload(
                multipartFormData: endpoint.updateMultipartFormData,
                to: endpoint.fullURL,
                method: endpoint.method,
                headers: endpoint.headers,
                interceptor: endpoint.shouldIntercept ? self : nil
            )
            
            request.uploadProgress { observer.onNext($0) }
            
            request.validate().response(completionHandler: { response in
                switch response.result {
                case .success: observer.onComplete()
                case .failure(let error): observer.onError(HTTPServiceError.unknown(error))
                }
            })
            
            return AnyCancellable { request.cancel() }
        }
        .mapError(endpoint.transformError(_:))
        .eraseToAnyPublisher()
    }
}
