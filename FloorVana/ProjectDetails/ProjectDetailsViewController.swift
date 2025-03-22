
import SwiftUI
import UIKit
import SDWebImage

class ProjectDetailsViewController: UIViewController {
    
    // Keep all your existing outlets and properties
    
    @IBOutlet weak var projectTitle: UILabel!
    @IBOutlet weak var projectDetailsView: UIView!
    
    @IBOutlet weak var projectImageView: UIImageView!
    @IBOutlet weak var createdOnLabel: UILabel!
    @IBOutlet weak var Segment2dto3d: UISegmentedControl!
    @IBOutlet weak var detailsCollectionView: UICollectionView!
    @IBOutlet weak var exportButton: UIButton!
    
    var projectData: DataModelMyProject.ProjectDetails?
    var projectDetails: [ProjectDetail] = []  // Will hold dynamic data

    override func viewDidLoad() {
        // Keep all your existing viewDidLoad code
        super.viewDidLoad()
        
        // Apply styling
        applyShadow(to: projectDetailsView)
        applyShadow(to: projectImageView)
        applyShadow(to: Segment2dto3d)
        
        projectImageView.layer.borderWidth = 1
        projectImageView.layer.borderColor = UIColor.systemGray4.cgColor
        projectImageView.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0.95)
        
        Segment2dto3d.layer.borderWidth = 1
        Segment2dto3d.layer.borderColor = UIColor.systemGray4.cgColor

        // Collection View Setup
        detailsCollectionView.delegate = self
        detailsCollectionView.dataSource = self
        setupCollectionViewLayout()
        
        Segment2dto3d.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        // Ensure data is available
        guard let project = projectData else { return }
        
        // Load image from documents directory if it's a file path, otherwise from assets
        loadProjectImage(from: project.imageName)
        
        createdOnLabel.text = project.createdOn
        projectTitle.text = project.type
        
        // Convert user data to ProjectDetail format
        projectDetails = [
            ProjectDetail(icon: UIImage(systemName: "square.fill"), title: "Area", value: project.area),
            ProjectDetail(icon: UIImage(systemName: "bed.double.fill"), title: "Bedrooms", value: project.bedrooms),
            ProjectDetail(icon: UIImage(systemName: "flame.fill"), title: "Kitchen", value: project.kitchen),
            ProjectDetail(icon: UIImage(systemName: "shower.fill"), title: "Bathrooms", value: project.bathrooms),
            ProjectDetail(icon: UIImage(systemName: "house.fill"), title: "Living Room", value: project.livingRoom),
            ProjectDetail(icon: UIImage(systemName: "table.furniture.fill"), title: "Dining Room", value: project.diningRoom),
            ProjectDetail(icon: UIImage(systemName: "book.fill"), title: "Study Room", value: project.studyRoom),
            ProjectDetail(icon: UIImage(systemName: "door.left.hand.open"), title: "Entry Points", value: project.entry),
            ProjectDetail(icon: UIImage(systemName: "leaf.fill"), title: "Vastu", value: project.vastu)
        ]

