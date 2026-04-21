//
//  AppRootView.swift
//  FinalProject
//
//  Created by Codex on 4/15/26.
//

import SwiftUI

// App shell decides whether the user sees auth or the signed-in experience.
struct AppRootView: View {
    @StateObject private var viewModel = AppViewModel()

    var body: some View {
        Group {
            if viewModel.currentUser == nil {
                AuthScreen(viewModel: viewModel)
            } else {
                HomeScreen(viewModel: viewModel)
            }
        }
        .preferredColorScheme(.dark)
    }
}
