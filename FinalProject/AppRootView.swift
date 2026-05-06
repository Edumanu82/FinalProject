//
//  AppRootView.swift
//  FinalProject

import SwiftUI

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
