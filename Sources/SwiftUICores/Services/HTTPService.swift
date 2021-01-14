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
    
    func mapped(_ error: Error) -> Error
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
    
    func mapped(_ error: Error) -> Error { error }
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
    func prepareFormData(_ formData: MultipartFormData)
}

// MARK: - HTTP Service

public typealias InterceptorBlock = (URLRequest, Session, ((Result<URLRequest, Error>) -> Void)) -> Void

public enum HTTPServiceError: Error {
    case requestFailed(statusCode: Int, response: Any?)
    case decodingFailed(endpoint: HTTPEndpoint, error: Error)
    case unknown(Error?)
}

public class HTTPService {
    
    /// Session configuration
    public var configuration: URLSessionConfiguration {
        sessionManager.sessionConfiguration
    }
    
    private let sessionManager: Session
    private var interceptorBlock: InterceptorBlock?
    
    /// Init new HTTP service
    /// - Parameter configuration: The session configuration
    public init(configuration: URLSessionConfiguration = .default) {
        sessionManager = Session(configuration: configuration)
    }
}

// MARK - Request interceptor

extension HTTPService: RequestInterceptor {
    
    /// Set the request interceptor handler
    /// - Parameter handler: Interceptor block
    public func setRequestInterceptor(handler: @escaping InterceptorBlock) {
        interceptorBlock = handler
    }
    
    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        interceptorBlock?(urlRequest, session, completion)
    }
}

// MARK: - REST request

public extension HTTPService {
    
    /// Call API request with an endpoint
    /// - Parameter endpoint: HTTP Endpoint to request
    /// - Returns: Request data
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
        .mapError(endpoint.mapped(_:))
        .eraseToAnyPublisher()
    }
    
    /// Call API request with an endpoint and transform response into `JSON` object
    /// - Parameters:
    ///   - endpoint: HTTP Endpoint to request
    ///   - queue: Dispatch Queue to transform to `JSON`
    /// - Returns: `JSON` object
    func requestJSON(withEndpoint endpoint: HTTPEndpoint, queue: DispatchQueue = DispatchQueue.global(qos: .background)) -> AnyPublisher<(HTTPURLResponse, Any), Error> {
        return requestData(withEndpoint: endpoint)
            .receive(on: queue)
            .tryMap {
                do {
                    let JSON = try JSONSerialization.jsonObject(with: $1, options: .allowFragments)
                    return ($0, JSON)
                } catch {
                    throw HTTPServiceError.decodingFailed(endpoint: endpoint, error: error)
                }
            }
            .mapError(endpoint.mapped(_:))
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    /// Call API request with an endpoint and transform response into a `Decodable` object
    /// - Parameters:
    ///   - endpoint: HTTP Endpoint to request
    ///   - queue: Dispatch Queue to transform to `Decodable`
    /// - Returns: `Decodable` object
    func requestDecodable<M: Decodable>(withEndpoint endpoint: HTTPEndpoint, queue: DispatchQueue = DispatchQueue.global(qos: .background)) -> AnyPublisher<M, Error> {
        return requestData(withEndpoint: endpoint)
            .receive(on: queue)
            .tryMap {
                do {
                    return try JSONDecoder().decode(M.self, from: $1)
                } catch {
                    throw HTTPServiceError.decodingFailed(endpoint: endpoint, error: error)
                }
            }
            .mapError(endpoint.mapped(_:))
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
            
            let request = self.sessionManager.download(urlRequest, interceptor: endpoint.shouldIntercept ? self : nil) { (temporaryURL, _) in
                (destinationURL: endpoint.destinationURL, options: .removePreviousFile)
            }
            
            request.downloadProgress { observer.onNext($0) }
            
            request.validate().response { response in
                switch response.result {
                case .success: observer.onComplete()
                case .failure(let error): observer.onError(HTTPServiceError.unknown(error))
                }
            }
            
            return AnyCancellable { request.cancel() }
        }
        .mapError(endpoint.mapped(_:))
        .receive(on: DispatchQueue.main)
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
                multipartFormData: endpoint.prepareFormData,
                to: endpoint.fullURL,
                method: endpoint.method,
                headers: endpoint.headers,
                interceptor: endpoint.shouldIntercept ? self : nil
            )
            
            request.uploadProgress { observer.onNext($0) }
            
            request.validate().response { response in
                switch response.result {
                case .success: observer.onComplete()
                case .failure(let error): observer.onError(HTTPServiceError.unknown(error))
                }
            }
            
            return AnyCancellable { request.cancel() }
        }
        .mapError(endpoint.mapped(_:))
        .receive(on: DispatchQueue.main)
        .eraseToAnyPublisher()
    }
}
