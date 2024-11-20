//
//  ViewController.swift
//  AppStore
//
//  Created by Navdeep

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    
    var autoScrollTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarController?.tabBar.tintColor = UIColor(red: 199/255, green: 175/255, blue: 96/255, alpha: 1.0)
        
        collectionView.dataSource = self
        collectionView.setCollectionViewLayout(generateLayout(), animated: true)
        
        
        startAutoScroll()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAutoScroll()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startAutoScroll()
    }
    
    // MARK: - Auto Scroll Functionality
    
    func startAutoScroll() {
        autoScrollTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(scrollToNextItem), userInfo: nil, repeats: true)
    }
    
    func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    @objc func scrollToNextItem() {
       
        guard DataModel.apps.count > 0 else { return }
        
        let visibleItems = collectionView.indexPathsForVisibleItems
        let currentIndexPath = visibleItems.sorted().first { $0.section == 1 }
        
        if let currentIndexPath = currentIndexPath {
            let nextItemIndex = (currentIndexPath.item + 1) % DataModel.apps.count
            let nextIndexPath = IndexPath(item: nextItemIndex, section: 1)
            
            collectionView.scrollToItem(at: nextIndexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return DataModel.sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return DataModel.apps.count
        } else if section == 2 {
            return 1
        } else if section == 3 {
            return DataModel.standardApps.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "welcomeLabel", for: indexPath)
            
            if let cell = cell as? welcomeLabelCollectionViewCell {
                cell.title.text = "Discover 3D Designs"
                
                return cell
            }
        }
        
        
        else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Promoted", for: indexPath)
            let app = DataModel.apps[indexPath.row]
            
            if let cell = cell as? crousel3dCollectionViewCell {
                cell.subTitleLabel.text = app.subtitle
                cell.imageView.layer.cornerRadius = 15
                cell.imageView.layer.shadowColor = UIColor.black.cgColor
                cell.imageView.layer.shadowOpacity = 0.1
                cell.imageView.layer.masksToBounds = true
                cell.imageView.image = UIImage(named: app.image)
                cell.imageView.layer.borderColor = UIColor.systemGray.cgColor
            }
            return cell
        }
        
        
        else if indexPath.section == 2 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "button", for: indexPath)
            let app = DataModel.label2D[indexPath.row]
            
            if let cell = cell as? buttonCollectionViewCell {
                cell.planButton.layer.cornerRadius = 15
                cell.label2d.text = app.title
                return cell
            }
        } else if indexPath.section == 3 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "standard", for: indexPath)
            
            if let cell = cell as? trending2dCollectionViewCell {
                let app = DataModel.standardApps[indexPath.row]
                cell.titleLabel.text = app.title
                cell.imageView.image = UIImage(named: app.image)
                cell.imageView.layer.cornerRadius = 15
                cell.imageView.layer.borderWidth = 1
                cell.imageView.layer.borderColor = UIColor.systemGray.cgColor
                return cell
            }
        }
        
        return UICollectionViewCell()
    }
    
    // MARK: - Layout Generation
    
    func generateLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, env) -> NSCollectionLayoutSection? in
            
            let sectionType = DataModel.sections[sectionIndex]
            
            switch sectionType {
            case .welocmeLabel:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: 1)
                return NSCollectionLayoutSection(group: group)
                
            case .crousel3d:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(360))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                group.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 15, trailing: 15)
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPagingCentered
                return section
                
            case .button:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(1.0))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(100))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: 1)
                return NSCollectionLayoutSection(group: group)
                
            case .trending2D:
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.33))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(180))
                let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitem: item, count: 1)
                group.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 15, bottom: 10, trailing: 15)
                return NSCollectionLayoutSection(group: group)
            }
        }
        return layout
    }
}
