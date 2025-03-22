import UIKit
import SpriteKit
import Foundation
import FirebaseAuth
import Firebase
import FirebaseStorage
import FirebaseFirestore

extension NSNotification.Name {
    static let projectSaved = NSNotification.Name("projectSaved")
}

// Add this class if it doesn't exist in your project
class imageDataStore {
    static let shared = imageDataStore()
    
    var generatedImage: UIImage?
    
    private init() {}
}

class GeneratedScreenViewController: UIViewController {
    static let sharedGen = GeneratedScreenViewController()
    
    var bedroomCount: Int = 0
    var kitchenCount: Int = 0
    var bathroomCount: Int = 0
    var livingRoomCount: Int = 0
    var dinningRoomCount: Int = 0
    var studyRoomCount: Int = 0
    var entryCount: Int = 0
    var totalArea: Int = 0
    var isVastuCompliant: Bool = false

    @IBOutlet weak var GeneratedImage: UIImageView!
    @IBOutlet weak var threeDButton: UIButton!
    
    var tempProjectData: [String: Any]?
    var generatedImageFromAPI: UIImage? // To store the generated image from the API

    @IBAction func saveButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Project Title", message: "Enter a title for your project.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter title"
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            guard let self = self else { return }
            guard let title = alert.textFields?.first?.text, !title.isEmpty else {
                self.showAlert(title: "Title Missing", message: "Please enter a valid title.")
                return
            }
            
            // Save the current image to ImageDataStore to ensure it's available after login
            if let currentImage = self.GeneratedImage.image {
                imageDataStore.shared.generatedImage = currentImage
            }
            
