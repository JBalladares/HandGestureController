//
//  HandGestureKnobController.swift
//  KnobRotationTemplate
//

import ARKit
import SwiftUI

@MainActor
class HandGestureKnobController {
    
    private var arKitSession = ARKitSession()
    private var handTracking = HandTrackingProvider()
    
    /// Fires when rotation value changes. Value ranges from 0.0 to 1.0.
    var onRotationValueChanged: ((Float) -> Void)?
    
    // --- Angle mapping (see README Section 3) ---
    private let startAngle: Float = 90.0
    private let endAngle: Float = 32.0
    private var rotationRange: Float { startAngle - endAngle }
    
    // --- Tracked hand (see README Section 4) ---
    private let trackedChirality: HandAnchor.Chirality = .left
    
    // --- Smoothing (see README Section 5) ---
    private let bufferSize = 5
    private let minChangeThreshold: Float = 0.005
    
    // --- Internal state ---
    private var isTracking = false
    private var previousAngle: Float?
    private var scrubValueBuffer: [Float] = []
    private var lastEmittedValue: Float = 0.0
    
    init() {}
    
    func start() async {
        do {
            guard HandTrackingProvider.isSupported else {
                print("[KnobController] Hand tracking is not supported on this device.")
                return
            }
            try await arKitSession.run([handTracking])
            Task { await monitorHandUpdates() }
        } catch {
            print("[KnobController] Failed to start hand tracking: \(error)")
        }
    }
    
    func stop() {
        arKitSession.stop()
        resetState()
    }
    
    // MARK: - Hand Update Loop
    
    private func monitorHandUpdates() async {
        for await update in handTracking.anchorUpdates {
            let anchor = update.anchor
            guard anchor.chirality == trackedChirality else { continue }
            
            switch update.event {
            case .added:
                resetState()
                onRotationValueChanged?(0.0)
            case .updated:
                processHandAnchor(anchor)
            case .removed:
                resetState()
                onRotationValueChanged?(0.0)
            }
        }
    }
    
    // MARK: - Angle Calculation
    
    private func processHandAnchor(_ anchor: HandAnchor) {
        // Tracked joints (see README Section 6)
        guard let thumbKnuckle = anchor.handSkeleton?.joint(.thumbKnuckle),
              let wrist = anchor.handSkeleton?.joint(.wrist) else {
            return
        }
        
        isTracking = true
        
        let originFromThumb = anchor.originFromAnchorTransform * thumbKnuckle.anchorFromJointTransform
        let thumbPosition = SIMD3<Float>(
            originFromThumb.columns.3.x,
            originFromThumb.columns.3.y,
            originFromThumb.columns.3.z
        )
        
        let originFromWrist = anchor.originFromAnchorTransform * wrist.anchorFromJointTransform
        let wristPosition = SIMD3<Float>(
            originFromWrist.columns.3.x,
            originFromWrist.columns.3.y,
            originFromWrist.columns.3.z
        )
        
        let thumbVector = thumbPosition - wristPosition
        let angleRadians = atan2(thumbVector.x, thumbVector.y)
        var angleDegrees = angleRadians * 180.0 / .pi
        if angleDegrees < 0 { angleDegrees += 360 }
        
        let rawValue = mapAngleToRotation(angleDegrees)
        let smoothedValue = applySmoothing(rawValue)
        
        if isTracking && abs(smoothedValue - lastEmittedValue) > minChangeThreshold {
            onRotationValueChanged?(smoothedValue)
            lastEmittedValue = smoothedValue
        }
        
        previousAngle = angleDegrees
    }
    
    // MARK: - Angle-to-Rotation Mapping
    
    private func mapAngleToRotation(_ currentAngle: Float) -> Float {
        if currentAngle >= endAngle && currentAngle <= startAngle {
            let normalized = (startAngle - currentAngle) / rotationRange
            return max(0.0, min(1.0, normalized))
        } else if currentAngle > startAngle && currentAngle < 180 {
            return 0.0
        } else {
            return 1.0
        }
    }
    
    // MARK: - Smoothing
    
    private func applySmoothing(_ newValue: Float) -> Float {
        scrubValueBuffer.append(newValue)
        if scrubValueBuffer.count > bufferSize {
            scrubValueBuffer.removeFirst()
        }
        
        var weightedSum: Float = 0.0
        var totalWeight: Float = 0.0
        
        for (index, value) in scrubValueBuffer.enumerated() {
            let weight = Float(index + 1)
            weightedSum += value * weight
            totalWeight += weight
        }
        
        return weightedSum / totalWeight
    }
    
    // MARK: - State Reset
    
    private func resetState() {
        isTracking = false
        previousAngle = nil
        scrubValueBuffer.removeAll()
        lastEmittedValue = 0.0
    }
}
