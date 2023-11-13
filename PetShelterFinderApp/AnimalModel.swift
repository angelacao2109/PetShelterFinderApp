// AnimalModel.swift

import Foundation

struct AnimalResponse: Codable {
    let animals: [Animal]
}

struct Animal: Codable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let species: String
    let breeds: Breeds
    let colors: Colors
    let age: String
    let gender: String
    let size: String
    let description: String?
    let photos: [Photo]
    let status: String
    let attributes: Attributes
    let environment: Environment
    let tags: [String]
    let contact: Contact
    
    struct Breeds: Codable {
        let primary: String?
        let secondary: String?
        let mixed: Bool
        let unknown: Bool
    }
    
    struct Colors: Codable {
        let primary: String?
        let secondary: String?
        let tertiary: String?
    }
    
    struct Attributes: Codable {
        let spayed_neutered: Bool
        let house_trained: Bool
        let declawed: Bool
        let special_needs: Bool
        let shots_current: Bool
    }
    
    struct Environment: Codable {
        let children: Bool?
        let dogs: Bool?
        let cats: Bool?
    }
    
    struct Contact: Codable {
        let email: String?
        let phone: String?
        let address: Address
    }
}
