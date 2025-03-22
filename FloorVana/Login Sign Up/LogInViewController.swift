import UIKit
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import FirebaseCore
import CryptoKit
import FirebaseFirestore
import FirebaseStorage

class LogInViewController: UIViewController {

    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var appleButton: UIButton!
    @IBOutlet weak var googleButton: UIButton!

    // For Apple Sign-In nonce
    private var currentNonce: String?
    
    // For temporary project data
    var tempProjectData: [String: Any]?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Load temporary project data from UserDefaults if it exists
        if let savedProjectData = UserDefaults.standard.dictionary(forKey: "tempProjectData") {
            tempProjectData = savedProjectData
            print("Loaded saved project data: \(tempProjectData!)")
        } else {
            print("No project data found in UserDefaults")
        }
        
        // Add tap gesture to dismiss keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
        self.title = "Log In"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 21, weight: .bold)
        ]
        navigationController?.navigationBar.titleTextAttributes = attributes
    }

    private func setupUI() {
        appleButton.layer.cornerRadius = 8
        googleButton.layer.cornerRadius = 8
        loginButton.layer.cornerRadius = 8
        googleButton.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0.95)
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "signUpSegue", sender: nil)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }

    
    
    
    
    // MARK: - Email/Password Login
    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let emailText = email.text, !emailText.isEmpty,
              let passwordText = password.text, !passwordText.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter both email and password.")
            return
        }

        Auth.auth().signIn(withEmail: emailText, password: passwordText) { authResult, error in
            if let error = error {
                self.showAlert(title: "Login Failed", message: error.localizedDescription)
            } else {
                self.navigateToHomeScreen()
                self.fetchProjectsForCurrentUser()
            }
        }
    }


    // MARK: - Google Sign-In
    @IBAction func googleSignInTapped(_ sender: UIButton) {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)

        GIDSignIn.sharedInstance.configuration = config

        GIDSignIn.sharedInstance.signIn(withPresenting: self) { result, error in
            guard let user = result?.user, error == nil else { return }
            
            guard let idToken = user.idToken?.tokenString else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.showAlert(title: "Google Sign-In Failed", message: error.localizedDescription)
                } else {
                    self.navigateToHomeScreen()
                    self.fetchProjectsForCurrentUser()
                }
            }
        }
    }

    
    private func fetchProjectsForCurrentUser() {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        print("Fetching projects for user: \(user.uid)")
        
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
            
            print("Found \(documents.count) projects in Firestore")
            
            // Clear existing projects before adding new ones
            DataModelMyProject.shared.clearProjects()
            
            for document in documents {
                let data = document.data()
                let project = DataModelMyProject.ProjectDetails(
                    documentID: document.documentID,
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
                
                print("Adding project from Firestore: \(project)")
                // Add each project to the shared data model
                DataModelMyProject.shared.addProject(project)
            }
            
            // Save the updated projects to persistence
            self.saveToPersistence()
        }
    }

    private func saveToPersistence() {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(DataModelMyProject.shared.getPhotos())
            UserDefaults.standard.set(data, forKey: "savedProjects")
            print("Projects successfully saved to UserDefaults.")
        } catch {
            print("Failed to encode project data: \(error.localizedDescription)")
        }
    }
    
    
    
    
    
    
    
    // MARK: - Apple Sign-In
    @IBAction func appleSignInTapped(_ sender: UIButton) {
        let nonce = randomNonceString()
        currentNonce = nonce
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    // MARK: - Navigate to Home
    private func navigateToHomeScreen() {
        // Save any temporary project data before navigating
        if let projectData = tempProjectData {
            saveProjectToFirestore(projectData)
            print("Project data saved successfully after login")
            
            // Clear temporary data
            tempProjectData = nil
            UserDefaults.standard.removeObject(forKey: "tempProjectData")
        } else {
            print("No project data found to save after login.")
        }
        
        // Then navigate as usual
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
            tabBarController.modalPresentationStyle = .fullScreen
            tabBarController.selectedIndex = 2
            self.present(tabBarController, animated: true, completion: nil)
        }
    }

    // Add this new method to save to Firestore
    private func saveProjectToFirestore(_ projectData: [String: Any]) {
        guard let user = Auth.auth().currentUser else {
            print("Error: No user logged in")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        let currentDate = dateFormatter.string(from: Date())
        
        // Check if we have a generated image in ImageDataStore
        var image: UIImage
        if let storedImage = imageDataStore.shared.generatedImage {
            print("Using stored image from ImageDataStore")
            image = storedImage
        } else {
            // Fallback to using a placeholder image based on bedroom count
            let bedroomCount = projectData["bedroomCount"] as? Int ?? 0
            let imageName = "myProject\(bedroomCount)"
            print("Using fallback image: \(imageName)")
            
            guard let fallbackImage = UIImage(named: imageName) else {
                print("Error: Could not load fallback image \(imageName)")
                return
            }
            image = fallbackImage
        }
        
        // Convert image to data
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            print("Error: Could not convert image to data")
            return
        }
        
        // Upload image to Firebase Storage
        let imageName2 = "\(UUID().uuidString).jpg"
        let storageRef = Storage.storage().reference().child("images/\(user.uid)/\(imageName2)")
        
        print("Starting image upload to Firebase Storage")
        
        storageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("Error uploading image: \(error.localizedDescription)")
                return
            }
            
            print("Image uploaded successfully, getting download URL")
            
            // Get download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Error getting download URL: \(error.localizedDescription)")
                    return
                }
                
                guard let downloadURL = url else {
                    print("Error: Download URL is nil")
                    return
                }
                
                print("Got download URL: \(downloadURL.absoluteString)")
                
                // Save project details to Firestore
                let db = Firestore.firestore()
                let projectDataForFirestore: [String: Any] = [
                    "userId": user.uid,
                    "imageUrl": downloadURL.absoluteString,
                    "title": projectData["title"] as? String ?? "My Project",
                    "createdOn": currentDate,
                    "area": "\(projectData["totalArea"] as? Int ?? 0) sq ft",
                    "bedrooms": "\(projectData["bedroomCount"] as? Int ?? 0)",
                    "kitchen": "\(projectData["kitchenCount"] as? Int ?? 0)",
                    "bathrooms": "\(projectData["bathroomCount"] as? Int ?? 0)",
                    "livingRoom": "\(projectData["livingRoomCount"] as? Int ?? 0)",
                    "diningRoom": "\(projectData["dinningRoomCount"] as? Int ?? 0)",
                    "studyRoom": "\(projectData["studyRoomCount"] as? Int ?? 0)",
                    "entry": "\(projectData["entryCount"] as? Int ?? 0)",
                    "vastu": (projectData["isVastuCompliant"] as? Bool ?? false) ? "Yes" : "No"
                ]
                
                print("Saving project to Firestore with data: \(projectDataForFirestore)")
                
                // Add the document to Firestore
                var documentRef: DocumentReference?
                documentRef = db.collection("projects").addDocument(data: projectDataForFirestore) { error in
                    if let error = error {
                        print("Error saving project to Firestore: \(error.localizedDescription)")
                    } else {
                        print("Project successfully saved to Firestore with ID: \(documentRef?.documentID ?? "unknown")")
                        
                        // Save to local data model
                        if let documentID = documentRef?.documentID {
                            let savedProject = DataModelMyProject.ProjectDetails(
                                documentID: documentID,
                                imageName: downloadURL.absoluteString,
                                type: projectData["title"] as? String ?? "My Project",
                                createdOn: currentDate,
                                area: "\(projectData["totalArea"] as? Int ?? 0) sq ft",
                                bedrooms: "\(projectData["bedroomCount"] as? Int ?? 0)",
                                kitchen: "\(projectData["kitchenCount"] as? Int ?? 0)",
                                bathrooms: "\(projectData["bathroomCount"] as? Int ?? 0)",
                                livingRoom: "\(projectData["livingRoomCount"] as? Int ?? 0)",
                                diningRoom: "\(projectData["dinningRoomCount"] as? Int ?? 0)",
                                studyRoom: "\(projectData["studyRoomCount"] as? Int ?? 0)",
                                entry: "\(projectData["entryCount"] as? Int ?? 0)",
                                vastu: (projectData["isVastuCompliant"] as? Bool ?? false) ? "Yes" : "No"
                            )
                            
                            print("Adding project to local data model: \(savedProject)")
                            DataModelMyProject.shared.addProject(savedProject)
                            
                            // Explicitly fetch projects to ensure the UI is updated
                            self.fetchProjectsForCurrentUser()
                            
                            // Post notification that project was saved
                            NotificationCenter.default.post(name: .projectSaved, object: nil)
                            print("Posted project saved notification")
                        }
                    }
                }
            }
        }
    }

    // MARK: - Show Alert
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}

extension LogInViewController: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return view.window!
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            guard let token = appleIDCredential.identityToken,
                  let tokenString = String(data: token, encoding: .utf8),
                  let nonce = currentNonce else { return }

            let credential = OAuthProvider.credential(withProviderID: "apple.com", idToken: tokenString, rawNonce: nonce)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.showAlert(title: "Apple Sign-In Failed", message: error.localizedDescription)
                } else {
                    self.navigateToHomeScreen()
                }
            }
        default:
            break
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        showAlert(title: "Apple Sign-In Error", message: error.localizedDescription)
    }
}

// MARK: - Apple Sign-In Helper for Nonce Generation
extension LogInViewController {
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if status != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(status)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
