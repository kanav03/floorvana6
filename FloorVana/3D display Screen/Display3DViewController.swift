


import UIKit
import SwiftUI

class Display3DViewController: UIViewController {

    var capturedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        setupFloorPlanView()
    }

    private func setupNavigationBar() {
        // Set the title
        self.title = "3D Floor Plan"

        // Create reset button with gold tint
        let goldColor = UIColor(red: 199/255, green: 180/255, blue: 105/255, alpha: 1.0)
        let resetButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(resetButtonTapped)
        )
        resetButton.tintColor = goldColor

        // Add the button to the navigation bar
        navigationItem.rightBarButtonItem = resetButton
    }

    @objc private func resetButtonTapped() {
        // Remove and re-add the SwiftUI view to reset it
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
        setupFloorPlanView()
    }

    private func setupFloorPlanView() {
        // Create a simplified version of FloorPlanView that doesn't include the image selection UI
        let floorPlanView = SimplifiedFloorPlanView(selectedImage: capturedImage)

        // Create a hosting controller to bridge SwiftUI to UIKit
        let hostingController = UIHostingController(rootView: floorPlanView)

        // Add the hosting controller as a child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        // Make the hosting controller's view fill the parent view
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
