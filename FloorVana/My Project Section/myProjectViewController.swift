
import UIKit
import Foundation
import SDWebImage

class myProjectViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var dataModel: DataModelMyProject = DataModelMyProject.shared
    var isEditingMode: Bool = false
    
    // Cache to store loaded images
    private var imageCache = NSCache<NSString, UIImage>()

    @IBOutlet weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the navigation bar title
        self.title = "My Project"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 21, weight: .bold)
        ]
        navigationController?.navigationBar.titleTextAttributes = attributes

        // Add the plus button to the left side of the navigation bar
        let plusButton = UIBarButtonItem(image: UIImage(systemName: "plus"), style: .plain, target: self, action: #selector(plusButtonTapped))
        navigationItem.leftBarButtonItem = plusButton

        // Add the edit button to the right side of the navigation bar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(editButtonTapped))

        // Set up the collection view
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)

        // Add observer for project saved notification
        NotificationCenter.default.addObserver(self, selector: #selector(handleProjectSavedNotification), name: .projectSaved, object: nil)
        
        // Configure SDWebImage global cache settings
        SDImageCache.shared.config.maxDiskAge = 60 * 60 * 24 * 30 // 30 days
        SDImageCache.shared.config.maxMemoryCost = 1024 * 1024 * 50 // 50 MB
        
        // Load projects data
        loadProjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Only reload data if needed (after adding a new project)
        if dataModel.needsReload {
            loadProjects()
            dataModel.needsReload = false
        }
    }
    
    // Load projects from DataModel (which should handle caching)
    private func loadProjects() {
        // Reload data from UserDefaults or local cache
        dataModel.reloadData()
        
        // Debug: Print all image URLs
        for (index, project) in dataModel.getPhotos().enumerated() {
            print("Project \(index) image URL: \(project.imageName)")
        }
        
        // Reload the collection view
        collectionView.reloadData()
    }
    
    @objc private func plusButtonTapped() {
        // Get the storyboard instance
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        // Instantiate the DrawViewController using its storyboard ID
        if let drawVC = storyboard.instantiateViewController(withIdentifier: "drawViewController") as? DrawViewController {
            // Push the DrawViewController onto the navigation stack
            self.navigationController?.pushViewController(drawVC, animated: true)
        }
    }
    
    @objc func editButtonTapped() {
        isEditingMode.toggle()
        
        // Change button title to "Done" when in editing mode
        navigationItem.rightBarButtonItem?.title = isEditingMode ? "Done" : "Edit"
        
        collectionView.reloadData()
    }

    @objc func handleProjectSavedNotification() {
        print("Project was saved!")
        
        // Set flag to reload data
        dataModel.needsReload = true
        
        // Reload data
        loadProjects()
    }

    func generateLayout() -> UICollectionViewCompositionalLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(200.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
        group.interItemSpacing = NSCollectionLayoutSpacing.fixed(10.0)
        
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 20
        section.contentInsets = NSDirectionalEdgeInsets(top: 15, leading: 15, bottom: 15, trailing: 15)
        
        return UICollectionViewCompositionalLayout(section: section)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataModel.getPhotos().count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyProjectCell", for: indexPath)
        let photoData = dataModel.getPhoto(at: indexPath.row)
        
        cell.layer.cornerRadius = 10
        cell.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0.95)
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 1.0, height: 1.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.3
        cell.layer.masksToBounds = false

        if let wordCell = cell as? myProjectCollectionViewCell {
            let imageName = photoData.imageName
            
            // First check our local cache
            if let cachedImage = imageCache.object(forKey: imageName as NSString) {
                wordCell.imageView.image = cachedImage
            }
            // Check if this is a URL (from Firebase Storage)
            else if imageName.hasPrefix("http://") || imageName.hasPrefix("https://") {
                // This is a URL, load the image using SDWebImage with caching
                if let imageUrl = URL(string: imageName) {
                    wordCell.imageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder")) { (image, error, cacheType, url) in
                        // Cache the image if it loaded successfully
                        if let downloadedImage = image {
                            self.imageCache.setObject(downloadedImage, forKey: imageName as NSString)
                        }
                    }
                } else {
                    wordCell.imageView.image = UIImage(named: "placeholder")
                }
            }
            // Check if this is a file path (local storage)
            else if imageName.contains(".jpg") || imageName.contains(".png") || imageName.contains("/") {
                // This is a file path, try to load from documents directory
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsDirectory.appendingPathComponent(imageName)
                
                if let image = UIImage(contentsOfFile: fileURL.path) {
                    wordCell.imageView.image = image
                    // Cache the image
                    self.imageCache.setObject(image, forKey: imageName as NSString)
                } else {
                    wordCell.imageView.image = UIImage(named: "placeholder")
                }
            }
            // This must be a named image from assets
            else {
                if let image = UIImage(named: imageName) {
                    wordCell.imageView.image = image
                } else {
                    wordCell.imageView.image = UIImage(named: "placeholder")
                }
            }
            
            wordCell.nameLabel.text = photoData.type
            wordCell.dateCreated.text = photoData.createdOn
            wordCell.area.text = photoData.area
            
            // Only show delete button for projects from index 1 onwards
            let shouldShowDelete = isEditingMode && indexPath.row >= 0
            wordCell.toggleEditMode(shouldShowDelete)
            wordCell.deleteButton.tag = indexPath.row
            wordCell.deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
        }

        return cell
    }
    
    @objc func deleteButtonTapped(_ sender: UIButton) {
        let indexToDelete = sender.tag
        let photoData = dataModel.getPhoto(at: indexToDelete)
        
        // Ensure the project has a documentID
        guard let documentID = photoData.documentID else {
            print("Error: Project does not have a documentID.")
            return
        }
        
        let alert = UIAlertController(title: "Delete Project", message: "Are you sure you want to delete this project?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            // Delete the project from Firestore
            self.dataModel.deleteProjectFromFirestore(documentID: documentID) { success in
                if success {
                    // Delete the image file if it exists
                    if photoData.imageName.contains(".jpg") || photoData.imageName.contains(".png") || photoData.imageName.contains("/") {
                        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                        let fileURL = documentsDirectory.appendingPathComponent(photoData.imageName)
                        try? FileManager.default.removeItem(at: fileURL)
                    }
                    
                    // Remove from cache
                    self.imageCache.removeObject(forKey: photoData.imageName as NSString)
                    
                    // Remove the project from the local data model
                    self.dataModel.removePhoto(at: indexToDelete)
                    
                    // Reload the collection view
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                } else {
                    // Show an error message if the deletion fails
                    print("Failed to delete project from Firestore.")
                }
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedProject = dataModel.getPhoto(at: indexPath.row)
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let projectDetailsVC = mainStoryboard.instantiateViewController(withIdentifier: "ProjectDetails") as? ProjectDetailsViewController {
            projectDetailsVC.projectData = selectedProject
            
            // Use cached image if available
            if let cachedImage = imageCache.object(forKey: selectedProject.imageName as NSString) {
                imageDataStore.shared.generatedImage = cachedImage
            }
            // Otherwise, load from local storage if needed
            else if selectedProject.imageName.contains(".jpg") || selectedProject.imageName.contains(".png") || selectedProject.imageName.contains("/") {
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsDirectory.appendingPathComponent(selectedProject.imageName)
                if let image = UIImage(contentsOfFile: fileURL.path) {
                    imageDataStore.shared.generatedImage = image
                    // Cache the image
                    self.imageCache.setObject(image, forKey: selectedProject.imageName as NSString)
                }
            }
            
            projectDetailsVC.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(projectDetailsVC, animated: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .projectSaved, object: nil)
    }
}

// Extension for DataModelMyProject to add reload flag
extension DataModelMyProject {
    // Flag to track if data needs to be reloaded
    static var needsReloadKey = "needsReloadKey"
    
    var needsReload: Bool {
        get {
            return UserDefaults.standard.bool(forKey: DataModelMyProject.needsReloadKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: DataModelMyProject.needsReloadKey)
        }
    }
}
