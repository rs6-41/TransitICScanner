import SwiftUI
import Combine
import AppTrackingTransparency
import AdSupport
import CoreLocation
import UserNotifications
import Foundation
import CoreNFC

@MainActor
final class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var completion: (() -> Void)?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestAuthorization(completion: @escaping () -> Void) {
        self.completion = completion

        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        default:
            self.completion = nil
            completion()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard manager.authorizationStatus != .notDetermined else {
            return
        }

        let completion = self.completion
        self.completion = nil
        completion?()
    }
}

struct PermissionModalView: View {
    @Binding var isPresented: Bool
    @State private var path: [Int] = []
    @State private var locationManager = LocationPermissionManager()

    let lastPath = 5

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                if let content = getPermissionContent(value: 0) {
                    PermissionView(
                        content: content,
                        path: $path,
                        lastPath: lastPath,
                        isPresented: $isPresented
                    )
                }
            }
            .navigationDestination(for: Int.self) { number in
                if let content = getPermissionContent(value: number) {
                    PermissionView(
                        content: content,
                        path: $path,
                        lastPath: lastPath,
                        isPresented: $isPresented
                    )
                } else {
                    if let content = getPermissionContent(value: lastPath) {
                        PermissionView(
                            content: content,
                            path: $path,
                            lastPath: lastPath,
                            isPresented: $isPresented
                        )
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .frame(maxWidth: 500)
            .padding()
        }
    }

    func getPermissionContent(value: Int) -> PermissionModel? {
        if value == 0 {
            return PermissionModel(
                title: "appName",
                imageName: "intro",
                description: "permission.first.description",
                descriptionRed: nil,
                action: { completion in
                    completion()
                }
            )
        }

        if value == 1 {
            if NFCNDEFReaderSession.readingAvailable {
                return PermissionModel(
                    title: "permission.nfc",
                    imageName: "intro_nfc_corenfc",
                    description: "permission.nfc.corenfc.description",
                    descriptionRed: nil,
                    action: { completion in
                        completion()
                    }
                )
            } else {
                return PermissionModel(
                    title: "permission.nfc",
                    imageName: "intro_nfc_external",
                    description: "permission.nfc.external.description",
                    descriptionRed: nil,
                    action: { completion in
                        completion()
                    }
                )
            }
        }

        if value == 2 {
            return PermissionModel(
                title: "permission.gps.title",
                imageName: "permission_GPS",
                description: "permission.gps.description",
                descriptionRed: nil,
                icon: "location.fill",
                fill: Color.blue,
                action: { completion in
                    locationManager.requestAuthorization(completion: completion)
                }
            )
        }

        if value == 3 {
            return PermissionModel(
                title: "permission.notifications.title",
                imageName: "permission_Notifications",
                description: "permission.notifications.description",
                descriptionRed: nil,
                icon: "bell.badge.fill",
                fill: Color.red,
                action: { completion in
                    let center = UNUserNotificationCenter.current()

                    center.getNotificationSettings { settings in
                        if settings.authorizationStatus == .notDetermined {
                            center.requestAuthorization(options: [.alert, .badge]) { _, error in
                                if let error {
                                    Log.debug("Notification authorization error: \(error.localizedDescription)")
                                }

                                DispatchQueue.main.async {
                                    completion()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                completion()
                            }
                        }
                    }
                }
            )
        }

        if value == 4 {
            let attStatus = ATTrackingManager.trackingAuthorizationStatus

            if attStatus != .restricted && attStatus != .denied {
                return PermissionModel(
                    title: "permission.att.title",
                    imageName: "permission_ATT",
                    description: "permission.att.description",
                    descriptionRed: "permission.att.description.ifDenied",
                    icon: "flag.fill",
                    fill: Color.orange,
                    action: { completion in
                        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
                            completion()
                            return
                        }

                        ATTrackingManager.requestTrackingAuthorization { status in
                            switch status {
                            case .authorized:
                                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                                Log.debug("ATT: Authorized: \(idfa)")
                            case .denied:
                                Log.debug("ATT: Denied")
                            case .notDetermined:
                                Log.debug("ATT: Not Determined")
                            case .restricted:
                                Log.debug("ATT: Restricted")
                            @unknown default:
                                break
                            }

                            DispatchQueue.main.async {
                                completion()
                            }
                        }
                    }
                )
            } else {
                return nil
            }
        }

        if value == lastPath {
            return PermissionModel(
                title: "permission.done",
                imageName: "permission_last",
                description: "permission.done.description",
                descriptionRed: nil,
                icon: "checkmark",
                color: Color.green,
                action: { completion in
                    isPresented = false
                    completion()
                }
            )
        }

        return nil
    }
}

struct PermissionModel {
    var title: LocalizedStringKey
    var imageName: String
    var description: String.LocalizationValue
    var descriptionRed: String.LocalizationValue?
    var icon: String?
    var fill: Color?
    var color: Color?
    var action: (@escaping () -> Void) -> Void
}

struct PermissionView: View {
    var content: PermissionModel
    @Binding var path: [Int]
    let lastPath: Int
    @Binding var isPresented: Bool

    @State var animate = true

    @State var description: AttributedString = ""

    var body: some View {
        VStack {
            ScrollView {
                Spacer()
                    .frame(height: 50)

                VStack(spacing: 0) {
                    HStack(spacing: 3) {
                        if let icon = content.icon {
                            if let fill = content.fill {
                                SquareIcon(systemImage: icon, color: fill)
                                    .symbolEffect(.drawOn.byLayer, options: .nonRepeating, isActive: animate)
                            } else if let color = content.color {
                                Image(systemName: icon)
                                    .symbolEffect(.drawOn.byLayer, options: .nonRepeating, isActive: animate)
                                    .foregroundStyle(color)
                                    .bold()
                                    .font(.title)
                            }
                        }
                        Text(content.title)
                            .bold()
                            .font(.title)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .onAppear() {
                        if let fill = content.fill {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                animate = false
                            }
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                animate = false
                            }
                        }
                    }
                    ZStack {
                        Color.white
                            .opacity(0.00001)
                            .frame(maxWidth: .infinity)
                        Image(content.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                    }
                }

                if let descriptionRed = content.descriptionRed {
                    Text(description)
                        .onAppear() {
                            var text1 = AttributedString(String(localized: content.description))
                            var text2 = AttributedString(String(localized: descriptionRed))
                            text2.foregroundColor = .red
                            description = text1 + "\n" + text2
                        }
                } else {
                    Text(String(localized: content.description))
                }
            }

            Spacer()

            Button(action: {
                content.action {
                    DispatchQueue.main.async {
                        move()
                    }
                }
            }) {
                Text(LocalizedStringKey("permission.continue"))
                    .bold()
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle)
            .padding(10)
        }
        .toolbar(.hidden, for: .navigationBar)
        .frame(maxWidth: 500)
        .padding()
    }

    func move() {
        if (path.last ?? 0) >= lastPath {
            isPresented = false
        } else {
            path.append((path.last ?? 0) + 1)
        }
    }
}

#Preview {
    PermissionModalView(isPresented: .constant(true))
}
