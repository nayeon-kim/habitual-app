//
//  MDBBApp.swift
//  MDBB
//
//  Created by Nayeon Kim on 5/4/25.
//

import SwiftUI

@main
struct MDBBApp: App {
    @StateObject private var routineStore = RoutineStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(routineStore)
        }
    }
}
