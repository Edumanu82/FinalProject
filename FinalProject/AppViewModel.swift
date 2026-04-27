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

    let authService = AstronomyAuthService()
    let upcomingEvents = EventCard.sampleData
    let feedPosts = FeedPost.sampleData

    private let locationManager = SkyLocationManager()
    private let skyAPIService = SkyAPIService()
    private let db = Firestore.firestore()

    private var cancellables = Set<AnyCancellable>()
    private var skyRefreshTask: Task<Void, Never>?
    private var userListener: ListenerRegistration?
    private var authStateHandle: AuthStateDidChangeListenerHandle?

    init() {
        bindLocationUpdates()
        bindAuthState()
        refreshSkyData()

        Task { [weak self] in
            await self?.refreshObjectSearch()
        }
    }

    deinit {
        userListener?.remove()

        if let authStateHandle {
            Auth.auth().removeStateDidChangeListener(authStateHandle)
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
            startUserListener(for: user.id)
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
            startUserListener(for: user.id)
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
        currentUser = nil
        loginPassword = ""
        signUpPassword = ""
        confirmPassword = ""
        selectedTab = .home
        authMode = .login
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
                self.startUserListener(for: firebaseUser.uid)
            } else {
                self.userListener?.remove()
                self.userListener = nil
                self.currentUser = nil
            }
        }
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
            }
        }
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
