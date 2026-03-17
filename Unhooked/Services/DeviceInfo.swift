//
//  DeviceInfo.swift
//  Unhooked
//
//  Device detection utilities for Dynamic Island support
//

import UIKit

struct DeviceInfo {
    
    /// iPhone model identifiers that have Dynamic Island
    private static let dynamicIslandModels: Set<String> = [
        "iPhone15,2",   // iPhone 14 Pro
        "iPhone15,3",   // iPhone 14 Pro Max
        "iPhone15,4",   // iPhone 15
        "iPhone15,5",   // iPhone 15 Plus
        "iPhone16,1",   // iPhone 15 Pro
        "iPhone16,2",   // iPhone 15 Pro Max
        "iPhone17,1",   // iPhone 16 Pro
        "iPhone17,2",   // iPhone 16 Pro Max
        "iPhone17,3",   // iPhone 16
        "iPhone17,4",   // iPhone 16 Plus
        "iPhone18,1",   // iPhone 17 Pro
        "iPhone18,2",   // iPhone 17 Pro Max
        "iPhone18,3",   // iPhone 17
        "iPhone18,4",   // iPhone Air
    ]
    
    /// Get the device model identifier (e.g., "iPhone15,2")
    static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
    
    /// Check if the current device has Dynamic Island
    static var hasDynamicIsland: Bool {
        #if targetEnvironment(simulator)
        // For simulator, check if it's a Dynamic Island model being simulated
        if let simulatorModelIdentifier = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return dynamicIslandModels.contains(simulatorModelIdentifier)
        }
        return false
        #else
        return dynamicIslandModels.contains(modelIdentifier)
        #endif
    }
    
    /// Get the Y position where content should be placed to appear on top of Dynamic Island
    /// This is the distance from top of screen to where the Dynamic Island top edge is
    static var dynamicIslandTopPadding: CGFloat {
        let model = modelIdentifier
        
        #if targetEnvironment(simulator)
        if let simulatorModel = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return paddingForModel(simulatorModel)
        }
        #endif
        
        return paddingForModel(model)
    }
    
    /// Get the width of the Dynamic Island for the current device
    static var dynamicIslandWidth: CGFloat {
        let model = modelIdentifier
        
        #if targetEnvironment(simulator)
        if let simulatorModel = ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return islandWidthForModel(simulatorModel)
        }
        #endif
        
        return islandWidthForModel(model)
    }
    
    private static func paddingForModel(_ model: String) -> CGFloat {
        switch model {
        case "iPhone18,1", "iPhone18,2", "iPhone18,3":
            // iPhone 17 Pro, 17 Pro Max, 17 - Dynamic Island top edge
            return 11.0
        case "iPhone17,1", "iPhone17,2":
            // iPhone 16 Pro, 16 Pro Max
            return 12.0
        case "iPhone17,3", "iPhone17,4":
            // iPhone 16, 16 Plus
            return 11.0
        case "iPhone18,4":
            // iPhone Air
            return 12.0
        default:
            // iPhone 14 Pro/Max, 15 series
            return 11.0
        }
    }
    
    private static func islandWidthForModel(_ model: String) -> CGFloat {
        switch model {
        case "iPhone18,1", "iPhone18,2":
            // iPhone 17 Pro, 17 Pro Max - slightly wider
            return 128.0
        case "iPhone17,1", "iPhone17,2":
            // iPhone 16 Pro, 16 Pro Max
            return 126.0
        default:
            // Standard Dynamic Island width
            return 126.0
        }
    }
}
