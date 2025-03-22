import Foundation
import UIKit
import FirebaseFirestore


class DataModelMyProject {
    
    struct ProjectDetails: Codable {
        var documentID: String?
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
    
    func clearProjects() {
            photos.removeAll()
            saveToPersistence()
        }
    func deleteProjectFromFirestore(documentID: String, completion: @escaping (Bool) -> Void) {
           let db = Firestore.firestore()
           db.collection("projects").document(documentID).delete { error in
               if let error = error {
                   print("Error deleting project from Firestore: \(error.localizedDescription)")
                   completion(false)
               } else {
                   print("Project successfully deleted from Firestore.")
                   completion(true)
               }
           }
       }
//    private func saveToPersistence() {
//        let encoder = JSONEncoder()
//        do {
//            let data = try encoder.encode(photos)
//            UserDefaults.standard.set(data, forKey: "savedProjects")
//            print("Projects successfully saved to UserDefaults.")
//        } catch {
//            print("Failed to encode project data: \(error.localizedDescription)")
//        }
//    }
    private func saveToPersistence() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(photos)
            UserDefaults.standard.set(data, forKey: "savedProjects")
            print("Projects successfully saved to UserDefaults. Total projects: \(photos.count)")
        } catch {
            print("Failed to encode project data: \(error.localizedDescription)")
        }
    }
    
//    private func loadFromPersistence() {
//        if let data = UserDefaults.standard.data(forKey: "savedProjects") {
//            let decoder = JSONDecoder()
//            do {
//                photos = try decoder.decode([ProjectDetails].self, from: data)
//                print("Loaded projects from UserDefaults: \(photos)")
//            } catch {
//                print("Failed to decode project data: \(error.localizedDescription)")
//            }
//        } else {
//            photos = [
//                ProjectDetails(
//                    imageName: "",
//                    type: "",
//                    createdOn: "",
//                    area: "",
//                    bedrooms: "",
//                    kitchen: "",
//                    bathrooms: "",
//                    livingRoom: "",
//                    diningRoom: "",
//                    studyRoom: "",
//                    entry: "",
//                    vastu: ""
//                )
//            ]
//        }
//    }
    
    func reloadData() {
        loadFromPersistence()
    }
    
    private func loadFromPersistence() {
        if let data = UserDefaults.standard.data(forKey: "savedProjects") {
            let decoder = JSONDecoder()
            do {
                photos = try decoder.decode([ProjectDetails].self, from: data)
                print("Loaded projects from UserDefaults. Total projects: \(photos.count)")
            } catch {
                print("Failed to decode project data: \(error.localizedDescription)")
                // Initialize with empty array if decoding fails
                photos = []
            }
        } else {
            // No saved projects found
            photos = []
            print("No saved projects found in UserDefaults. Initialized with empty array.")
        }
    }
    
}

struct ProjectDetail {
    let icon: UIImage?
    let title: String
    let value: String
    
    static func fromUserData(_ project: DataModelMyProject.ProjectDetails) -> [ProjectDetail] {
        return [
            ProjectDetail(icon: UIImage(systemName: "square.fill"), title: "Area", value: project.area),
            ProjectDetail(icon: UIImage(systemName: "bed.double.fill"), title: "Bedrooms", value: project.bedrooms),
            ProjectDetail(icon: UIImage(systemName: "flame.fill"), title: "Kitchen", value: project.kitchen),
            ProjectDetail(icon: UIImage(systemName: "shower.fill"), title: "Bathrooms", value: project.bathrooms),
            ProjectDetail(icon: UIImage(systemName: "couch.fill"), title: "Living Room", value: project.livingRoom),
            ProjectDetail(icon: UIImage(systemName: "tablecells.fill"), title: "Dining Room", value: project.diningRoom),
            ProjectDetail(icon: UIImage(systemName: "book.fill"), title: "Study Room", value: project.studyRoom),
            ProjectDetail(icon: UIImage(systemName: "door.left.hand.open"), title: "Entry", value: project.entry),
            ProjectDetail(icon: UIImage(systemName: "compass.fill"), title: "Vastu", value: project.vastu)
        ]
    }
}
