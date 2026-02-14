//
//  KnobRotationView.swift
//  KnobRotationTemplate
//

import SwiftUI
import RealityKit

struct KnobRotationView: View {
    
    @State private var gestureController: HandGestureKnobController?
    @State private var rotationValue: Float = 0.0
    @State private var knobEntity: Entity?
    
    // --- Knob placement (see README Section 2) ---
    private let knobPosition = SIMD3<Float>(0, 1.2, -0.8)
    private let knobScale: Float = 0.15
    
    // --- Rotation axis (see README Section 7) ---
    private let rotationAxis = SIMD3<Float>(0, 1, 0)
    
    var body: some View {
        RealityView { content, attachments in
            
            // --- Load 3D knob (see README Section 1) ---
            let knob = await loadKnobEntity(named: "KnobAsset")
            knob.position = knobPosition
            knob.scale = SIMD3<Float>(repeating: knobScale)
            content.add(knob)
            knobEntity = knob
            
            if let label = attachments.entity(for: "rotationLabel") {
                label.position = SIMD3<Float>(
                    knobPosition.x,
                    knobPosition.y + 0.25,
                    knobPosition.z
                )
                content.add(label)
            }
            
        } update: { content, attachments in
            
            guard let knob = knobEntity else { return }
            
            // Maps 0.0-1.0 to 0-360 degrees (see README Section 8)
            let fullRotationRadians = rotationValue * 2.0 * .pi
            
            knob.transform.rotation = simd_quatf(
                angle: fullRotationRadians,
                axis: rotationAxis
            )
            
            if let label = attachments.entity(for: "rotationLabel") {
                label.position = SIMD3<Float>(
                    knobPosition.x,
                    knobPosition.y + 0.25,
                    knobPosition.z
                )
            }
            
        } attachments: {
            
            // --- Debug HUD (see README Section 9) ---
            Attachment(id: "rotationLabel") {
                VStack(spacing: 8) {
                    Text("Knob Rotation")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("\(Int(rotationValue * 360))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                    
                    Text("degrees")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                    
                    ZStack {
                        Circle()
                            .stroke(.quaternary, lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(rotationValue))
                            .stroke(.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                    }
                    .padding(.top, 4)
                }
                .padding(24)
                .frame(width: 200, height: 260)
                .glassBackgroundEffect(in: .rect(cornerRadius: 24))
            }
        }
        .task {
            let controller = HandGestureKnobController()
            await controller.start()
            gestureController = controller
            
            controller.onRotationValueChanged = { value in
                withAnimation(.interactiveSpring(response: 0.15, dampingFraction: 0.9)) {
                    rotationValue = value
                }
            }
        }
    }
    
    // MARK: - Asset Loading
    
    private func loadKnobEntity(named assetName: String) async -> Entity {
        do {
            let entity = try await Entity(named: assetName)
            return entity
        } catch {
            print("[KnobRotationView] Could not load '\(assetName).usdz': \(error)")
            print("[KnobRotationView] Using placeholder cylinder instead.")
            return createPlaceholderKnob()
        }
    }
    
    private func createPlaceholderKnob() -> Entity {
        let parent = Entity()
        
        let bodyMesh = MeshResource.generateCylinder(height: 0.3, radius: 0.5)
        var bodyMaterial = SimpleMaterial()
        bodyMaterial.color = .init(tint: .gray)
        bodyMaterial.roughness = 0.4
        bodyMaterial.metallic = 0.8
        let body = ModelEntity(mesh: bodyMesh, materials: [bodyMaterial])
        parent.addChild(body)
        
        let indicatorMesh = MeshResource.generateBox(width: 0.08, height: 0.32, depth: 0.4)
        var indicatorMaterial = SimpleMaterial()
        indicatorMaterial.color = .init(tint: .white)
        let indicator = ModelEntity(mesh: indicatorMesh, materials: [indicatorMaterial])
        indicator.position = SIMD3<Float>(0, 0.01, -0.25)
        parent.addChild(indicator)
        
        let capMesh = MeshResource.generateCylinder(height: 0.05, radius: 0.35)
        var capMaterial = SimpleMaterial()
        capMaterial.color = .init(tint: .darkGray)
        capMaterial.roughness = 0.3
        capMaterial.metallic = 0.9
        let cap = ModelEntity(mesh: capMesh, materials: [capMaterial])
        cap.position = SIMD3<Float>(0, 0.175, 0)
        parent.addChild(cap)
        
        return parent
    }
}
