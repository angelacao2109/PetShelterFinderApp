import Foundation

class ShelterViewModel: ObservableObject {
    
    struct APIErrorResponse: Codable {
        let type: String
        let status: Int
        let title: String
        let detail: String
        let invalidParams: [InvalidParam]
        
        enum CodingKeys: String, CodingKey {
            case type, status, title, detail
            case invalidParams = "invalid-params"
        }
    }
    
    struct InvalidParam: Codable {
        let inParam: String
        let path: String
        let message: String
        
        enum CodingKeys: String, CodingKey {
            case inParam = "in"
            case path, message
        }
    }
    
    struct Pagination: Codable {
        let current_page: Int
        let total_pages: Int
    }
    
    struct ShelterResponse: Codable {
        let organizations: [Shelter]
        let pagination: Pagination
    }
    
    struct OrganizationResponse: Codable {
        let organization: Shelter
    }
    
    @Published private var accessToken: String? = nil
    @Published var shelters: [Shelter] = []
    @Published var errorMessage: String? = nil
    @Published var currentPage: Int = 1
    @Published var totalPages: Int = 1
    
        
    func searchForShelters(in city: String) {
            if !isValidLocation(city) {
                self.errorMessage = "Invalid location format."
                return
            }
            
        if accessToken == nil {
            fetchAccessToken {
                self.actualShelterSearch(in: city)
            }
        } else {
            self.actualShelterSearch(in: city)
        }


        }
    
    func isValidLocation(_ location: String) -> Bool {
        // Regular expression for city, state
        let cityStatePattern = "^[a-zA-Z\\s]+,\\s*[a-zA-Z]{2}$"

        
        // Regular expression for latitude, longitude
        let latLongPattern = "^[-+]?([1-8]?\\d(\\.\\d+)?|90(\\.0+)?),\\s*[-+]?(180(\\.0+)?|((1[0-7]\\d)|([1-9]?\\d))(\\.\\d+)?)$"
        
        // Regular expression for postal code (US format)
        let postalCodePattern = "^\\d{5}(-\\d{4})?$"
        
        
        if location.range(of: cityStatePattern, options: .regularExpression) != nil {
            return true
        } else if location.range(of: latLongPattern, options: .regularExpression) != nil {
            return true
        } else if location.range(of: postalCodePattern, options: .regularExpression) != nil {
            return true
        }
        
        return false
    }
    
    private func actualShelterSearch(in city: String) {
        let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? city
        let urlString = "https://api.petfinder.com/v2/organizations?location=\(encodedCity)&limit=20&page=\(currentPage)"
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let strongSelf = self, let data = data else { return }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                // Handle API error response
                if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                    DispatchQueue.main.async {
                        strongSelf.errorMessage = apiError.detail
                    }
                }
                return
            }
            
            do {
                let shelterData = try JSONDecoder().decode(ShelterResponse.self, from: data)
                              DispatchQueue.main.async {
                                  self?.shelters = shelterData.organizations
                                  // New Code: Fetch detailed data for each shelter
                                  for shelter in shelterData.organizations {
                                      self?.fetchOrganizationDetails(id: shelter.id) { detailedShelter in
                                          if let detailed = detailedShelter, let index = self?.shelters.firstIndex(where: { $0.id == detailed.id }) {
                                              self?.shelters[index] = detailed
                                          }
                                      }
                                  }
                }
            } catch let decodingError {
                print("Decoding failed with error: \(decodingError)")
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let message = json["message"] as? String {
                    DispatchQueue.main.async {
                        strongSelf.errorMessage = message
                    }
                } else {
                    DispatchQueue.main.async {
                        strongSelf.errorMessage = "Failed to load shelters."
                    }
                }
            }
        }.resume()
        
    }
    func fetchOrganizationDetails(id: String, completion: @escaping (Shelter?) -> Void) {
        let urlString = "https://api.petfinder.com/v2/organizations/\(id)"

        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error:", error ?? "Unknown error")
                completion(nil)
                return
            }

            if let organization = try? JSONDecoder().decode(OrganizationResponse.self, from: data) {
                DispatchQueue.main.async {
                    completion(organization.organization)
                }
            } else {
                completion(nil)
            }
        }.resume()
    }


    func fetchAccessToken(completion: @escaping () -> Void) {
        let clientID = "iC5yARokkcelcoNEQ4NRaTA2Djni8U5h4Qe2cHjunKiibX52gT"
        let clientSecret = "Nfy0nkFIt948SUlPmYITE8VP5bcKXB3rfY3z7vsx"
        
        let url = URL(string: "https://api.petfinder.com/v2/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "grant_type=client_credentials&client_id=\(clientID)&client_secret=\(clientSecret)"
        request.httpBody = body.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                print("Error:", error ?? "Unknown error")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = json["access_token"] as? String {
                    DispatchQueue.main.async {
                        self?.accessToken = token
                        print(token)
                        completion()
                    }
                }
            } catch let parseError {
                print("Parsing error: \(parseError)")
            }
        }
        task.resume()
    }
}

