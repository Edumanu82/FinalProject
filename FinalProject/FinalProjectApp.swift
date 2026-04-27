//
//  FinalProjectApp.swift
//  FinalProject
//
//  Created by Carlos Fletes on 4/9/26.
//

import SwiftUI
import FirebaseCore

@main
struct FinalProjectApp: App {

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
