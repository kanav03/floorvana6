//
//  ViewController.swift
//  imageCapture
//
//  Created by Navdeep on 14/11/24.
import UIKit

class ImageCaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    private var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
 
    @IBAction func captureImage(_ sender: UIButton) {
        openCamera()
    }

    @IBAction func uploadImage(_ sender: UIButton) {
        openImagePicker(sourceType: .photoLibrary)
    }
    
//    @IBAction func continueButtonPressed(_ sender: UIButton) {
//        guard let imageToSave = selectedImage else {
//            showAlert("No Image", message: "Please capture or upload an image before continuing.")
//            return
//        }
//        
//        ImageModel.saveImage(imageToSave)
//        
//        showAlert("Image Saved", message: "Your image has been successfully saved.") { [weak self] in
//            self?.navigateToD3OutputScreen()
//        }
//    }
    func openCamera() {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .camera
                imagePicker.allowsEditing = true
                present(imagePicker, animated: true, completion: nil)
            } else {
                showAlert("Error", message: "Camera not available.")
            }
        }
    func openImagePicker(sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            showAlert("Unavailable", message: "This feature is not available on your device.")
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = sourceType
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[.originalImage] as? UIImage {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Continue", style: .plain, target: self, action: #selector(navigateToD3OutputScreen))
            imageView.image = image
            selectedImage = image
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc private func navigateToD3OutputScreen() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let d3OutputVC = mainStoryboard.instantiateViewController(withIdentifier: "D3Output") as? Display3DViewController {
            d3OutputVC.capturedImage = selectedImage
            navigationController?.pushViewController(d3OutputVC, animated: true)
        }
    }
    
    private func showAlert(_ title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
