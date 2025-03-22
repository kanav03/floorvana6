
import UIKit
import FirebaseFirestore
import SDWebImage

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var trendingCollectionView: UICollectionView!
    @IBOutlet weak var previousCollectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var trendingPlans: [Plan] = []
    var savedProjects: [SavedProject] = []
    var emptyStateView: UIView?
    
    // UserDefaults key for caching trending plans
    private let trendingPlansKey = "cachedTrendingPlans"
    // Flag to check if data has been loaded
    private var hasFetchedTrendingPlans = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        trendingCollectionView.dataSource = self
        trendingCollectionView.delegate = self
        previousCollectionView.dataSource = self
        previousCollectionView.delegate = self
        
        if let layout = trendingCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
        }
        trendingCollectionView.isPagingEnabled = true

        pageControl.numberOfPages = trendingPlans.count
        pageControl.currentPage = 0

        setupEmptyStateView()
        
        // Try to load cached trending plans first
        loadCachedTrendingPlans()
        loadSavedProjects()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadSavedProjects()
    }

    // MARK: - Setup Empty State View
    func setupEmptyStateView() {
        let emptyView = UIView()
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.backgroundColor = UIColor.clear // Transparent to blend with blur effect
        emptyView.layer.cornerRadius = 10
        emptyView.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        emptyView.layer.borderWidth = 1.2
        emptyView.clipsToBounds = true
        emptyView.backgroundColor = UIColor(red: 0.93, green: 0.93, blue: 0.93, alpha: 0.95)
        // Glassmorphism Blur Effect
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 16
        blurView.clipsToBounds = true
        emptyView.addSubview(blurView)

        // Add Title Label
        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.text = "Plan Your Dream Home"
        messageLabel.font = UIFont.boldSystemFont(ofSize: 22)
        messageLabel.textColor = UIColor.black.withAlphaComponent(0.7)
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        // Add Subtitle Label
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Create your first project and bring your vision to life!"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = UIColor.darkGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 2

        emptyView.addSubview(blurView)
        emptyView.addSubview(messageLabel)
        emptyView.addSubview(subtitleLabel)
        self.view.addSubview(emptyView)
        
        previousCollectionView.backgroundView = emptyView
        
        self.emptyStateView = emptyView

        // Constraints
        NSLayoutConstraint.activate([
            emptyView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, constant: 220),
            emptyView.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.92),
            emptyView.heightAnchor.constraint(equalToConstant: 200),

            blurView.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: emptyView.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor),

            messageLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: emptyView.topAnchor, constant: 55),

            subtitleLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 10),
            subtitleLabel.leadingAnchor.constraint(equalTo: emptyView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: emptyView.trailingAnchor, constant: -20)
        ])

        emptyStateView?.isHidden = true // Initially hidden
    }
    
    // MARK: - Trending Plans Caching
    
    // Load cached trending plans from UserDefaults
    func loadCachedTrendingPlans() {
        if let cachedData = UserDefaults.standard.data(forKey: trendingPlansKey),
           let cachedPlans = try? JSONDecoder().decode([Plan].self, from: cachedData) {
            self.trendingPlans = cachedPlans
            DispatchQueue.main.async {
                self.pageControl.numberOfPages = self.trendingPlans.count
                self.trendingCollectionView.reloadData()
            }
            hasFetchedTrendingPlans = true
        } else {
            // If no cached data exists, fetch from Firebase
            fetchTrendingPlans()
        }
    }
    
    // Save trending plans to UserDefaults
    func cacheTrendingPlans() {
        if let encodedData = try? JSONEncoder().encode(trendingPlans) {
            UserDefaults.standard.set(encodedData, forKey: trendingPlansKey)
        }
    }
    
    // Fetch trending plans from Firebase (only if not already cached)
    func fetchTrendingPlans() {
        // Don't fetch if we already have the data
        if hasFetchedTrendingPlans && !trendingPlans.isEmpty {
            return
        }
        
        FirebaseManager.shared.fetchImages { [weak self] imageUrls in
            guard let self = self else { return }
            
            self.trendingPlans = imageUrls.map { Plan(title: "Success Spotlights", imageURL: $0) }
            DispatchQueue.main.async {
                self.pageControl.numberOfPages = self.trendingPlans.count
                self.trendingCollectionView.reloadData()
            }
            
            // Cache the fetched data
            self.cacheTrendingPlans()
            self.hasFetchedTrendingPlans = true
        }
    }

    func loadSavedProjects() {
        let localPhotos = DataModelMyProject.shared.getPhotos()
        
        savedProjects = localPhotos.map { photo in
            SavedProject(
                name: photo.type,
                dateCreated: photo.createdOn,
                imageName: photo.imageName, // Ensure this is the URL from Firestore
                area: photo.area
            )
        }

        DispatchQueue.main.async {
            self.updateSavedProjectsUI()
            self.previousCollectionView.reloadData()
        }
    }

    func updateSavedProjectsUI() {
        let hasProjects = !savedProjects.isEmpty
        previousCollectionView.backgroundView?.isHidden = hasProjects
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionView == trendingCollectionView ? trendingPlans.count : savedProjects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == trendingCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TrendingPlanCell", for: indexPath) as! TrendingPlanCell
            let plan = trendingPlans[indexPath.item]

            cell.planTitleLabel.text = plan.title
            if let url = URL(string: plan.imageURL) {
                // Use SDWebImage's built-in caching
                cell.planImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
            } else {
                cell.planImageView.image = UIImage(named: "placeholder")
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlanCell", for: indexPath) as! PlanCell
            let project = savedProjects[indexPath.item]
            
            cell.titleLabel.text = project.name
            
            // Load the image properly based on where it's stored
            let imageName = project.imageName
            
            // Check if this is a URL (from Firebase Storage)
            if imageName.hasPrefix("http://") || imageName.hasPrefix("https://") {
                // This is a URL, load the image using SDWebImage
                if let imageUrl = URL(string: imageName) {
                    cell.imageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "project_placeholder"))
                } else {
                    cell.imageView.image = UIImage(named: "project_placeholder")
                }
            } else if imageName.contains(".jpg") || imageName.contains(".png") || imageName.contains("/") {
                // This is a file path, try to load from documents directory
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsDirectory.appendingPathComponent(imageName)
                if let imageData = try? Data(contentsOf: fileURL), let image = UIImage(data: imageData) {
                    cell.imageView.image = image
                } else {
                    // Fallback to placeholder if file can't be loaded
                    cell.imageView.image = UIImage(named: "project_placeholder")
                }
            } else {
                // This is a named image, load from assets
                if let image = UIImage(named: imageName) {
                    cell.imageView.image = image
                } else {
                    cell.imageView.image = UIImage(named: "project_placeholder")
                }
            }
            
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == trendingCollectionView {
            return CGSize(width: collectionView.frame.width * 0.9, height: 230)
        } else {
            return CGSize(width: 170, height: 180)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
 
        if collectionView == trendingCollectionView {
            let selectedPlan = trendingPlans[indexPath.item]
 
            if let detailsVC = storyboard.instantiateViewController(withIdentifier: "TrendingPlanDetails") as? TrendingPlanDetailsViewController {
                detailsVC.plan = selectedPlan
                detailsVC.modalPresentationStyle = .pageSheet
                self.present(detailsVC, animated: true, completion: nil)
            }
        } else if collectionView == previousCollectionView {
            let adjustedIndex = indexPath.item
            let selectedProject = DataModelMyProject.shared.getPhoto(at: adjustedIndex)
 
            if let projectDetailsVC = storyboard.instantiateViewController(withIdentifier: "ProjectDetails") as? ProjectDetailsViewController {
                projectDetailsVC.projectData = selectedProject
                
                // If the project uses a file path, pass the image to imageDataStore
                if selectedProject.imageName.contains(".jpg") || selectedProject.imageName.contains(".png") || selectedProject.imageName.contains("/") {
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                    let fileURL = documentsDirectory.appendingPathComponent(selectedProject.imageName)
                    if let imageData = try? Data(contentsOf: fileURL), let image = UIImage(data: imageData) {
                        imageDataStore.shared.generatedImage = image
                    }
                }
                
                projectDetailsVC.modalPresentationStyle = .pageSheet
                self.present(projectDetailsVC, animated: true, completion: nil)
            }
        }
    }
 
    // MARK: - Update PageControl When Scrolling
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == trendingCollectionView {
            let pageIndex = round(scrollView.contentOffset.x / scrollView.frame.width)
            pageControl.currentPage = Int(pageIndex)
        }
    }
}

// Make Plan conform to Codable for UserDefaults storage
struct Plan: Codable {
    let title: String
    let imageURL: String
}

struct SavedProject {
    let name: String
    let dateCreated: String
    let imageName: String
    let area: String
}
