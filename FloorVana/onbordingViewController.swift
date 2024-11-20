import UIKit

class onbordingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func continueButtonTapped(_ sender: UIButton) {
       
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        
        
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
            tabBarController.modalPresentationStyle = .fullScreen
            tabBarController.selectedIndex = 0 // Assuming Profile tab is at index 2
            self.present(tabBarController, animated: true, completion: nil)
        }
    }
}
