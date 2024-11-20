import UIKit

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var phoneLabel: UILabel!
    @IBOutlet weak var settingsLabel: UILabel!
    @IBOutlet weak var deleteAccountLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        if let loggedInUser = currentUser {
           
            usernameLabel.text = loggedInUser.Username
            emailLabel.text = "\(loggedInUser.Username)@gmail.com"
            phoneLabel.text = "9876543210"
            
            logoutButton.isHidden = false
        } else {
            
            let alert = UIAlertController(
                title: "Not Logged In",
                message: "Log in to view your profile",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.redirectToLogin()
            }))
            present(alert, animated: true)
            
            
            
            
            logoutButton.isHidden = true
        }
    }
    
    private func redirectToLogin() {
            let loginStoryboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = loginStoryboard.instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController {
                self.present(loginVC, animated: true, completion: nil)
            }
        }
    
    private func redirectToHome() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
            tabBarController.modalPresentationStyle = .fullScreen
            tabBarController.selectedIndex = 0  // Profile tab is at index 2
            self.present(tabBarController, animated: true, completion: nil)
        }
    }
    
    @IBAction func logoutButtonTapped(_ sender: UIButton) {
        if let _ = currentUser {
            currentUser = nil
            
            let alert = UIAlertController(
                title: "Logged Out",
                message: "You have been logged out successfully.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.redirectToHome()
            }))
            present(alert, animated: true)
        } else {
            let alert = UIAlertController(
                title: "No User Logged In",
                message: "You are not logged in.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
}