class ShelterAnimalsViewModel: ObservableObject {
    @Published var animals: [Animal] = []
    @Published private var accessToken: String? = nil
    @Published var errorMessage: String? = nil
    
    func fetchAnimalsForShelter(shelterId: String, completion: @escaping () -> Void) {
        if accessToken == nil {
                fetchAccessToken {
                    self.actualAnimalSearch(for: shelterId, completion: completion)
                }
            } else {
                self.actualAnimalSearch(for: shelterId, completion: completion)
            }
        }

    private func actualAnimalSearch(for shelterId: String, completion: @escaping () -> Void) {
        let urlString = "https://api.petfinder.com/v2/animals?organization=\(shelterId)&limit=20"
           
        guard let url = URL(string: urlString) else {
            self.errorMessage = "Invalid URL"
            return
        }
               
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        if let token = accessToken {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, _ in
            guard let strongSelf = self else { return }

            // If data is nil, print and set an error message
            guard let data = data else {
                DispatchQueue.main.async {
                    strongSelf.errorMessage = "Failed to fetch data from the server."
                }
                print("No data returned from the API")
                return
            }

            // Print raw API response
            print(String(data: data, encoding: .utf8) ?? "No data")

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                // Handle API error response
                if let apiError = try? JSONDecoder().decode(ShelterViewModel.APIErrorResponse.self, from: data) {
                    DispatchQueue.main.async {
                        strongSelf.errorMessage = apiError.detail
                        print("API Error: \(apiError.detail)") // Print API error
                    }
                }
                return
            }

            do {
                    let animalData = try JSONDecoder().decode(AnimalResponse.self, from: data)
                    DispatchQueue.main.async {
                        self?.animals = animalData.animals
                        print("Fetched \(animalData.animals.count) animals") // Print number of fetched animals
                        completion()
                    }
                } catch {
                print("Decoding failed with error: \(error)") // Print decoding error
                DispatchQueue.main.async {
                    strongSelf.errorMessage = "Failed to load animals."
                }
            }
        }.resume()
    }

    private func fetchAccessToken(completion: @escaping () -> Void) {
        // ... [same as in ShelterViewModel]
        let clientID = "iC5yARokkcelcoNEQ4NRaTA2Djni8U5h4Qe2cHjunKiibX52gT"
        let clientSecret = "Nfy0nkFIt948SUlPmYITE8VP5bcKXB3rfY3z7vsx"
        
        let url = URL(string: "https://api.petfinder.com/v2/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let body = "grant_type=client_credentials&client_id=\(clientID)&client_secret=\(clientSecret)"
        request.httpBody = body.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                print("Error:", error ?? "Unknown error")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let token = json["access_token"] as? String {
                    DispatchQueue.main.async {
                        self?.accessToken = token
                    
                        completion()
                    }
                }
            } catch let parseError {
                print("Parsing error: \(parseError)")
            }
        }
        task.resume()
    }
}


