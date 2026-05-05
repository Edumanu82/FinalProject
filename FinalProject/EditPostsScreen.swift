import SwiftUI

struct EditPostsScreen: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isSelecting = false
    @State private var selectedIDs = Set<String>()

    var body: some View {
        List {
            if viewModel.isLoadingProfilePosts && viewModel.profilePosts.isEmpty {
                Section {
                    HStack(spacing: 10) {
                        ProgressView().tint(AstroTheme.primary)
                        Text("Loading your posts...")
                            .foregroundStyle(AstroTheme.muted)
                    }
                }
            }

            ForEach(viewModel.profilePosts) { post in
                HStack(spacing: 12) {
                    selectionIndicator(for: post.id)

                    if let data = post.imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(LinearGradient(colors: post.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 64, height: 64)
                            .overlay(StarFieldOverlay().opacity(0.6).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous)))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.caption)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                        Text(post.timestampText)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(AstroTheme.muted)
                    }

                    Spacer()

                    if !isSelecting {
                        Menu {
                            Button(role: .destructive) {
                                Task { await deleteSingle(postID: post.id) }
                            } label: { Label("Delete", systemImage: "trash") }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AstroTheme.muted)
                                .padding(4)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    guard isSelecting else { return }
                    toggleSelection(for: post.id)
                }
            }

            if !viewModel.profilePosts.isEmpty {
                Section {
                    if viewModel.isLoadingProfilePosts {
                        HStack(spacing: 10) {
                            ProgressView().tint(AstroTheme.primary)
                            Text("Loading more...")
                                .foregroundStyle(AstroTheme.muted)
                        }
                    } else {
                        Button {
                            Task { await viewModel.loadMoreProfilePosts() }
                        } label: {
                            HStack {
                                Spacer()
                                Text("Load 20 more")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Edit Posts")
        .toolbar { toolbarContent }
        .task {
            viewModel.resetProfilePostsPagination()
            await viewModel.loadMoreProfilePosts()
        }
        .alert("Delete Posts", isPresented: Binding(get: { !viewModel.deleteErrorMessage.isEmpty }, set: { _ in viewModel.deleteErrorMessage = "" })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.deleteErrorMessage)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if isSelecting {
                Button("Cancel") { cancelSelection() }
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            if isSelecting {
                Button(role: .destructive) {
                    Task { await deleteSelected() }
                } label: { Text("Delete (") + Text("\(selectedIDs.count)") + Text(")") }
                .disabled(selectedIDs.isEmpty)
            } else {
                Button("Select") { isSelecting = true }
            }
        }
    }

    private func selectionIndicator(for id: String) -> some View {
        Group {
            if isSelecting {
                Image(systemName: selectedIDs.contains(id) ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selectedIDs.contains(id) ? AstroTheme.primary : AstroTheme.muted)
                    .font(.system(size: 20, weight: .bold))
            } else {
                EmptyView()
            }
        }
        .frame(width: isSelecting ? 24 : 0)
    }

    private func toggleSelection(for id: String) {
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }

    private func cancelSelection() {
        isSelecting = false
        selectedIDs.removeAll()
    }

    private func deleteSingle(postID: String) async {
        if let error = await viewModel.deletePost(withID: postID) {
            await MainActor.run { viewModel.deleteErrorMessage = error }
        }
    }

    private func deleteSelected() async {
        let ids = Array(selectedIDs)
        if let error = await viewModel.deletePosts(withIDs: ids) {
            await MainActor.run { viewModel.deleteErrorMessage = error }
        } else {
            await MainActor.run {
                cancelSelection()
            }
        }
    }
}

