import UIKit
import CoreMotion
import AVFoundation

class PhotoVC: UIViewController {

    @IBOutlet weak var cameraPreview: UIView!
    @IBOutlet weak var cameraButton: UIButton!

    private let cameraManager = CameraManager()
    private let motionManager = MotionManager()
    private var capturedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
    }

    @IBAction func capturePhoto(_ sender: UIButton) {
        cameraManager.capturePhoto()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapVC",
           let destinationVC = segue.destination as? MapVC {
            destinationVC.imageToDisplay = capturedImage
        }
    }

    private func setupCamera() {
        cameraManager.delegate = self
        cameraManager.setupCamera(on: cameraPreview)
    }
}

extension PhotoVC: CameraManagerDelegate {
    func didCapturePhoto(_ image: UIImage) {
        capturedImage = image
        performSegue(withIdentifier: "toMapVC", sender: self)
    }
}
