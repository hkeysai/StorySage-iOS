//
//  ErrorView.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import SwiftUI

struct ErrorView: View {
    let error: Error
    let retryAction: (() -> Void)?
    
    init(error: Error, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.errorRed)
            
            VStack(spacing: 12) {
                Text("Oops! Something went wrong")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.storySagePrimary)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.secondaryBackground)
    }
    
    private var errorMessage: String {
        if let networkError = error as? NetworkError {
            return networkError.errorDescription ?? "Unknown network error"
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "Please check your internet connection and try again."
            case .timedOut:
                return "The request timed out. Please try again."
            case .cannotFindHost, .cannotConnectToHost:
                return "Unable to connect to the server. Please try again later."
            default:
                return "A network error occurred. Please try again."
            }
        } else {
            return error.localizedDescription
        }
    }
}

#Preview {
    ErrorView(
        error: NetworkError.networkError(URLError(.notConnectedToInternet)),
        retryAction: {
            print("Retry tapped")
        }
    )
}