//
//  NetworkManager.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation
import Combine

// MARK: - Network Manager

@MainActor
class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let session = URLSession.shared
    private let baseURL: String
    
    @Published var isConnected = true
    @Published var lastError: NetworkError?
    
    private init() {
        #if DEBUG
        // Development environment - connect to local Flask API
        self.baseURL = "http://localhost:5010"
        #else
        // Production environment
        self.baseURL = "https://api.storysage.com"
        #endif
        
        // Start monitoring network connectivity
        startNetworkMonitoring()
    }
    
    // MARK: - Generic Request Method
    
    func request<T: Codable>(
        endpoint: APIEndpoint,
        responseType: T.Type,
        body: Data? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        
        // Add headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add body if provided
        if let body = body {
            request.httpBody = body
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            // Check HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                guard 200...299 ~= httpResponse.statusCode else {
                    let errorMessage = String(data: data, encoding: .utf8)
                    throw NetworkError.serverError(httpResponse.statusCode, errorMessage)
                }
            }
            
            // Decode response
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(T.self, from: data)
                
                // Clear any previous errors on successful request
                lastError = nil
                isConnected = true
                
                return result
            } catch {
                throw NetworkError.decodingError(error)
            }
            
        } catch let networkError as NetworkError {
            lastError = networkError
            throw networkError
        } catch {
            let wrappedError = NetworkError.networkError(error)
            lastError = wrappedError
            isConnected = false
            throw wrappedError
        }
    }
    
    // MARK: - Convenience Methods
    
    func get<T: Codable>(endpoint: APIEndpoint, responseType: T.Type) async throws -> T {
        return try await request(endpoint: endpoint, responseType: responseType)
    }
    
    func post<T: Codable, U: Codable>(
        endpoint: APIEndpoint,
        body: U,
        responseType: T.Type
    ) async throws -> T {
        let encoder = JSONEncoder()
        do {
            let bodyData = try encoder.encode(body)
            return try await request(endpoint: endpoint, responseType: responseType, body: bodyData)
        } catch {
            throw NetworkError.encodingError(error)
        }
    }
    
    // MARK: - Story API Methods
    
    func getCategories() async throws -> [Category] {
        let response = try await get(
            endpoint: .categories,
            responseType: APIResponse<[Category]>.self
        )
        
        if let error = response.error {
            throw NetworkError.apiError(error)
        }
        
        return response.data ?? []
    }
    
    func getStories(categoryId: String? = nil, gradeLevel: String? = nil) async throws -> [Story] {
        let response = try await get(
            endpoint: .stories(categoryId: categoryId, gradeLevel: gradeLevel),
            responseType: APIResponse<[Story]>.self
        )
        
        if let error = response.error {
            throw NetworkError.apiError(error)
        }
        
        return response.data ?? []
    }
    
    func getStory(id: String) async throws -> Story {
        let response = try await get(
            endpoint: .story(id: id),
            responseType: APIResponse<Story>.self
        )
        
        if let error = response.error {
            throw NetworkError.apiError(error)
        }
        
        guard let story = response.data else {
            throw NetworkError.noData
        }
        
        return story
    }
    
    func getUserProgress(userId: String) async throws -> UserProgress {
        let response = try await get(
            endpoint: .userProgress(userId: userId),
            responseType: APIResponse<UserProgress>.self
        )
        
        if let error = response.error {
            throw NetworkError.apiError(error)
        }
        
        guard let progress = response.data else {
            throw NetworkError.noData
        }
        
        return progress
    }
    
    func updateProgress(
        userId: String,
        storyId: String,
        playbackPosition: Int,
        isCompleted: Bool
    ) async throws {
        let progressUpdate = ProgressUpdateRequest(
            playbackPosition: playbackPosition,
            isCompleted: isCompleted
        )
        
        let response = try await post(
            endpoint: .updateProgress(userId: userId, storyId: storyId),
            body: progressUpdate,
            responseType: APIResponse<String>.self
        )
        
        if let error = response.error {
            throw NetworkError.apiError(error)
        }
    }
    
    // MARK: - Health Check Methods
    
    func healthCheck() async throws -> Bool {
        do {
            let response = try await get(
                endpoint: .healthCheck,
                responseType: APIResponse<[String: String]>.self
            )
            return response.isSuccess
        } catch {
            return false
        }
    }
    
    func audioHealthCheck() async throws -> Bool {
        do {
            let response = try await get(
                endpoint: .audioHealth,
                responseType: APIResponse<[String: String]>.self
            )
            return response.isSuccess
        } catch {
            return false
        }
    }
    
    // MARK: - Download Methods
    
    func downloadAudio(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.serverError(httpResponse.statusCode, nil)
            }
        }
        
        return data
    }
    
    func downloadAudioWithProgress(
        from urlString: String,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            var observationToken: NSKeyValueObservation?
            
            let task = session.downloadTask(with: url) { localURL, response, error in
                // Clean up observation
                observationToken?.invalidate()
                
                if let error = error {
                    continuation.resume(throwing: NetworkError.networkError(error))
                    return
                }
                
                guard let localURL = localURL else {
                    continuation.resume(throwing: NetworkError.noData)
                    return
                }
                
                do {
                    let data = try Data(contentsOf: localURL)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: NetworkError.networkError(error))
                }
            }
            
            // Observe download progress
            observationToken = task.progress.observe(\.fractionCompleted) { progress, _ in
                DispatchQueue.main.async {
                    progressHandler(progress.fractionCompleted)
                }
            }
            
            task.resume()
        }
    }
    
    // MARK: - Network Monitoring
    
    private func startNetworkMonitoring() {
        // Simple connectivity check - in a real app you might use NWPathMonitor
        Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                do {
                    let isHealthy = try await self.healthCheck()
                    self.isConnected = isHealthy
                } catch {
                    self.isConnected = false
                }
            }
        }
    }
}