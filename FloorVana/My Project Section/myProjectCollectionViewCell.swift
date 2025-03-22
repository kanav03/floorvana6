
import UIKit

class myProjectCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var dateCreated: UILabel!
    @IBOutlet weak var area: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Configure imageView
        // Configure imageView
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        imageView.layer.backgroundColor = UIColor.white.cgColor

        // Configure delete button
        let trashImage = UIImage(systemName: "trash.fill")?.withRenderingMode(.alwaysTemplate)
        let smallerTrashImage = trashImage?.applyingSymbolConfiguration(UIImage.SymbolConfiguration(pointSize: 12, weight: .regular))

        deleteButton.setImage(smallerTrashImage, for: .normal)
        deleteButton.tintColor = .white
        deleteButton.backgroundColor = UIColor(red: 193/255, green: 39/255, blue: 45/255, alpha: 1.0) // Matte Red
        deleteButton.layer.masksToBounds = true
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(deleteButton)

        NSLayoutConstraint.activate([
            deleteButton.topAnchor.constraint(equalTo: self.topAnchor, constant: -3), // Slightly up
            deleteButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 8), // Slightly right
            deleteButton.widthAnchor.constraint(equalToConstant: 26), // Keep small circular background
            deleteButton.heightAnchor.constraint(equalToConstant: 26)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        deleteButton.layer.cornerRadius = deleteButton.frame.size.width / 2 // Make it circular
    }

    func toggleEditMode(_ isEditing: Bool) {
        deleteButton.isHidden = !isEditing
    }
}
