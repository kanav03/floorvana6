// LogInViewController.swift
import UIKit

class LogInViewController: UIViewController {
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    var tempProjectData: [String: Any]?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapgesture)
        loginButton.layer.cornerRadius = 8
        loginButton.clipsToBounds = true
        
        // Retrieve tempProjectData from UserDefaults if it exists
        if let savedProjectData = UserDefaults.standard.dictionary(forKey: "tempProjectData") {
            tempProjectData = savedProjectData
            print("Loaded saved project data: \(tempProjectData!)")
        } else {
            print("No project data found in UserDefaults")
        }
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    @IBAction func loginButtonTapped(_ sender: Any) {
        guard let emailText = email.text, !emailText.isEmpty,
              let passwordText = password.text, !passwordText.isEmpty else {
            showAlert(title: "Missing Information", message: "Please enter both email and password.")
            return
        }

      
        if let user = users.first(where: { $0.Username == emailText && $0.Password == passwordText }) {
         
            currentUser = user
            
         
            if let projectData = tempProjectData {
                GeneratedScreenViewController.sharedGen.saveProjectFromTempData(projectData)
                print("Project data saved successfully after login")
                
               
                tempProjectData = nil
                UserDefaults.standard.removeObject(forKey: "tempProjectData")
            } else {
                print("No project data found to save after login.")
            }

           
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            if let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
                tabBarController.modalPresentationStyle = .fullScreen
                tabBarController.selectedIndex = 2 
                self.present(tabBarController, animated: true, completion: nil)
            }
        } else {
            showAlert(title: "Invalid Credentials", message: "Please check your username and password.")
        }
    }

    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "SignUpSegue", sender: nil)
        }
    
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true, completion: nil)
    }
}