            if self.isLoggedIn() {
                self.saveProject(withTitle: title)
                print("Project saved with title: \(title)")
                
                NotificationCenter.default.post(name: .projectSaved, object: nil)
                print("Notification posted: Project saved.")
                
                self.redirectToMyProjects()
            } else {
                self.tempProjectData = [
                    "bedroomCount": self.bedroomCount,
                    "kitchenCount": self.kitchenCount,
                    "bathroomCount": self.bathroomCount,
                    "livingRoomCount": self.livingRoomCount,
                    "dinningRoomCount": self.dinningRoomCount,
                    "studyRoomCount": self.studyRoomCount,
                    "entryCount": self.entryCount,
                    "totalArea": self.totalArea,
                    "isVastuCompliant": self.isVastuCompliant,
                    "title": title
                ]
                UserDefaults.standard.set(self.tempProjectData, forKey: "tempProjectData")

                let loginAlert = UIAlertController(title: "Login Required", message: "Please log in to save your project.", preferredStyle: .alert)
                loginAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self.redirectToLogin()
                }))
                self.present(loginAlert, animated: true)
            }
        }
        
        alert.addAction(saveAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Generated"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 21, weight: .bold)
        ]
        navigationController?.navigationBar.titleTextAttributes = attributes
        
        // Display the generated image
        displayGeneratedImage()
        
        GeneratedImage.layer.cornerRadius=10
        GeneratedImage.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0.95)
        GeneratedImage.layer.borderColor = UIColor.lightGray.cgColor
        GeneratedImage.layer.borderWidth = 0.6
        // Check if we have temp project data to save after login
        checkForTempProjectData()
    }
    
    
   
    // New method for displaying the generated image with prioritization
    private func displayGeneratedImage() {
        // First priority: use the image from ImageDataStore
        if let storedImage = ImageDataStore.shared.generatedImage {
            GeneratedImage.image = storedImage
            threeDButton.isEnabled = true
            GeneratedImage.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0.95)
            return
        }
        
        // Second priority: use the directly passed image (for backward compatibility)
        if let directImage = generatedImageFromAPI {
            GeneratedImage.image = directImage
            threeDButton.isEnabled = true
            GeneratedImage.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0.95)
            return
        }
        
        // Third priority: fallback to the default image based on bedroom count
        let imageName = "myProject\(bedroomCount)"
        print("Attempting to load image named: \(imageName)")
        if let image = UIImage(named: imageName) {
            GeneratedImage.image = image
            threeDButton.isEnabled = true
            GeneratedImage.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0.95)
        } else {
            print("Error: Image not found in assets - \(imageName)")
            showNoImageAvailableMessage()
            threeDButton.isEnabled = false
        }
    }
    
    // New method for showing a "no image available" message
    private func showNoImageAvailableMessage() {
        GeneratedImage.image = nil
        
        let label = UILabel()
        label.text = "No floorplan image available"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 18)
        
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isLoggedIn() {
            fetchProjectsForCurrentUser()
        }
    }

    private func checkForTempProjectData() {
        if isLoggedIn(), let tempData = UserDefaults.standard.dictionary(forKey: "tempProjectData") {
            saveProjectFromTempData(tempData)
            UserDefaults.standard.removeObject(forKey: "tempProjectData")
            print("Saved temp project data after login and cleared temp data.")
        }
    }
    
    @IBAction func threeDButtonTapped(_ sender: UIButton) {
        guard let image = GeneratedImage.image else {
            showAlert(title: "Image Error", message: "Could not load floor plan image")
            return
        }
        
        // Add white background to the image
        let imageWithBackground = addWhiteBackground(to: image)
        
        // Pass the image with white background to FloorPlanView
        presentFloorPlanView(with: imageWithBackground)
    }

    // Function to add white background to an image
    func addWhiteBackground(to image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true // This ensures the background is opaque (not transparent)
        
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        let imageWithBackground = renderer.image { context in
            // Fill the entire context with white color
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: image.size))
            
            // Draw the original image on top of the white background
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        
        return imageWithBackground
    }
    

    private func isLoggedIn() -> Bool {
        // Properly check Firebase auth state
        return Auth.auth().currentUser != nil
    }
    
    private func saveProject(withTitle title: String) {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "User not logged in.")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let currentDate = dateFormatter.string(from: Date())
        
        // Save the generated image to Firebase Storage
        guard let image = GeneratedImage.image,
              let imageData = image.jpegData(compressionQuality: 1.0) else {
            showAlert(title: "Error", message: "Could not convert image to data.")
            return
        }
        
        let imageName = "\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child("images/\(user.uid)/\(imageName)")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                self.showAlert(title: "Error", message: "Failed to upload image: \(error.localizedDescription)")
                return
            }
            
            // Once the image is uploaded, get the download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    self.showAlert(title: "Error", message: "Failed to get download URL: \(error.localizedDescription)")
                    return
                }
                
                guard let downloadURL = url else {
                    self.showAlert(title: "Error", message: "Download URL is nil.")
                    return
                }
                
                // Save project details to Firestore
                let db = Firestore.firestore()
                let projectData: [String: Any] = [
                    "userId": user.uid,
                    "imageUrl": downloadURL.absoluteString,
                    "title": title,
                    "createdOn": currentDate,
                    "area": "\(self.totalArea) sq ft",
                    "bedrooms": "\(self.bedroomCount)",
                    "kitchen": "\(self.kitchenCount)",
                    "bathrooms": "\(self.bathroomCount)",
                    "livingRoom": "\(self.livingRoomCount)",
                    "diningRoom": "\(self.dinningRoomCount)",
                    "studyRoom": "\(self.studyRoomCount)",
                    "entry": "\(self.entryCount)",
                    "vastu": self.isVastuCompliant ? "Yes" : "No"
                ]
                
                // Declare documentRef before using it in the closure
                var documentRef: DocumentReference?
                
                // Add the document to Firestore
                documentRef = db.collection("projects").addDocument(data: projectData) { error in
                    if let error = error {
                        self.showAlert(title: "Error", message: "Failed to save project details: \(error.localizedDescription)")
                    } else {
                        // Save to local data model
                        if let documentID = documentRef?.documentID {
                            let savedProject = DataModelMyProject.ProjectDetails(
                                documentID: documentID, // Assign the Firestore document ID
                                imageName: downloadURL.absoluteString,
                                type: title,
                                createdOn: currentDate,
                                area: "\(self.totalArea) sq ft",
                                bedrooms: "\(self.bedroomCount)",
                                kitchen: "\(self.kitchenCount)",
                                bathrooms: "\(self.bathroomCount)",
                                livingRoom: "\(self.livingRoomCount)",
                                diningRoom: "\(self.dinningRoomCount)",
                                studyRoom: "\(self.studyRoomCount)",
                                entry: "\(self.entryCount)",
                                vastu: self.isVastuCompliant ? "Yes" : "No"
                            )
                            
                            DataModelMyProject.shared.addProject(savedProject)
                            self.saveToPersistence()
                            
                            NotificationCenter.default.post(name: .projectSaved, object: nil)
                            self.redirectToMyProjects()
                        }
                    }
                }
            }
        }
    }
