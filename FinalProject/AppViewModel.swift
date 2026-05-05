//
//  AppViewModel.swift
//  FinalProject
//
//  Created by Codex on 4/15/26.
//

import Combine
import CoreLocation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore


@MainActor
final class AppViewModel: ObservableObject {
    
    @Published var isFeedLoading = false
    @Published var feedErrorMessage = ""
    @Published var feedPosts: [FeedPost] = []
    @Published var activePostComments: [PostComment] = []
    @Published var isCommentsLoading = false
    @Published var commentsErrorMessage = ""
    @Published var pendingLikePostIDs = Set<String>()
    @Published var currentUser: UserProfile?
    @Published var authMode: AuthMode = .login
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var loginEmail = ""
    @Published var loginPassword = ""
    @Published var signUpUsername = ""
    @Published var signUpEmail = ""
    @Published var signUpPassword = ""
    @Published var confirmPassword = ""
    @Published var selectedTab: HomeTab = .home
    @Published var visibleObjects = CelestialObject.sampleData
    @Published var skySnapshot = SkySnapshot.placeholder
    @Published var locationAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var skyConditions = SkyConditions.fallback
    @Published var isSkyDataLoading = false
    @Published var skyDataErrorMessage = ""
    @Published var manualLocationQuery = ""
    @Published var activeLocationName: String?
    @Published var isSearchingLocation = false
    @Published var objectSearchQuery = ""
    @Published var remoteObjectSearchResults: [SearchableSkyObject] = []
    @Published var displayedObjectSearchResults: [SearchableSkyObject] = []
    @Published var isObjectSearchLoading = false
    @Published var astronomyAPIErrorMessage = ""
    @Published var isDeletingPosts = false
    @Published var deleteErrorMessage = ""
    @Published var profilePosts: [FeedPost] = []
    @Published var isLoadingProfilePosts = false
    @Published var savedEventIDs = Set<String>()
    private var profilePostsLastDocument: DocumentSnapshot?
    private var feedListener: ListenerRegistration?
    private var commentsListener: ListenerRegistration?
    private var activeCommentsPostID: String?

    let authService = AstronomyAuthService()
    let upcomingEvents = EventCard.sampleData

    private let locationManager = SkyLocationManager()
    private let skyAPIService = SkyAPIService()
    private let db = Firestore.firestore()

    private var cancellables = Set<AnyCancellable>()
    private var skyRefreshTask: Task<Void, Never>?
    private var userListener: ListenerRegistration?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        currentUser = authService.currentUser
        loadSavedEvents()
        bindLocationUpdates()
        bindAuthState()
        startFeedListener()
        refreshSkyData()
        