        // Setup collection view
        detailsCollectionView.delegate = self
        detailsCollectionView.dataSource = self
        setupCollectionViewLayout()
    }
    

    private func loadProjectImage(from imageName: String) {
        // First check if we have an image in imageDataStore (passed from myProjectViewController)
        if let storedImage = imageDataStore.shared.generatedImage {
            projectImageView.image = storedImage
            // Clear the stored image after using it
            imageDataStore.shared.generatedImage = nil
            return
        }
        
        // Check if the imageName is a URL (from Firebase Storage)
        if imageName.hasPrefix("http://") || imageName.hasPrefix("https://") {
            // This is a URL, load the image using SDWebImage or URLSession
            if let imageUrl = URL(string: imageName) {
                // Using SDWebImage (recommended)
                projectImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder"))
            }
        } else if imageName.contains(".jpg") || imageName.contains(".png") || imageName.contains("/") {
            // This is a file path, try to load from documents directory
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileURL = documentsDirectory.appendingPathComponent(imageName)
            if let imageData = try? Data(contentsOf: fileURL), let image = UIImage(data: imageData) {
                projectImageView.image = image
            } else {
                // Fallback to named image if file can't be loaded
                projectImageView.image = UIImage(named: imageName)
            }
        } else {
            // This is a named image, load from assets
            projectImageView.image = UIImage(named: imageName)
        }
    }
    
    // Keep your existing methods
    func applyShadow(to view: UIView) {
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.16
        view.layer.shadowOffset = CGSize(width: 0.5, height: 1)
        view.layer.shadowRadius = 4
        view.layer.masksToBounds = false
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.95)
    }
    
    // Modify the segmentChanged method to redirect to 3D view
    @objc func segmentChanged() {
        switch Segment2dto3d.selectedSegmentIndex {
        case 0:
            // 2D view - show the original image
            guard let project = projectData else { return }
            // Reload the project image using our new method
            loadProjectImage(from: project.imageName)
        case 1:
            // 3D view - redirect to SimplifiedFloorPlanView with the current image
            guard let image = projectImageView.image else {
                let alert = UIAlertController(title: "Error", message: "No image available for 3D conversion.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    // Reset segment control to 2D
                    self.Segment2dto3d.selectedSegmentIndex = 0
                })
                present(alert, animated: true)
                return
            }
            
            // Present the 3D floor plan view using UIHostingController
            let floorPlanView = SimplifiedFloorPlanView(selectedImage: image)
            let hostingController = UIHostingController(rootView: floorPlanView)
            
            // Add a custom close button at the top right
            let closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24)) // Super compact size
            closeButton.layer.cornerRadius = 12 // Keeps it perfectly circular
            closeButton.backgroundColor = UIColor(red: 199/255, green: 180/255, blue: 105/255, alpha: 1.0) // Tint color background
            closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            closeButton.tintColor = .white // White cross
            closeButton.clipsToBounds = true // Ensures the shape stays perfect
            closeButton.addTarget(self, action: #selector(self.dismissFloorPlanView), for: .touchUpInside)

            // Position the button at the top right of the view with margins
            closeButton.translatesAutoresizingMaskIntoConstraints = false
            hostingController.view.addSubview(closeButton)
            
            NSLayoutConstraint.activate([
                closeButton.topAnchor.constraint(equalTo: hostingController.view.safeAreaLayoutGuide.topAnchor, constant: 16),
                closeButton.trailingAnchor.constraint(equalTo: hostingController.view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
                closeButton.widthAnchor.constraint(equalToConstant: 24),
                closeButton.heightAnchor.constraint(equalToConstant: 24)
            ])
            
            // Ensure the close button appears on top
            hostingController.view.bringSubviewToFront(closeButton)
            
            // You can present it modally or push it onto your navigation stack
            if let navigationController = self.navigationController {
                navigationController.pushViewController(hostingController, animated: true)
                // Hide the navigation bar for full screen experience
                navigationController.setNavigationBarHidden(true, animated: true)
            } else {
                hostingController.modalPresentationStyle = .fullScreen
                present(hostingController, animated: true)
            }
            
            // Reset the segment to 2D for when user returns to this screen
            self.Segment2dto3d.selectedSegmentIndex = 0
            
        default:
            break
        }
    }
    
    // Add a method to dismiss the floor plan view
    @objc func dismissFloorPlanView() {
        if let navigationController = self.navigationController {
            // Show the navigation bar again when dismissing
            navigationController.setNavigationBarHidden(false, animated: true)
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    // Keep your existing exportButtonTapped method
    @IBAction func exportButtonTapped(_ sender: UIButton) {
        guard let image = projectImageView.image else {
            let alert = UIAlertController(title: "Error", message: "No image to export.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        if let imageData = image.jpegData(compressionQuality: 1.0) {
            let tempFileURL = FileManager.default.temporaryDirectory.appendingPathComponent("exported_image.jpg")

            do {
                try imageData.write(to: tempFileURL)
                let activityVC = UIActivityViewController(activityItems: [tempFileURL], applicationActivities: nil)
                activityVC.popoverPresentationController?.sourceView = sender
                present(activityVC, animated: true)
            } catch {
                let alert = UIAlertController(title: "Error", message: "Failed to save image.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }

    // Keep your existing setupCollectionViewLayout method
    func setupCollectionViewLayout() {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 13
        let numberOfColumns: CGFloat = 2
        let cellWidth = 165
        
        layout.itemSize = CGSize(width: cellWidth, height: 65)
        layout.minimumInteritemSpacing = spacing
        layout.minimumLineSpacing = spacing
        detailsCollectionView.collectionViewLayout = layout
    }
}

// Keep your existing extension
extension ProjectDetailsViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return projectDetails.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProjectDetailCell", for: indexPath) as! ProjectDetailCell
        let detail = projectDetails[indexPath.row]

        cell.iconImageView.image = detail.icon
        cell.titleLabel.text = detail.title
        cell.valueLabel.text = detail.value
    
        cell.layer.cornerRadius = 12
        cell.layer.borderWidth = 1
        cell.layer.borderColor = UIColor.systemGray4.cgColor
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOpacity = 0.2
        cell.layer.shadowOffset = CGSize(width: 0.5, height: 2)
        cell.layer.shadowRadius = 4
        cell.layer.masksToBounds = false
        cell.backgroundColor = UIColor.systemGray3
        cell.backgroundColor = UIColor(white: 1.0, alpha: 1)

        return cell
    }
}
