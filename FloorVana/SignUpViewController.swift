import UIKit

class SignUpViewController: UIViewController {
    @IBOutlet weak var NameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var PasswordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

       
        AddUser(username: username, password: password)

        
        showAlert(message: "Sign-up successful!")
    }

    private func AddUser(username: String, password: String) {
        
        addUser(username: username, password: password)
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
        let loginStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginVC = loginStoryboard.instantiateViewController(withIdentifier: "LogInViewController") as? LogInViewController {
            self.present(loginVC, animated: true, completion: nil)
        }
    }
}
