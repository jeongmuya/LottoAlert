import CoreLocation

class GeocodingService {
    let geocoder = CLGeocoder()
    
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            guard let location = placemarks.first?.location?.coordinate else {
                throw GeocodingError.noLocation
            }
            return location
        } catch {
            throw GeocodingError.geocodingFailed(error)
        }
    }
    
    enum GeocodingError: Error {
        case noLocation
        case geocodingFailed(Error)
    }
} 