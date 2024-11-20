import UIKit
import SpriteKit
import Foundation

extension NSNotification.Name {
    static let projectSaved = NSNotification.Name("projectSaved")
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
    
    var tempProjectData: [String: Any]?
    
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
                UserDefaults.standard.set(tempProjectData, forKey: "tempProjectData")

               
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
        
        
        GeneratedImage.image = UIImage(named: "myProject\(bedroomCount)")
        GeneratedImage.layer.cornerRadius = 15
        GeneratedImage.clipsToBounds = true
    }

    
    private func isLoggedIn() -> Bool {
        return currentUser != nil
    }
    
   
    private func saveProject(withTitle title: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let currentDate = dateFormatter.string(from: Date())
        let savedProject = DataModelMyProject.ProjectDetails(
            imageName: "myProject\(bedroomCount)",
            type: title,
            createdOn: currentDate,
            area: "\(totalArea) sq ft",
            bedrooms: "\(bedroomCount)",
            kitchen: "\(kitchenCount)",
            bathrooms: "\(bathroomCount)",
            livingRoom: "\(livingRoomCount)",
            diningRoom: "\(dinningRoomCount)",
            studyRoom: "\(studyRoomCount)",
            entry: "\(entryCount)",
            vastu: isVastuCompliant ? "Yes" : "No"
        )
        
        DataModelMyProject.shared.addProject(savedProject)
        
        saveToPersistence()
    }
   
    @IBAction func imageTapped(_ sender: UITapGestureRecognizer) {
        let selectedImageName = "myProject2"
        
       
        if let skView = self.view as? SKView {
            let scene = FloorPlanScene(size: skView.bounds.size)
            scene.selectedImageName = selectedImageName
            skView.presentScene(scene)
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
            type: data["title"] as? String ?? "\((data["bedroomCount"] as? Int ?? 0))BHK",            createdOn: currentDate,
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
}
