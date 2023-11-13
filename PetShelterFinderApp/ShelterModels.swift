// ShelterModels.swift

import Foundation

struct ShelterResponse: Codable {
    let organizations: [Shelter]
}

struct Shelter: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let email: String?
    let phone: String?
    let address: Address
    let hours: [String: String?]
    let url: String?
    let website: String?
    let mission_statement: String?
    let photos: [Photo]
    let distance: Double?



    var formattedAddress: String {
        return [
            address.address1,
            address.city,
            address.state,
            address.postcode,
            address.country
        ].compactMap { $0 }.joined(separator: ", ")
    }
    var nonNullHours: [String] {
        return hours.compactMap { key, value in
            if let val = value {
                return "\(key): \(val)"
            } else {
                return nil
            }
        }
    }
    
    // Equatable
    static func == (lhs: Shelter, rhs: Shelter) -> Bool {
        return lhs.id == rhs.id
    }

    // Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}



struct Address: Codable {
    let address1: String?
    let city: String
    let state: String
    let postcode: String
    let country: String
}

struct Photo: Codable {
    let small: String
    let medium: String
    let large: String
    let full: String
}
