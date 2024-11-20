import UIKit

class ProjectDetailsViewController: UIViewController {

    @IBOutlet weak var projectImageView: UIImageView!
    @IBOutlet weak var createdOnLabel: UILabel!
    @IBOutlet weak var areaLabel: UILabel!
    @IBOutlet weak var bedroomCountLabel: UILabel!
    @IBOutlet weak var kitchenCountLabel: UILabel!
    @IBOutlet weak var bathroomCountLabel: UILabel!
    @IBOutlet weak var livingRoomCountLabel: UILabel!
    @IBOutlet weak var diningRoomCountLabel: UILabel!
    @IBOutlet weak var studyRoomCountLabel: UILabel!
    @IBOutlet weak var entryCountLabel: UILabel!
    @IBOutlet weak var vastuLabel: UILabel!
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var Segment2dto3d: UISegmentedControl!

    
    var projectData: DataModelMyProject.ProjectDetails?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        Segment2dto3d.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        
        guard let project = projectData else { return }

        projectImageView.image = UIImage(named: project.imageName)
        createdOnLabel.text = "Created on: \(project.createdOn)"
        areaLabel.text = "\(project.area)"
        bedroomCountLabel.text = "\(project.bedrooms)"
        kitchenCountLabel.text = "\(project.kitchen)"
        bathroomCountLabel.text = "\(project.bathrooms)"
        livingRoomCountLabel.text = "\(project.livingRoom)"
        diningRoomCountLabel.text = "\(project.diningRoom)"
        studyRoomCountLabel.text = "\(project.studyRoom)"
        entryCountLabel.text = "\(project.entry)"
        vastuLabel.text = "\(project.vastu)"
    }

    @objc func segmentChanged() {
       
        switch Segment2dto3d.selectedSegmentIndex {
        case 0:
          
            guard let project = projectData else { return }
            projectImageView.image = UIImage(named: project.imageName)
        case 1:
            
            projectImageView.image = UIImage(named: "a")
        default:
            break
        }
    }

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
}
