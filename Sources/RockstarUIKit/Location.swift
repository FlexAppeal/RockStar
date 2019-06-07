//import CoreLocation
//import Foundation
//import Rockstar
//
//struct LocationUnavailable: Error {}
//
//public struct Location: Codable {
//    let latitude: Double
//    let longitude: Double
//
//    var speed: Double?
//    var accuracy: Double?
//    var direction: Double?
//    var altitude: Double?
//    var altitudeAccuracy: Double?
//    var measurementTime: Date
//
//    public init(latitude: Double, longitude: Double) {
//        self.latitude = latitude
//        self.longitude = longitude
//        self.measurementTime = Date()
//    }
//}
//
//extension CLLocation {
//    var rockstarLocation: Location {
//        var location = Location(
//            latitude: self.coordinate.latitude,
//            longitude: self.coordinate.longitude
//        )
//
//        location.measurementTime = self.timestamp
//
//        location.altitude = self.altitude
//        location.altitudeAccuracy = self.verticalAccuracy
//
//        location.accuracy = self.horizontalAccuracy
//        location.speed = self.speed
//        location.direction = self.course
//
//        return location
//    }
//}
//
//@available(iOS 9.0, *)
//public final class LocationManager: NSObject, CLLocationManagerDelegate {
//    let manager: CLLocationManager
//    private let locationStream = WriteStream<Location>()
//
//    public var locationChanges: ReadStream<Location> {
//        manager.startUpdatingLocation()
//
//        return locationStream.listener
//    }
//
//    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        guard let location = locations.last else { return }
//
//        locationStream.next(location.rockstarLocation)
//    }
//
//    public init(
//        reason: LocationReason,
//        accuracy: LocationAccuracy = .best,
//        minimumFluctuation: Double = kCLDistanceFilterNone,
//        alwaysAccessible: Bool = false
//    ) {
//        manager = CLLocationManager()
//        manager.allowsBackgroundLocationUpdates = true
//        manager.desiredAccuracy = accuracy.clAccuracy
//        manager.activityType = reason.clReason
//        manager.distanceFilter = minimumFluctuation
//
//        super.init()
//
//        manager.delegate = self
//
//        if CLLocationManager.authorizationStatus() == .notDetermined {
//            if alwaysAccessible {
//                manager.requestAlwaysAuthorization()
//            } else {
//                manager.requestWhenInUseAuthorization()
//            }
//        }
//    }
//
//    deinit {
//        manager.stopUpdatingLocation()
//    }
//}
//
//public enum LocationReason {
//    case fitness
//
//    var clReason: CLActivityType {
//        switch self {
//        case .fitness:
//            return .fitness
//        }
//    }
//}
//
//public enum LocationAccuracy {
//   case best, tenMeters, hundredMeters, oneKilometer, threeKilometers
//
//    var clAccuracy: CLLocationAccuracy {
//        switch self {
//        case .best:
//            return kCLLocationAccuracyBest
//        case .tenMeters:
//            return kCLLocationAccuracyNearestTenMeters
//        case .hundredMeters:
//            return kCLLocationAccuracyHundredMeters
//        case .oneKilometer:
//            return kCLLocationAccuracyKilometer
//        case .threeKilometers:
//            return kCLLocationAccuracyThreeKilometers
//        }
//    }
//}
