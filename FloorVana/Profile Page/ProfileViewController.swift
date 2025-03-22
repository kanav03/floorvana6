//
//
//import UIKit
//import FirebaseAuth
//
//class ProfileViewController: UIViewController {
//
//    @IBOutlet weak var profileImageView: UIImageView!
//    @IBOutlet weak var usernameLabel: UILabel!
//    @IBOutlet weak var emailLabel: UILabel!
//    @IBOutlet weak var phoneLabel: UILabel!
//    @IBOutlet weak var logoutButton: UIButton!
//    
//    // Add outlets for the stack views
//    @IBOutlet weak var userDetailsStackView: UIStackView! // Stack view containing all user details
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 21.5)
//        updateUI()
//    }
//
//    private func updateUI() {
//        if let user = Auth.auth().currentUser {
//            // User is logged in - show all details
//            userDetailsStackView.isHidden = false
//            
//            let email = user.email ?? "No Email"
//            let username = email.components(separatedBy: "@").first ?? "User"
//
//            usernameLabel.text = username
//            emailLabel.text = email
//            phoneLabel.text = user.phoneNumber ?? "No Phone"
//            
//            logoutButton.setTitle("Logout", for: .normal)
//        } else {
//            // User is not logged in - hide details, show only login button
//            userDetailsStackView.isHidden = true
//            
//            logoutButton.setTitle("Log In", for: .normal)
//        }
//
//        // Set the font size explicitly here
//        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 21.5)
//    }
//
//    @IBAction func logoutButtonTapped(_ sender: UIButton) {
//        if Auth.auth().currentUser != nil {
//            do {
//                try Auth.auth().signOut()
//                showAlert(title: "Logged Out", message: "You have been logged out successfully.") {
//                    self.updateUI()
//                }
//            } catch let signOutError as NSError {
//                showAlert(title: "Error", message: "Failed to log out: \(signOutError.localizedDescription)")
//            }
//        } else {
//            redirectToLogin()
//        }
//    }
//
//    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
//            completion?()
//        })
//        present(alert, animated: true)
//    }
//
//    private func redirectToLogin() {
//        let loginStoryboard = UIStoryboard(name: "Main", bundle: nil)
//        if let loginVC = loginStoryboard.instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController {
//            self.present(loginVC, animated: true, completion: nil)
//        }
//    }
//}
import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {

    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    
    // Add outlets for the stack views
    @IBOutlet weak var userDetailsStackView: UIStackView! // Stack view containing all user details
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 21.5)
        updateUI()
    }

    private func updateUI() {
        if let user = Auth.auth().currentUser {
            // User is logged in - show all details
            userDetailsStackView.isHidden = false
            
            let email = user.email ?? "No Email"
            let username = email.components(separatedBy: "@").first ?? "User"

            usernameLabel.text = username
            emailLabel.text = email
            phoneLabel.text = user.phoneNumber ?? "No Phone"
            
            logoutButton.setTitle("Logout", for: .normal)
        } else {
            // User is not logged in - hide details, show only login button
            userDetailsStackView.isHidden = true
            
            logoutButton.setTitle("Log In", for: .normal)
        }

        // Set the font size explicitly here
        logoutButton.titleLabel?.font = UIFont.systemFont(ofSize: 21.5)
    }

    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        if Auth.auth().currentUser != nil {
            // User is logged in - handle logout
            handleLogout()
        } else {
            // User is not logged in - redirect to login
            redirectToLogin()
        }
    }

    private func handleLogout() {
        // Clear local data using the new method
        DataModelMyProject.shared.clearProjects()
        
        // Log out from Firebase Auth
        do {
            try Auth.auth().signOut()
            print("User logged out successfully.")
            
            // Show a success message
            showAlert(title: "Logged Out", message: "You have been logged out successfully.") {
                // Update the UI to reflect the logged-out state
                self.updateUI()
            }
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
            showAlert(title: "Error", message: "Failed to log out: \(signOutError.localizedDescription)")
        }
    }

    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    private func redirectToLogin() {
        let loginStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginVC = loginStoryboard.instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController {
            loginVC.modalPresentationStyle = .fullScreen
            self.present(loginVC, animated: true, completion: nil)
        }
    }
}
