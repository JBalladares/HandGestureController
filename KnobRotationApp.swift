//
//  KnobRotationApp.swift
//  KnobRotationTemplate
//

import SwiftUI

@main
struct KnobRotationApp: App {
    
    @State private var immersionStyle: ImmersionStyle = .mixed

    var body: some Scene {
        ImmersiveSpace {
            KnobRotationView()
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed)
    }
}
