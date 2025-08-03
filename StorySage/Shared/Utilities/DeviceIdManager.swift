//
//  DeviceIdManager.swift
//  StorySage
//
//  Created on 2025-08-03.
//

import Foundation
import UIKit

class DeviceIdManager {
    static let shared = DeviceIdManager()
    
    private let deviceIdKey = "StorySageDeviceId"
    private let userIdKey = "StorySageUserId"
    
    private init() {}
    
    // MARK: - Device ID
    
    var deviceId: String {
        if let storedId = UserDefaults.standard.string(forKey: deviceIdKey) {
            return storedId
        }
        
        let newId = generateDeviceId()
        UserDefaults.standard.set(newId, forKey: deviceIdKey)
        return newId
    }
    
    private func generateDeviceId() -> String {
        // Use identifierForVendor if available, otherwise generate UUID
        if let vendorId = UIDevice.current.identifierForVendor?.uuidString {
            return "ios_\(vendorId)"
        } else {
            return "ios_\(UUID().uuidString)"
        }
    }
    
    // MARK: - User ID
    
    var userId: String? {
        get {
            return UserDefaults.standard.string(forKey: userIdKey)
        }
        set {
            if let newValue = newValue {
                UserDefaults.standard.set(newValue, forKey: userIdKey)
            } else {
                UserDefaults.standard.removeObject(forKey: userIdKey)
            }
        }
    }
    
    var hasUserId: Bool {
        return userId != nil
    }
    
    func createAnonymousUserId() -> String {
        let anonymousId = "anon_\(UUID().uuidString)"
        userId = anonymousId
        return anonymousId
    }
    
    // MARK: - Device Info
    
    var deviceInfo: [String: String] {
        return [
            "device_id": deviceId,
            "device_type": "iOS",
            "device_model": UIDevice.current.model,
            "os_version": UIDevice.current.systemVersion,
            "app_version": appVersion,
            "app_build": appBuild
        ]
    }
    
    private var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var appBuild: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}