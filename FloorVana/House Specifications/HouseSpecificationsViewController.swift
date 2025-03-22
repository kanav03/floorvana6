
import UIKit
import Foundation

class HouseSpecificationsViewController: UIViewController {

 
    @IBOutlet weak var bedroomCountLabel: UILabel!
    @IBOutlet weak var kitchenCountLabel: UILabel!
    @IBOutlet weak var bathroomCountLabel: UILabel!
    @IBOutlet weak var livingRoomCountLabel: UILabel!
    @IBOutlet weak var dinningRoomCountLabel: UILabel!
    @IBOutlet weak var studyRoomCountLabel: UILabel!
    @IBOutlet weak var entryCountLabel: UILabel!

   
    @IBOutlet weak var bedroomStepper: UIStepper!
    @IBOutlet weak var kitchenStepper: UIStepper!
    @IBOutlet weak var bathroomStepper: UIStepper!
    @IBOutlet weak var livingRoomStepper: UIStepper!
    @IBOutlet weak var dinningRoomStepper: UIStepper!
    @IBOutlet weak var studyRoomStepper: UIStepper!
    @IBOutlet weak var entryStepper: UIStepper!


    @IBOutlet weak var areaTextField: UITextField!
    @IBOutlet weak var vastuSwitch: UISwitch!

  
    @IBOutlet weak var buildButton: UIButton!

        private var model: HouseSpecifications!

    override func viewDidLoad() {
        super.viewDidLoad()

       
        model = HouseSpecifications()

      
        setupInitialValues()
        configureUI()
        
        self.title = "Specifications"

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)

        addDoneButtonToKeyboard()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func addDoneButtonToKeyboard() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismissKeyboard))
        toolbar.setItems([doneButton], animated: false)
        areaTextField.inputAccessoryView = toolbar
    }

    private func setupInitialValues() {
       
        [bedroomStepper, kitchenStepper, bathroomStepper, livingRoomStepper,
         dinningRoomStepper, studyRoomStepper, entryStepper].forEach { stepper in
            stepper?.minimumValue = 0
            stepper?.maximumValue = 6
            stepper?.value = 0
        }

       
        areaTextField.text = ""
       
        updateUIFromModel()
    }

    private func updateUIFromModel() {
      
        bedroomCountLabel.text = "\(model.getRoomCount(for: .bedroom))"
        kitchenCountLabel.text = "\(model.getRoomCount(for: .kitchen))"
        bathroomCountLabel.text = "\(model.getRoomCount(for: .bathroom))"
        livingRoomCountLabel.text = "\(model.getRoomCount(for: .livingRoom))"
        dinningRoomCountLabel.text = "\(model.getRoomCount(for: .dinningRoom))"
        studyRoomCountLabel.text = "\(model.getRoomCount(for: .studyRoom))"
        entryCountLabel.text = "\(model.getRoomCount(for: .entry))"

     
        areaTextField.text = model.totalArea > 0 ? "\(model.totalArea)" : ""


        vastuSwitch.isOn = model.isVastuCompliant
    }

    private func configureUI() {
       
        buildButton.layer.cornerRadius = 12
        buildButton.backgroundColor = .black
        buildButton.setTitleColor(.yellow, for: .normal)

       
        areaTextField.keyboardType = .numberPad
        areaTextField.delegate = self

        
        // Navigation Bar Title Size
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 21, weight: .bold)
        ]
        navigationController?.navigationBar.titleTextAttributes = attributes
    }

  
    @IBAction func bedroomStepperChanged(_ sender: UIStepper) {
        model.updateRoomCount(for: .bedroom, count: Int(sender.value))
        bedroomCountLabel.text = "\(Int(sender.value))"
    }

    @IBAction func kitchenStepperChanged(_ sender: UIStepper) {
        model.updateRoomCount(for: .kitchen, count: Int(sender.value))
        kitchenCountLabel.text = "\(Int(sender.value))"
    }

    @IBAction func bathroomStepperChanged(_ sender: UIStepper) {
        model.updateRoomCount(for: .bathroom, count: Int(sender.value))
        bathroomCountLabel.text = "\(Int(sender.value))"
    }

    @IBAction func livingRoomStepperChanged(_ sender: UIStepper) {
        model.updateRoomCount(for: .livingRoom, count: Int(sender.value))
        livingRoomCountLabel.text = "\(Int(sender.value))"
    }

    @IBAction func dinningRoomStepperChanged(_ sender: UIStepper) {
        model.updateRoomCount(for: .dinningRoom, count: Int(sender.value))
        dinningRoomCountLabel.text = "\(Int(sender.value))"
    }

    @IBAction func studyRoomStepperChanged(_ sender: UIStepper) {
        model.updateRoomCount(for: .studyRoom, count: Int(sender.value))
        studyRoomCountLabel.text = "\(Int(sender.value))"
    }

    @IBAction func entryStepperChanged(_ sender: UIStepper) {
        model.updateRoomCount(for: .entry, count: Int(sender.value))
        entryCountLabel.text = "\(Int(sender.value))"
    }

    @IBAction func vastuSwitchChanged(_ sender: UISwitch) {
        model.setVastuCompliance(sender.isOn)
    }

    @IBAction func buildButtonTapped(_ sender: UIButton) {
        
        if let areaValue = Int(areaTextField.text ?? "0") {
            model.updateTotalArea(area: areaValue)
        }

       
        if model.validate() {
            performSegue(withIdentifier: "ShowGeneratedScreen", sender: nil)
        } else {
            let alert = UIAlertController(
                title: "Invalid Specifications",
                message: "Please ensure you have at least one bedroom, kitchen, and bathroom, and the total area is greater than 0.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowGeneratedScreen",
           let destinationVC = segue.destination as? GeneratedScreenViewController {
            destinationVC.bedroomCount = model.getRoomCount(for: .bedroom)
            destinationVC.kitchenCount = model.getRoomCount(for: .kitchen)
            destinationVC.bathroomCount = model.getRoomCount(for: .bathroom)
            destinationVC.livingRoomCount = model.getRoomCount(for: .livingRoom)
            destinationVC.dinningRoomCount = model.getRoomCount(for: .dinningRoom)
            destinationVC.studyRoomCount = model.getRoomCount(for: .studyRoom)
            destinationVC.entryCount = model.getRoomCount(for: .entry)
            destinationVC.totalArea = model.totalArea
            destinationVC.isVastuCompliant = model.isVastuCompliant
        }
    }
}


extension HouseSpecificationsViewController: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == areaTextField, let value = Int(textField.text ?? "") {
            model.updateTotalArea(area: value)
            areaTextField.text = "\(value) sq ft"
        }
    }


    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let allowedCharacters = CharacterSet.decimalDigits
        let characterSet = CharacterSet(charactersIn: string)
        return allowedCharacters.isSuperset(of: characterSet)
    }

}
