import Foundation
import MapKit
import CoreLocation
import Combine

@MainActor
final class GetCountry: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published private(set) var countryCode: String?

    private var isDebugMode = false

    override init() {
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func start() {
        guard !isDebugMode else {
            return
        }

        guard CLLocationManager.locationServicesEnabled() else {
            countryCode = nil
            return
        }

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()

        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()

        case .denied, .restricted:
            countryCode = nil

        @unknown default:
            countryCode = nil
        }
    }

    func debug(country: String) {
        isDebugMode = true
        countryCode = country.lowercased()
    }

    func resetDebug() {
        isDebugMode = false
        countryCode = nil
        start()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard !isDebugMode else {
            return
        }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()

        case .notDetermined:
            manager.requestWhenInUseAuthorization()

        case .denied, .restricted:
            countryCode = nil

        @unknown default:
            countryCode = nil
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard !isDebugMode else {
            return
        }

        guard let location = locations.last else {
            return
        }

        Task {
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)

                guard let isoCountryCode = placemarks.first?.isoCountryCode else {
                    countryCode = nil
                    return
                }

                countryCode = isoCountryCode.lowercased()
            } catch {
                countryCode = nil
            }
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        guard !isDebugMode else {
            return
        }

        countryCode = nil
    }
}
