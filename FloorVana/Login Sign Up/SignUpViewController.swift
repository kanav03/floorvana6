import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController {
    @IBOutlet weak var NameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var PasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Sign Up"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 21, weight: .bold)
        ]
        navigationController?.navigationBar.titleTextAttributes = attributes
        
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapgesture)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        guard let username = NameTextField.text, !username.isEmpty,
              let email = emailTextField.text, !email.isEmpty,
              let password = PasswordTextField.text, !password.isEmpty else {
           
            showAlert(message: "Please fill in all fields.")
            return
        }

        AddUser(username: username, email: email, password: password)
    }

    private func AddUser(username: String, email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                self.showAlert(message: "Registration failed: \(error.localizedDescription)")
                return
            }
            
            // Update profile with the username
            let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
            changeRequest?.displayName = username
            changeRequest?.commitChanges { error in
                if let error = error {
                    print("Failed to update username: \(error.localizedDescription)")
                }
            }
            
            self.showAlert(message: "Sign-up successful!")
        }
    }

    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Sign Up", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            if message == "Sign-up successful!" {
                self.redirectToLogin()
            }
        }))
        present(alert, animated: true, completion: nil)
    }

    private func redirectToLogin() {
        // If using navigation controller:
        navigationController?.popViewController(animated: true)
        
        // If not using navigation controller or you want to present a new login screen:
        if navigationController == nil {
            let loginStoryboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = loginStoryboard.instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController {
                self.present(loginVC, animated: true, completion: nil)
            }
        }
    }
}
