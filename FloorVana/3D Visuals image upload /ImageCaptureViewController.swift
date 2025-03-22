
import UIKit

class ImageCaptureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    
    private var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Visualise Your Dream"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 21, weight: .bold)
        ]
        navigationController?.navigationBar.titleTextAttributes = attributes
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        imageView.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0.95)
    }
 
    @IBAction func captureImage(_ sender: UIButton) {
        openCamera()
    }

    @IBAction func uploadImage(_ sender: UIButton) {
        if uploadButton.currentTitle == "Continue" {
            navigateToD3OutputScreen()
        } else {
            openImagePicker(sourceType: .photoLibrary)
        }
    }
    
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
            imageView.image = image
            selectedImage = image
            captureButton.isHidden = true  // Hide capture button
            uploadButton.setTitle("Continue", for: .normal)  // Change upload button title
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    @objc private func navigateToD3OutputScreen() {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let d3OutputVC = mainStoryboard.instantiateViewController(withIdentifier: "D3Output") as? Display3DViewController {
            // Process the image to add white background before passing it
            if let originalImage = selectedImage {
                let imageWithBackground = addWhiteBackgroundToImage(originalImage)
                d3OutputVC.capturedImage = imageWithBackground
            } else {
                d3OutputVC.capturedImage = selectedImage
            }
            navigationController?.pushViewController(d3OutputVC, animated: true)
        }
    }
    
    private func addWhiteBackgroundToImage(_ image: UIImage) -> UIImage {
        // Create a new context with white background
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = true // Ensures the background is opaque
        
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        
        let newImage = renderer.image { context in
            // Fill the background with white
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: image.size))
            
            // Draw the original image on top
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        
        return newImage
    }
    
    private func showAlert(_ title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
