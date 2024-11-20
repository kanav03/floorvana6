import Foundation
import UIKit

class DataModelMyProject {
    
    struct ProjectDetails: Codable {
        var imageName: String
        var type: String
        var createdOn: String
        var area: String
        var bedrooms: String
        var kitchen: String
        var bathrooms: String
        var livingRoom: String
        var diningRoom: String
        var studyRoom: String
        var entry: String
        var vastu: String
    }
    
   
    static let shared = DataModelMyProject()
    
    private(set) var photos: [ProjectDetails] = []
    
    private init() {
        loadFromPersistence()
    }
    
    func getPhotos() -> [ProjectDetails] {
        return photos
    }
    
    func getPhoto(at index: Int) -> ProjectDetails {
        return photos[index]
    }
    
    func removePhoto(at index: Int) {
        if index >= 0 && index < photos.count {
            photos.remove(at: index)
            saveToPersistence()
        }
    }
    
    
    func addProject(_ project: ProjectDetails) {
        photos.append(project)
        saveToPersistence()
        print("Added project: \(project)")
    }
    
  
    private func saveToPersistence() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(photos)
            UserDefaults.standard.set(data, forKey: "savedProjects")
            print("Projects successfully saved to UserDefaults.")
        } catch {
            print("Failed to encode project data: \(error.localizedDescription)")
        }
    }
    

    private func loadFromPersistence() {
        if let data = UserDefaults.standard.data(forKey: "savedProjects") {
            let decoder = JSONDecoder()
            do {
                photos = try decoder.decode([ProjectDetails].self, from: data)
                print("Loaded projects from UserDefaults: \(photos)")
            } catch {
                print("Failed to decode project data: \(error.localizedDescription)")
            }
        } else {
        
            photos = [
                ProjectDetails(
                    imageName: "Plus",
                    type: "     Add New Project",
                    createdOn: "",
                    area: "",
                    bedrooms: "",
                    kitchen: "",
                    bathrooms: "",
                    livingRoom: "",
                    diningRoom: "",
                    studyRoom: "",
                    entry: "",
                    vastu: ""
                )
            ]
        }
    }
}


//ProjectDetails(imageName: "Plus", type: "     Add New Project", createdOn: "", area: "", bedrooms: "", kitchen: "", bathrooms: "", livingRoom: "", diningRoom: "", studyRoom: "", entry: "", vastu: ""),
//        ProjectDetails(imageName: "myProject1", type: "2BHK", createdOn: "01/11/2024", area: "1200 sq ft", bedrooms: "2", kitchen: "1", bathrooms: "2", livingRoom: "1", diningRoom: "1", studyRoom: "1", entry: "1", vastu: "Yes"),
//        ProjectDetails(imageName: "myProject2", type: "3BHK", createdOn: "05/11/2024", area: "1500 sq ft", bedrooms: "3", kitchen: "1", bathrooms: "3", livingRoom: "1", diningRoom: "1", studyRoom: "0", entry: "2", vastu: "No"),
//        ProjectDetails(imageName: "myProject3", type: "4BHK", createdOn: "10/11/2024", area: "2000 sq ft", bedrooms: "4", kitchen: "1", bathrooms: "4", livingRoom: "1", diningRoom: "1", studyRoom: "1", entry: "1", vastu: "Yes"),
//        ProjectDetails(imageName: "myProject4", type: "4BHK", createdOn: "10/11/2024", area: "2000 sq ft", bedrooms: "4", kitchen: "1", bathrooms: "4", livingRoom: "1", diningRoom: "1", studyRoom: "1", entry: "1", vastu: "Yes"),
//        ProjectDetails(imageName: "myProject5", type: "4BHK", createdOn: "10/11/2024", area: "2000 sq ft", bedrooms: "4", kitchen: "1", bathrooms: "4", livingRoom: "1", diningRoom: "1", studyRoom: "1", entry: "1", vastu: "Yes"),
//        ProjectDetails(imageName: "myProject6", type: "4BHK", createdOn: "10/11/2024", area: "2000 sq ft", bedrooms: "4", kitchen: "1", bathrooms: "4", livingRoom: "1", diningRoom: "1", studyRoom: "1", entry: "1", vastu: "Yes"),
//        ProjectDetails(imageName: "myProject7", type: "4BHK", createdOn: "10/11/2024", area: "2000 sq ft", bedrooms: "4", kitchen: "1", bathrooms: "4", livingRoom: "1", diningRoom: "1", studyRoom: "1", entry: "1", vastu: "Yes")
