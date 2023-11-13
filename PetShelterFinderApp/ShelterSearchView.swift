import SwiftUI

extension Color {
    static let lightBlue = Color(red: 173/255, green: 216/255, blue: 230/255)
    static let lightGray = Color.gray.opacity(0.3)
}


struct ShelterSearchView: View {
    @ObservedObject var viewModel = ShelterViewModel()
    @State private var searchText: String = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 15) {
                    TextField("Enter City", text: $searchText, onCommit: {
                        viewModel.searchForShelters(in: searchText)
                    })
                    .padding(15)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(color: .gray, radius: 5, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    
                    LazyVStack(spacing: 15) {
                        ForEach(viewModel.shelters) { shelter in
                            NavigationLink(destination: ShelterDetailView(viewModel: viewModel, shelter: shelter)) {
                                ShelterRow(shelter: shelter)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .background(Color.white.ignoresSafeArea())
            .navigationBarTitle("Find Animal Shelter", displayMode: .inline)
            
        }
    }
    
    
    struct ShelterRow: View {
        var shelter: Shelter
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(shelter.name)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(Color.black)
                    Text("\(shelter.address.city), \(shelter.address.state)")
                        .font(.subheadline)
                        .foregroundColor(Color.black)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundColor(Color.lightBlue)
            }
            .padding(15)
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: .gray, radius: 5, x: 0, y: 5)
        }
    }
    
    struct ShelterDetailView: View {
        @ObservedObject var viewModel: ShelterViewModel
        var shelter: Shelter
        @State private var detailedShelter: Shelter?
        @State private var detailSearchText: String = ""
        
        var body: some View {
            ScrollView {
                VStack(spacing: 20) {
                    Text(shelter.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.lightBlue)
                    
                    if let distance = shelter.distance {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(Color.lightBlue)
                            Text(String(format: "%.2f miles away", distance))
                                .font(.subheadline)
                        }
                    }
                    
                    if let email = shelter.email, !email.isEmpty {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(Color.lightBlue)
                            Text(email)
                                .font(.subheadline)
                        }
                    }
                    
                    if let phone = shelter.phone, !phone.isEmpty {
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(Color.lightBlue)
                            Text(phone)
                                .font(.subheadline)
                        }
                    }
                    
                    
                    Text("\(shelter.address.address1 ?? "")  \(shelter.address.city), \(shelter.address.state) \(shelter.address.postcode)")

                        .font(.body)
                        .foregroundColor(Color.black.opacity(0.6))
                    
                        .cornerRadius(10)
                    
                    if !shelter.nonNullHours.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Operating Hours:")
                                .font(.headline)
                                .foregroundColor(Color.lightBlue)
                            ForEach(shelter.nonNullHours, id: \.self) { hour in
                                Text(hour)
                            }
                        }
                    }
                    
                    if let officialUrl = shelter.url,
                                       let officialUrlObject = URL(string: officialUrl),
                                       UIApplication.shared.canOpenURL(officialUrlObject) {
                                        Button(action: {
                                            UIApplication.shared.open(officialUrlObject)
                                        }) {
                                            Text("Official Page")
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .padding()
                                                .background(Color.lightBlue)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                    }
                                    
                    if let websiteUrl = shelter.website,
                                       let websiteUrlObject = URL(string: websiteUrl),
                                       UIApplication.shared.canOpenURL(websiteUrlObject) {
                                        Button(action: {
                                            UIApplication.shared.open(websiteUrlObject)
                                        }) {
                                            Text("Website")
                                                .frame(minWidth: 0, maxWidth: .infinity)
                                                .padding()
                                                .background(Color.lightBlue)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                        }
                                    }
                        
                        
                        NavigationLink(destination: ShelterAnimalsView(shelterId: shelter.id)) {
                            Text("Adopt Me")
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        
                        
                    }
                    .padding()
                    .navigationBarTitle("Shelter Details", displayMode: .inline)
                    .onAppear {
                        viewModel.fetchOrganizationDetails(id: shelter.id) { fetchedShelter in
                            self.detailedShelter = fetchedShelter
                        }
                    }
                }
                .background(Color.white.ignoresSafeArea())
            }
        }
        
        struct ShelterAnimalsView: View {
            var shelterId: String
            @ObservedObject var viewModel = ShelterAnimalsViewModel()
            @State private var hasFetched: Bool = false  // Set this to true temporarily
            @State private var isLoading: Bool = false
            
            
            var body: some View {
                
                VStack {
                    if isLoading {
                        ProgressView("Loading animals...")
                    } else if viewModel.animals.isEmpty && hasFetched {
                        // Use the custom message directly instead of checking for the error message
                        Text("No pets available for adoption.")
                            .font(.headline)
                            .padding()
                    } else {
                        List(viewModel.animals) { animal in
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    AsyncImage(url: URL(string: animal.photos.first?.medium ?? "")) { phase in
                                        switch phase {
                                        case .empty:
                                            RoundedRectangle(cornerRadius: 10)
                                                .frame(width: 70, height: 70)
                                                .foregroundColor(.gray)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFit()
                                                .frame(width: 70, height: 70)
                                                .cornerRadius(10)
                                        case .failure:
                                            RoundedRectangle(cornerRadius: 10)
                                                .frame(width: 70, height: 70)
                                                .foregroundColor(.gray)
                                        @unknown default:
                                            RoundedRectangle(cornerRadius: 10)
                                                .frame(width: 70, height: 70)
                                                .foregroundColor(.gray)
                                        }
                                    }
                                    
                                    
                                    VStack(alignment: .leading) {
                                        if let error = viewModel.errorMessage {
                                            Text(error).foregroundColor(.red).padding()
                                        }
                                        Text(animal.name).font(.headline)
                                        Text(animal.species).font(.subheadline)
                                    }
                                }
                                
                                
                                HStack {
                                    Text("Breeds:").bold()
                                    Text("\(animal.breeds.primary ?? "Unknown"), \(animal.breeds.secondary ?? "N/A")")
                                }
                                
                                // Colors
                                HStack {
                                    Text("Colors:").bold()
                                    Text("\(animal.colors.primary ?? "Unknown")")
                                }
                                
                                // Age, Gender, Size
                                Text("\(animal.age) - \(animal.gender) - \(animal.size)")
                                
                                // Description
                                if let description = animal.description {
                                    Text(description).font(.caption)
                                }
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text("Neutered:").bold()
                                        Text(animal.attributes.spayed_neutered ? "Yes" : "No")
                                    }
                                    HStack {
                                        Text("House Trained:").bold()
                                        Text(animal.attributes.house_trained ? "Yes" : "No")
                                    }
                                    HStack {
                                        Text("Declawed:").bold()
                                        Text(animal.attributes.declawed ? "Yes" : "No")
                                    }
                                    HStack {
                                        Text("Special Needs:").bold()
                                        Text(animal.attributes.special_needs ? "Yes" : "No")
                                    }
                                    HStack {
                                        Text("Shots Current:").bold()
                                        Text(animal.attributes.shots_current ? "Yes" : "No")
                                    }
                                }
                                
                                
                                
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Text("Compatible with children:").bold()
                                            .lineLimit(nil)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Text(animal.environment.children == true ? "Yes" : animal.environment.children == false ? "No" : "Unknown")
                                    }
                                    HStack {
                                        Text("Compatible with dogs:").bold()
                                        Text(animal.environment.dogs == true ? "Yes" : animal.environment.dogs == false ? "No" : "Unknown")
                                    }
                                    HStack {
                                        Text("Compatible with cats:").bold()
                                        Text(animal.environment.cats == true ? "Yes" : animal.environment.cats == false ? "No" : "Unknown")
                                    }
                                }
                                
                                
                                
                            }.padding()
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(color: .gray, radius: 5, x: 0, y: 5)
                                .padding(.horizontal)
                        }
                    }
                }
                .onAppear {
                    isLoading = true
                    viewModel.fetchAnimalsForShelter(shelterId: shelterId) {
                        self.isLoading = false
                        self.hasFetched = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if !self.hasFetched && viewModel.animals.isEmpty {
                            self.isLoading = false
                            self.hasFetched = true
                        }
                    }
                }
                
            }
        }
    }
    
    
    
    