//    func fetchProjectsForCurrentUser() {
//        guard let user = Auth.auth().currentUser else {
//            return
//        }
//        
//        let db = Firestore.firestore()
//        db.collection("projects").whereField("userId", isEqualTo: user.uid).getDocuments { snapshot, error in
//            if let error = error {
//                print("Error fetching projects: \(error.localizedDescription)")
//                return
//            }
//            
//            guard let documents = snapshot?.documents else {
//                print("No projects found")
//                return
//            }
//            
//            // Clear existing projects before adding new ones
//            DataModelMyProject.shared.clearProjects()
//            
//            for document in documents {
//                let data = document.data()
//                let project = DataModelMyProject.ProjectDetails(
//                    documentID: document.documentID,
//                    imageName: data["imageUrl"] as? String ?? "",
//                    type: data["title"] as? String ?? "",
//                    createdOn: data["createdOn"] as? String ?? "",
//                    area: data["area"] as? String ?? "",
//                    bedrooms: data["bedrooms"] as? String ?? "",
//                    kitchen: data["kitchen"] as? String ?? "",
//                    bathrooms: data["bathrooms"] as? String ?? "",
//                    livingRoom: data["livingRoom"] as? String ?? "",
//                    diningRoom: data["diningRoom"] as? String ?? "",
//                    studyRoom: data["studyRoom"] as? String ?? "",
//                    entry: data["entry"] as? String ?? "",
//                    vastu: data["vastu"] as? String ?? ""
//                )
//                
//                // Add each project to the shared data model
//                DataModelMyProject.shared.addProject(project)
//            }
//            
//            // Save the updated projects to persistence
//            self.saveToPersistence()
//        }
//    }
    private func fetchProjectsForCurrentUser() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let db = Firestore.firestore()
        db.collection("projects").whereField("userId", isEqualTo: user.uid).getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching projects: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else {
                print("No projects found")
                return
            }
            
            // Clear existing projects before adding new ones
            DataModelMyProject.shared.clearProjects()
            
            for document in documents {
                let data = document.data()
                let project = DataModelMyProject.ProjectDetails(
                    documentID: document.documentID, // Assign the Firestore document ID
                    imageName: data["imageUrl"] as? String ?? "",
                    type: data["title"] as? String ?? "",
                    createdOn: data["createdOn"] as? String ?? "",
                    area: data["area"] as? String ?? "",
                    bedrooms: data["bedrooms"] as? String ?? "",
                    kitchen: data["kitchen"] as? String ?? "",
                    bathrooms: data["bathrooms"] as? String ?? "",
                    livingRoom: data["livingRoom"] as? String ?? "",
                    diningRoom: data["diningRoom"] as? String ?? "",
                    studyRoom: data["studyRoom"] as? String ?? "",
                    entry: data["entry"] as? String ?? "",
                    vastu: data["vastu"] as? String ?? ""
                )
                
                // Add each project to the shared data model
                DataModelMyProject.shared.addProject(project)
            }
            
            // Save the updated projects to persistence
            self.saveToPersistence()
            
            // Reload the collection view
        }
    }
    
    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {
        // When image is tapped, present the FloorPlanView with the generated image
        if let image = GeneratedImage.image {
            self.presentFloorPlanView(with: image)
        }
    }

    private func saveToPersistence() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(DataModelMyProject.shared.photos)
            UserDefaults.standard.set(data, forKey: "savedProjects")
            print("Projects successfully saved to UserDefaults.")
        } catch {
            print("Failed to encode project data: \(error.localizedDescription)")
        }
    }

    func saveProjectFromTempData(_ data: [String: Any]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let currentDate = dateFormatter.string(from: Date())
        let savedProject = DataModelMyProject.ProjectDetails(
            imageName: "myProject\(data["bedroomCount"] as? Int ?? 0)",
            type: data["title"] as? String ?? "\((data["bedroomCount"] as? Int ?? 0))BHK",
            createdOn: currentDate,
            area: "\((data["totalArea"] as? Int ?? 0)) sq ft",
            bedrooms: "\(data["bedroomCount"] as? Int ?? 0)",
            kitchen: "\(data["kitchenCount"] as? Int ?? 0)",
            bathrooms: "\(data["bathroomCount"] as? Int ?? 0)",
            livingRoom: "\(data["livingRoomCount"] as? Int ?? 0)",
            diningRoom: "\(data["dinningRoomCount"] as? Int ?? 0)",
            studyRoom: "\(data["studyRoomCount"] as? Int ?? 0)",
            entry: "\(data["entryCount"] as? Int ?? 0)",
            vastu: (data["isVastuCompliant"] as? Bool ?? false) ? "Yes" : "No"
        )
        
        print("Saved Project: \(savedProject)")
        
        DataModelMyProject.shared.addProject(savedProject)
        saveToPersistence()
    }

    @IBAction func exportButtonTapped(_ sender: UIButton) {
        guard let generatedImage = GeneratedImage.image else {
            showAlert(title: "No Image", message: "No generated image available to export.")
            return
        }

        let projectDetails = """
        Project Details:
        Bedrooms: \(bedroomCount)
        Kitchen: \(kitchenCount)
        Bathrooms: \(bathroomCount)
        Living Room: \(livingRoomCount)
        Dining Room: \(dinningRoomCount)
        Study Room: \(studyRoomCount)
        Entry: \(entryCount)
        Total Area: \(totalArea) sq ft
        Vastu Compliant: \(isVastuCompliant ? "Yes" : "No")
        """

        let activityItems: [Any] = [generatedImage, projectDetails]

        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activityViewController.excludedActivityTypes = [.addToReadingList, .assignToContact]

        activityViewController.popoverPresentationController?.sourceView = sender
        present(activityViewController, animated: true) {
            print("Export options presented to the user.")
        }
    }
   
    private func redirectToMyProjects() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
            tabBarController.modalPresentationStyle = .fullScreen
            tabBarController.selectedIndex = 2  // Profile tab is at index 2
            self.present(tabBarController, animated: true, completion: nil)
        }
    }

    private func redirectToLogin() {
        performSegue(withIdentifier: "LogInSegue", sender: nil)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
    // Note: This is a method signature with no implementation in your original code
    // You'll need to implement this method or it will cause a compile error
     // This should present the FloorPlanView with the given image
    }


