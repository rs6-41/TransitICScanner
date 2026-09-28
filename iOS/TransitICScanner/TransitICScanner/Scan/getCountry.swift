import Foundation
import MapKit
import CoreLocation
import Combine

@MainActor
final class GetCountry: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()

    @Published private(set) var countryCode: String?
    @Published private(set) var administrativeArea: String?

    private var isDebugMode = false
    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

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
            administrativeArea = nil
            return
        }

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()

        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()

        case .denied, .restricted:
            countryCode = nil
            administrativeArea = nil

        @unknown default:
            countryCode = nil
            administrativeArea = nil
        }
    }

    func debug(country: String) {
        isDebugMode = true
        countryCode = country.lowercased()
        administrativeArea = nil
    }

    func resetDebug() {
        isDebugMode = false
        countryCode = nil
        administrativeArea = nil
        start()
    }

    func fetchCountry() async -> String? {
        guard !isDebugMode else {
            return countryCode
        }

        await fetchLocationAndGeocode()

        return countryCode
    }

    func fetchAdministrativeArea() async -> String? {
        guard !isDebugMode else {
            return administrativeArea
        }

        await fetchLocationAndGeocode()

        return administrativeArea
    }

    private func fetchLocationAndGeocode() async {
        guard CLLocationManager.locationServicesEnabled() else {
            countryCode = nil
            administrativeArea = nil
            return
        }

        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            break

        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            return

        case .denied, .restricted:
            countryCode = nil
            administrativeArea = nil
            return

        @unknown default:
            countryCode = nil
            administrativeArea = nil
            return
        }

        guard let location = await fetchCurrentLocation() else {
            countryCode = nil
            administrativeArea = nil
            return
        }

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location,preferredLocale: Locale(identifier: "en_US"))

            guard let placemark = placemarks.first else {
                countryCode = nil
                administrativeArea = nil
                return
            }

            countryCode = placemark.isoCountryCode?.lowercased()
            administrativeArea = placemark.administrativeArea
        } catch {
            countryCode = nil
            administrativeArea = nil
        }
    }

    private func fetchCurrentLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            locationContinuation?.resume(returning: nil)
            locationContinuation = continuation
            locationManager.requestLocation()
        }
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
            administrativeArea = nil
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil

        @unknown default:
            countryCode = nil
            administrativeArea = nil
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else {
            locationContinuation?.resume(returning: nil)
            locationContinuation = nil
            return
        }

        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        countryCode = nil
        administrativeArea = nil

        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }
}
