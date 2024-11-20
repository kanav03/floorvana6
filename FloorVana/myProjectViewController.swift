import UIKit
import Foundation

class myProjectViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
   
    var dataModel: DataModelMyProject = DataModelMyProject.shared
    var isEditingMode: Bool = false
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var editButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.dataSource = self
        collectionView.delegate = self
        
       
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)
        
      
        NotificationCenter.default.addObserver(self, selector: #selector(handleProjectSavedNotification), name: .projectSaved, object: nil)
    }
    
    
    @objc func handleProjectSavedNotification() {
        print("Project was saved!")
        collectionView.reloadData()
    }
    
    
    @objc func reloadData() {
        collectionView.reloadData()
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
    
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        isEditingMode.toggle()
        sender.setTitle(isEditingMode ? "Done" : "Edit", for: .normal)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataModel.getPhotos().count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MyProjectCell", for: indexPath)
        let photoData = dataModel.getPhoto(at: indexPath.row)
        
        cell.layer.cornerRadius = 10
        cell.backgroundColor = UIColor.systemGray5
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 1.0, height: 4.0)
        cell.layer.shadowRadius = 2.0
        cell.layer.shadowOpacity = 0.5
        cell.layer.masksToBounds = false
        
        if let wordCell = cell as? myProjectCollectionViewCell {
            wordCell.imageView.image = UIImage(named: photoData.imageName)
            wordCell.nameLabel.text = photoData.type
            
            
            wordCell.deleteButton.isHidden = !isEditingMode || (indexPath.row == 0)
            wordCell.deleteButton.tag = indexPath.row
            wordCell.deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
        }
        
        return cell
    }
    @objc func backToMyProjects(){
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        if let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
            tabBarController.modalPresentationStyle = .fullScreen
            tabBarController.selectedIndex = 2
            self.present(tabBarController, animated: true, completion: nil)
        }
    }

    
    
    @objc func deleteButtonTapped(_ sender: UIButton) {
        let indexToDelete = sender.tag
        
        
        let alert = UIAlertController(title: "Delete Project", message: "Are you sure you want to delete this project?", preferredStyle: .alert)
        
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            
            self.dataModel.removePhoto(at: indexToDelete)
            
            
            self.collectionView.deleteItems(at: [IndexPath(row: indexToDelete, section: 0)])
        }))
        
        
        self.present(alert, animated: true, completion: nil)
    }

    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 0 {
//            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
//            if let tabBarController = mainStoryboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
//                tabBarController.modalPresentationStyle = .fullScreen
//                tabBarController.selectedIndex = 1
//                self.present(tabBarController, animated: true, completion: nil)
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            
           
            
            if let drawVC = mainStoryboard.instantiateViewController(withIdentifier: "drawViewController") as? DrawViewController {
                drawVC.hidesBottomBarWhenPushed = true
//                drawVC.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(backToMyProjects))
                // Ensure navigation controller is available
                if let navigationController = self.navigationController {
                    navigationController.pushViewController(drawVC, animated: true)
                    
                } else {
                    // Handle case where navigation controller is not present
                    print("Error: No Navigation Controller available.")
                }
            }
            }
            else {
            let selectedProject = dataModel.getPhoto(at: indexPath.row)
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            if let projectDetailsVC = mainStoryboard.instantiateViewController(withIdentifier: "ProjectDetails") as? ProjectDetailsViewController {
                projectDetailsVC.projectData = selectedProject
                projectDetailsVC.modalPresentationStyle = .pageSheet
                self.present(projectDetailsVC, animated: true, completion: nil)
            }
        }
       
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .projectSaved, object: nil)
    }
}