        Task { [weak self] in
            await self?.refreshObjectSearch()
        }
    }


    func login() async {
        errorMessage = ""

        guard !loginEmail.isEmpty, !loginPassword.isEmpty else {
            errorMessage = "Enter your email and password."
            return
        }

        await runAuthAction {
            let user = try await authService.login(email: loginEmail, password: loginPassword)
            currentUser = user
            loadSavedEvents()
            feedErrorMessage = ""
            startUserListener(for: user.id)
            startFeedListener()
        }
    }

    func signUp() async {
        errorMessage = ""

        guard !signUpUsername.isEmpty, !signUpEmail.isEmpty, !signUpPassword.isEmpty else {
            errorMessage = "Complete every sign up field."
            return
        }

        guard signUpPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        await runAuthAction {
            let user = try await authService.signUp(
                username: signUpUsername,
                email: signUpEmail,
                password: signUpPassword
            )
            currentUser = user
            loadSavedEvents()
            feedErrorMessage = ""
            startUserListener(for: user.id)
            startFeedListener()
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            errorMessage = error.localizedDescription
        }

        userListener?.remove()
        userListener = nil
        feedListener?.remove()
        feedListener = nil
        stopCommentsListener()

        currentUser = nil
        savedEventIDs = []
        feedPosts = []
        feedErrorMessage = ""
        isFeedLoading = false

        loginPassword = ""
        signUpPassword = ""
        confirmPassword = ""
        selectedTab = .home
        authMode = .login
    }
    
    func startFeedListener() {
        feedListener?.remove()

        isFeedLoading = true
        feedErrorMessage = ""

        feedListener = db.collection("feedPosts")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    Task { @MainActor in
                        self.isFeedLoading = false
                        self.feedErrorMessage = error.localizedDescription
                    }
                    return
                }

                guard let documents = snapshot?.documents else {
                    Task { @MainActor in
                        self.feedPosts = []
                        self.isFeedLoading = false
                        self.feedErrorMessage = ""
                    }
                    return
                }

                let posts = documents.compactMap { Self.feedPost(from: $0) }

                Task { @MainActor in
                    self.feedPosts = posts
                    self.isFeedLoading = false
                    self.feedErrorMessage = ""
                }
            }
    }
    
    func createPost(caption: String, imageData: Data?) async -> String? {
        print("🚀 Starting createPost")

        guard let currentUser else {
            print("❌ No current user")
            return "You must be signed in to create a post."
        }

        guard let imageData else {
            print("❌ No image data")
            return "Choose a photo to post."
        }

        let trimmedCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCaption.isEmpty else {
            print("❌ Caption empty")
            return "Add a description for your post."
        }

        isFeedLoading = true
        feedErrorMessage = ""

        do {
            guard let uiImage = UIImage(data: imageData) else {
                isFeedLoading = false
                return "The selected image could not be processed."
            }

            guard let compressedData = uiImage.jpegData(compressionQuality: 0.2) else {
                isFeedLoading = false
                return "The selected image could not be compressed."
            }

            print("✅ Original image size:", imageData.count)
            print("✅ Compressed image size:", compressedData.count)

            let imageBase64 = compressedData.base64EncodedString()

            let postData: [String: Any] = [
                "userID": currentUser.id,
                "username": currentUser.username,
                "caption": trimmedCaption,
                "createdAt": Timestamp(date: Date()),
                "likes": 0,
                "comments": 0,
                "likedBy": [],
                "imageBase64": imageBase64
            ]

            print("📝 Saving Firestore document...")

            try await db.collection("feedPosts").addDocument(data: postData)

            print("✅ Firestore save SUCCESS")

            isFeedLoading = false
            feedErrorMessage = ""
            return nil

        } catch {
            print("🔥 ERROR:", error.localizedDescription)
            isFeedLoading = false
            feedErrorMessage = error.localizedDescription
            return error.localizedDescription
        }
    }

    var savedEventCount: Int {
        savedEventIDs.count
    }

    func isEventSaved(_ event: EventCard) -> Bool {
        savedEventIDs.contains(event.id)
    }

    func toggleSavedEvent(_ event: EventCard) {
        if savedEventIDs.contains(event.id) {
            savedEventIDs.remove(event.id)
        } else {
            savedEventIDs.insert(event.id)
        }

        saveSavedEvents()
    }

    func toggleLike(for post: FeedPost) async -> String? {
        guard let currentUser else {
            return "You must be signed in to like a post."
        }

        guard !pendingLikePostIDs.contains(post.id) else { return nil }

        pendingLikePostIDs.insert(post.id)
        defer { pendingLikePostIDs.remove(post.id) }

        let postRef = db.collection("feedPosts").document(post.id)
        let currentUserID = currentUser.id

        do {
            _ = try await db.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(postRef)
                    let data = snapshot.data() ?? [:]
                    var likedBy = Self.stringArray(from: data["likedBy"])
                    let currentLikes = Self.intValue(from: data["likes"])

                    if likedBy.contains(currentUserID) {
                        likedBy.removeAll { $0 == currentUserID }
                        transaction.updateData([
                            "likes": max(currentLikes - 1, 0),
                            "likedBy": likedBy
                        ], forDocument: postRef)
                    } else {
                        likedBy.append(currentUserID)
                        transaction.updateData([
                            "likes": currentLikes + 1,
                            "likedBy": likedBy
                        ], forDocument: postRef)
                    }
                } catch {
                    errorPointer?.pointee = error as NSError
                }

                return nil
            }

            feedErrorMessage = ""
            return nil
        } catch {
            feedErrorMessage = error.localizedDescription
            return error.localizedDescription
        }
    }

    func startCommentsListener(for postID: String) {
        commentsListener?.remove()
        activeCommentsPostID = postID
        activePostComments = []
        isCommentsLoading = true
        commentsErrorMessage = ""

        commentsListener = db.collection("feedPosts")
            .document(postID)
            .collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    Task { @MainActor in
                        guard self.activeCommentsPostID == postID else { return }
                        self.isCommentsLoading = false
                        self.commentsErrorMessage = error.localizedDescription
                    }
                    return
                }

                let comments = snapshot?.documents.compactMap {
                    Self.postComment(from: $0, postID: postID)
                } ?? []

                Task { @MainActor in
                    guard self.activeCommentsPostID == postID else { return }
                    self.activePostComments = comments
                    self.isCommentsLoading = false
                    self.commentsErrorMessage = ""
                }
            }
    }

    func stopCommentsListener() {
        commentsListener?.remove()
        commentsListener = nil
        activeCommentsPostID = nil
        activePostComments = []
        isCommentsLoading = false
        commentsErrorMessage = ""
    }

    func addComment(to postID: String, text: String) async -> String? {
        guard let currentUser else {
            return "You must be signed in to comment."
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            return "Write a comment first."
        }

        let postRef = db.collection("feedPosts").document(postID)
        let commentRef = postRef.collection("comments").document()

        do {
            let batch = db.batch()
            batch.setData([
                "userID": currentUser.id,
                "username": currentUser.username,
                "text": trimmedText,
                "createdAt": Timestamp(date: Date())
            ], forDocument: commentRef)
            batch.updateData([
                "comments": FieldValue.increment(Int64(1))
            ], forDocument: postRef)

            try await batch.commit()
            commentsErrorMessage = ""
            return nil
        } catch {
            commentsErrorMessage = error.localizedDescription
            return error.localizedDescription
        }
    }

    func deletePost(withID id: String) async -> String? {
        guard currentUser != nil else { return "You must be signed in to delete a post." }
        isDeletingPosts = true
        deleteErrorMessage = ""
        do {
            let postRef = db.collection("feedPosts").document(id)
            let commentsSnapshot = try await postRef.collection("comments").getDocuments()
            let batch = db.batch()
            for commentDocument in commentsSnapshot.documents {
                batch.deleteDocument(commentDocument.reference)
            }
            batch.deleteDocument(postRef)
            try await batch.commit()
            await MainActor.run {
                self.feedPosts.removeAll { $0.id == id }
                self.profilePosts.removeAll { $0.id == id }
            }
            isDeletingPosts = false
            return nil
        } catch {
            isDeletingPosts = false
            deleteErrorMessage = error.localizedDescription
            return error.localizedDescription
        }
    }

    func deletePosts(withIDs ids: [String]) async -> String? {
        guard currentUser != nil else { return "You must be signed in to delete posts." }
        guard !ids.isEmpty else { return nil }
        isDeletingPosts = true
        deleteErrorMessage = ""
        do {
            let batch = db.batch()
            let collection = db.collection("feedPosts")
            for id in ids {
                let postRef = collection.document(id)
                let commentsSnapshot = try await postRef.collection("comments").getDocuments()
                for commentDocument in commentsSnapshot.documents {
                    batch.deleteDocument(commentDocument.reference)
                }
                batch.deleteDocument(postRef)
            }
            try await batch.commit()
            await MainActor.run {
                self.feedPosts.removeAll { ids.contains($0.id) }
                self.profilePosts.removeAll { ids.contains($0.id) }
            }
            isDeletingPosts = false
            return nil
        } catch {
            isDeletingPosts = false
            deleteErrorMessage = error.localizedDescription
            return error.localizedDescription
        }
    }
    
    func resetProfilePostsPagination() {
        profilePosts = []
        profilePostsLastDocument = nil
    }

    func loadMoreProfilePosts(pageSize: Int = 20) async {
        guard let currentUser else { return }
        if isLoadingProfilePosts { return }
        isLoadingProfilePosts = true
        deleteErrorMessage = ""
        var query: Query = db.collection("feedPosts")
            .whereField("userID", isEqualTo: currentUser.id)
            .order(by: "createdAt", descending: true)
            .limit(to: pageSize)
        if let last = profilePostsLastDocument {
            query = query.start(afterDocument: last)
        }
        do {
            let snapshot = try await query.getDocuments()
            let newPosts = snapshot.documents.compactMap { Self.feedPost(from: $0) }
            await MainActor.run {
                self.profilePosts.append(contentsOf: newPosts)
                self.profilePostsLastDocument = snapshot.documents.last
            }
        } catch {
            await MainActor.run {
                self.deleteErrorMessage = error.localizedDescription
            }
        }
        isLoadingProfilePosts = false
    }

    func requestLocationAccess() {
        activeLocationName = nil
        locationManager.requestLocationAccess()
    }

    func searchForLocation() async {
        let query = manualLocationQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            skyDataErrorMessage = "Enter a city or location name first."
            return
        }

        isSearchingLocation = true
        skyDataErrorMessage = ""

        do {
            let result = try await skyAPIService.searchLocation(named: query)
            activeLocationName = result.displayName
            refreshSkyData(using: result.coordinate, coordinateForCopy: result.coordinate)
        } catch {
            skyDataErrorMessage = error.localizedDescription
        }

        isSearchingLocation = false
    }

    var canRequestLocation: Bool {
        activeLocationName == nil && locationAuthorizationStatus == .notDetermined
    }

    var locationButtonTitle: String {
        if activeLocationName != nil {
            return "Use Device Location"
        }

        switch locationAuthorizationStatus {
        case .notDetermined:
            return "Use My Location"
        case .denied, .restricted:
            return "Location Unavailable"
        default:
            return "Update Sky Data"
        }
    }

    var locationStatusMessage: String {
        if let activeLocationName {
            return "Sky recommendations are centered on \(activeLocationName) with live conditions."
        }

        switch locationAuthorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            return "Sky recommendations are using your current coordinates and live conditions."
        case .denied:
            return "Turn on location access in Settings to personalize the sky map."
        case .restricted:
            return "Location access is restricted on this device."
        case .notDetermined:
            return "Allow location access to tailor the sky to your current horizon."
        @unknown default:
            return "Location status is unavailable."
        }
    }

    var objectSearchResults: [SearchableSkyObject] {
        displayedObjectSearchResults
    }

    var astronomyAPIStatusMessage: String {
        if !skyAPIService.hasAstronomyCredentials {
            return "Add AstronomyAPI credentials through build settings or environment variables to enable live astronomy results."
        }

        if !astronomyAPIErrorMessage.isEmpty {
            return astronomyAPIErrorMessage
        }

        return "AstronomyAPI is connected. Search for a planet or look for live badges in tonight's picks."
    }

    var liveVisibleObjectCount: Int {
        visibleObjects.filter { $0.dataSource == .live }.count
    }

    var visibleObjectsStatusMessage: String {
        if liveVisibleObjectCount > 0 {
            return "\(liveVisibleObjectCount) of \(visibleObjects.count) visible picks are live from AstronomyAPI."
        }

        if skyAPIService.hasAstronomyCredentials {
            return "No live planet matches are showing right now, so the guide is filling in the rest."
        }

        return "Visible picks are coming from the built-in sky guide until live astronomy credentials are active."
    }

    func refreshObjectSearch() async {
        let trimmedQuery = objectSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            remoteObjectSearchResults = []
            displayedObjectSearchResults = Array(SearchableSkyObject.catalog.prefix(6))
            isObjectSearchLoading = false
            await enrichDisplayedSearchResults()
            return
        }

        isObjectSearchLoading = true

        if skyAPIService.hasAstronomyCredentials {
            do {
                remoteObjectSearchResults = try await skyAPIService.searchAstronomyObjects(term: trimmedQuery)
                astronomyAPIErrorMessage = ""
            } catch {
                remoteObjectSearchResults = []
                astronomyAPIErrorMessage = error.localizedDescription
            }
        } else {
            remoteObjectSearchResults = []
            astronomyAPIErrorMessage = ""
        }

        displayedObjectSearchResults = baseSearchResults(for: trimmedQuery)
        await enrichDisplayedSearchResults()

        isObjectSearchLoading = false
    }

    private func bindAuthState() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self else { return }

            if let firebaseUser {
                self.feedErrorMessage = ""
                self.startUserListener(for: firebaseUser.uid)
                self.startFeedListener()
            } else {
                self.userListener?.remove()
                self.userListener = nil
                self.feedListener?.remove()
                self.feedListener = nil
                self.stopCommentsListener()
                self.currentUser = nil
                self.feedPosts = []
                self.feedErrorMessage = ""
                self.isFeedLoading = false
            }
        }
    }

    private nonisolated static func feedPost(from document: QueryDocumentSnapshot) -> FeedPost? {
        let data = document.data()

        guard
            let userID = data["userID"] as? String,
            let username = data["username"] as? String,
            let caption = data["caption"] as? String,
            let createdAt = data["createdAt"] as? Timestamp
        else {
            return nil
        }

        let imageBase64 = data["imageBase64"] as? String
        let decodedImageData = imageBase64.flatMap { Data(base64Encoded: $0) }

        return FeedPost(
            id: document.documentID,
            userID: userID,
            username: username,
            caption: caption,
            createdAt: createdAt.dateValue(),
            likes: intValue(from: data["likes"]),
            comments: intValue(from: data["comments"]),
            likedBy: stringArray(from: data["likedBy"]),
            gradient: [
                AstroTheme.primary.opacity(0.9),
                AstroTheme.secondary.opacity(0.8)
            ],
            imageData: decodedImageData,
            imageBase64: imageBase64
        )
    }

    private nonisolated static func postComment(from document: QueryDocumentSnapshot, postID: String) -> PostComment? {
        let data = document.data()

        guard
            let userID = data["userID"] as? String,
            let username = data["username"] as? String,
            let text = data["text"] as? String,
            let createdAt = data["createdAt"] as? Timestamp
        else {
            return nil
        }

        return PostComment(
            id: document.documentID,
            postID: postID,
            userID: userID,
            username: username,
            text: text,
            createdAt: createdAt.dateValue()
        )
    }

    private nonisolated static func intValue(from value: Any?) -> Int {
        if let value = value as? Int {
            return value
        }

        if let value = value as? NSNumber {
            return value.intValue
        }

        return 0
    }

    private nonisolated static func stringArray(from value: Any?) -> [String] {
        if let values = value as? [String] {
            return values
        }

        if let values = value as? [Any] {
            return values.compactMap { $0 as? String }
        }

        return []
    }

    private func startUserListener(for uid: String) {
        userListener?.remove()

        userListener = db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error {
                print("User listener error:", error.localizedDescription)
                return
            }

            guard let snapshot, snapshot.exists, let data = snapshot.data() else {
                return
            }

            let username = data["username"] as? String ?? "Astronomy User"
            let email = data["email"] as? String ?? "user@email.com"

            Task { @MainActor in
                self.currentUser = UserProfile(
                    id: snapshot.documentID,
                    username: username,
                    email: email
                )
                self.loadSavedEvents()
            }
        }
    }

    private var savedEventsStorageKey: String {
        "savedEventIDs.\(currentUser?.id ?? "local")"
    }

    private func loadSavedEvents() {
        let ids = UserDefaults.standard.stringArray(forKey: savedEventsStorageKey) ?? []
        savedEventIDs = Set(ids)
    }

    private func saveSavedEvents() {
        UserDefaults.standard.set(Array(savedEventIDs).sorted(), forKey: savedEventsStorageKey)
    }

    private func baseSearchResults(for query: String) -> [SearchableSkyObject] {
        if !remoteObjectSearchResults.isEmpty {
            return remoteObjectSearchResults
        }

        let normalizedQuery = query.lowercased()
        return SearchableSkyObject.catalog.filter { object in
            object.name.lowercased().contains(normalizedQuery)
            || object.type.lowercased().contains(normalizedQuery)
            || object.tags.contains(where: { $0.lowercased().contains(normalizedQuery) })
            || object.summary.lowercased().contains(normalizedQuery)
        }
    }

    private func enrichDisplayedSearchResults() async {
        let currentResults = displayedObjectSearchResults

        do {
            let enriched = try await skyAPIService.enrichSearchableObjectsWithImages(currentResults)
            guard currentResults.map(\.id) == displayedObjectSearchResults.map(\.id) else { return }
            displayedObjectSearchResults = enriched
        } catch {
            guard currentResults.map(\.id) == displayedObjectSearchResults.map(\.id) else { return }
            displayedObjectSearchResults = currentResults
        }
    }

    private func runAuthAction(_ action: () async throws -> Void) async {
        isLoading = true

        do {
            try await action()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func bindLocationUpdates() {
        locationManager.$authorizationStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                self?.locationAuthorizationStatus = status
                guard self?.activeLocationName == nil else { return }
                self?.refreshSkyData()
            }
            .store(in: &cancellables)

        locationManager.$currentLocation
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard self?.activeLocationName == nil else { return }
                self?.refreshSkyData()
            }
            .store(in: &cancellables)
    }

    private func refreshSkyData() {
        let effectiveCoordinate = locationManager.currentLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 34.05, longitude: -118.24)
        refreshSkyData(using: effectiveCoordinate, coordinateForCopy: locationManager.currentLocation?.coordinate)
    }

    private func refreshSkyData(using effectiveCoordinate: CLLocationCoordinate2D, coordinateForCopy: CLLocationCoordinate2D?) {
        let snapshot = SkyInsightEngine.snapshot(for: Date(), coordinate: coordinateForCopy)
        skySnapshot = snapshot
        visibleObjects = snapshot.visibleObjects
        skyRefreshTask?.cancel()
        skyRefreshTask = Task { [weak self] in
            await self?.loadLiveSkyData(for: effectiveCoordinate, fallbackObjects: snapshot.visibleObjects)
        }
    }

    private func loadLiveSkyData(for coordinate: CLLocationCoordinate2D, fallbackObjects: [CelestialObject]) async {
        isSkyDataLoading = true
        skyDataErrorMessage = ""
        var resolvedConditions = SkyConditions.fallback

        do {
            resolvedConditions = try await skyAPIService.fetchLiveConditions(for: coordinate)
        } catch {
            skyDataErrorMessage = error.localizedDescription
        }

        var liveBodies: [CelestialObject] = []
        if skyAPIService.hasAstronomyCredentials {
            do {
                liveBodies = try await skyAPIService.fetchVisibleBodies(for: coordinate, on: Date())
                astronomyAPIErrorMessage = ""
            } catch {
                astronomyAPIErrorMessage = error.localizedDescription
            }
        } else {
            astronomyAPIErrorMessage = ""
        }

        do {
            let sourceObjects = mergeVisibleObjects(liveBodies: liveBodies, fallbackObjects: fallbackObjects)
            let enrichedObjects = try await skyAPIService.enrichObjectsWithImages(sourceObjects)

            guard !Task.isCancelled else { return }
            skyConditions = resolvedConditions
            visibleObjects = enrichedObjects
        } catch {
            guard !Task.isCancelled else { return }
            skyConditions = resolvedConditions
            visibleObjects = fallbackObjects
            if skyDataErrorMessage.isEmpty {
                skyDataErrorMessage = error.localizedDescription
            }
        }

        isSkyDataLoading = false
    }

    private func mergeVisibleObjects(liveBodies: [CelestialObject], fallbackObjects: [CelestialObject]) -> [CelestialObject] {
        var merged: [CelestialObject] = []
        var seenNames = Set<String>()

        for object in liveBodies + fallbackObjects {
            let key = object.name.lowercased()
            guard !seenNames.contains(key) else { continue }
            merged.append(object)
            seenNames.insert(key)

            if merged.count == 3 {
                break
            }
        }

        return merged
    }
}

final class SkyLocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var currentLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus

    private let manager = CLLocationManager()

    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocationAccess() {
        switch authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Keep the current fallback snapshot if the system cannot provide a location update.
    }
    
    
}
