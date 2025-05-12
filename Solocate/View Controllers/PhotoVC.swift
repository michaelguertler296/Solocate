import UIKit
import CoreMotion
import AVFoundation

class PhotoVC: UIViewController, HeadingManagerDelegate {
    @IBOutlet weak var cameraPreview: UIView!
    @IBOutlet weak var cameraButton: UIButton!
    
    var cameraManager = CameraManager()
    var headingManager: HeadingManager?
    let motionManager = MotionManager()
    let CMmotionManager = CMMotionManager()
    var magneticHeading: CLLocationDirection?
    var pitch: Double?
    var covertModeEnabled = false
    var latestSolarAzimuth: Double?
    var latestSolarElevation: Double?
    
    // UI Elements
    let centerDot = UIView()
    let rollDot = UIView()
    let rollIndicator = UILabel()
    let azimuthLabel = UILabel()
    let elevationLabel = UILabel()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraManager.setupCamera(on: cameraPreview)
        
        setupCovertModeButton()
        setupInstructionsButton()
        setupSensorSuiteUI()
        
        headingManager = HeadingManager()
        headingManager?.delegate = self
        
        startMonitoringSensorSuite()
    }
    
    func didUpdateHeading(_ heading: CLLocationDirection) {
        self.magneticHeading = heading
    }
    
    func didFailWithError(_ error: Error) {
        print("Failed to fetch heading: \(error.localizedDescription)")
    }
    
    @IBAction func capturePhoto(_ sender: UIButton) {
        performSegue(withIdentifier: "MapVC", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "MapVC",
           let destination = segue.destination as? MapVC {
            destination.receivedAzimuth = latestSolarAzimuth
            destination.receivedElevation = latestSolarElevation
        }
    }
    
    private func setupSensorSuiteUI() {
        setupCenterDot()
        setupRollDot()
    }
    
    private func setupCenterDot() {
        centerDot.translatesAutoresizingMaskIntoConstraints = false
        centerDot.backgroundColor = UIColor.green.withAlphaComponent(0.5)
        centerDot.layer.cornerRadius = 15
        centerDot.clipsToBounds = true
        cameraPreview.addSubview(centerDot)
        
        NSLayoutConstraint.activate([
            centerDot.centerXAnchor.constraint(equalTo: cameraPreview.centerXAnchor),
            centerDot.centerYAnchor.constraint(equalTo: cameraPreview.centerYAnchor),
            centerDot.widthAnchor.constraint(equalToConstant: 30),
            centerDot.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func setupRollDot() {
        rollDot.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        rollDot.backgroundColor = .red
        rollDot.layer.cornerRadius = 10
        rollDot.center = CGPoint(x: cameraPreview.bounds.midX, y: cameraPreview.bounds.midY)
        cameraPreview.addSubview(rollDot)
        
        rollIndicator.frame = CGRect(x: 0, y: rollDot.frame.maxY + 8, width: cameraPreview.bounds.width, height: 30)
        rollIndicator.textAlignment = .center
        rollIndicator.textColor = .white
        rollIndicator.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cameraPreview.addSubview(rollIndicator)
    }
    
    private func setupCovertModeButton() {
        let covertButton = UIButton(type: .system)
        covertButton.setTitle("Covert Mode", for: .normal)
        covertButton.setTitleColor(.black, for: .normal)
        covertButton.backgroundColor = .white
        covertButton.layer.cornerRadius = 10
        covertButton.addTarget(self, action: #selector(toggleCovertMode), for: .touchUpInside)
        
        covertButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(covertButton)
        
        NSLayoutConstraint.activate([
            covertButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            covertButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            covertButton.widthAnchor.constraint(equalToConstant: 140),
            covertButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func toggleCovertMode(_ sender: UIButton) {
        covertModeEnabled.toggle()
        sender.setTitle(covertModeEnabled ? "Covert Mode: ON" : "Covert Mode", for: .normal)
    }
    
    private func setupInstructionsButton() {
        let instructionsButton = UIButton(type: .system)
        instructionsButton.setTitle("Instructions", for: .normal)
        instructionsButton.setTitleColor(.black, for: .normal)
        instructionsButton.backgroundColor = .white
        instructionsButton.layer.cornerRadius = 10
        instructionsButton.addTarget(self, action: #selector(showInstructions), for: .touchUpInside)

        instructionsButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(instructionsButton)

        NSLayoutConstraint.activate([
            instructionsButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            instructionsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionsButton.widthAnchor.constraint(equalToConstant: 140),
            instructionsButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    @objc func showInstructions() {
        let alert = UIAlertController(title: "Instructions", message: "Align the red dot with the green dot to ensure level positioning. Tap the shutter to capture data.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func startMonitoringSensorSuite() {
        CMmotionManager.deviceMotionUpdateInterval = 0.05
        CMmotionManager.startDeviceMotionUpdates(to: .main) { [weak self] motionData, _ in
            guard let self = self, let motion = motionData, let heading = self.magneticHeading else { return }
            
            // Roll
            let gravityX = motion.gravity.x
            let tiltAngle = atan2(gravityX, motion.gravity.z) * 180 / .pi
            let offset = CGFloat(gravityX) * 100
            self.rollDot.center.x = self.cameraPreview.bounds.midX + offset
            self.rollDot.backgroundColor = abs(tiltAngle) < 1 ? .green : .red
            
            // Get pitch asynchronously
            self.motionManager.getPitch { pitch in
                guard let pitch = pitch else { return }
                
                let declination = 10.97
                var trueHeading = heading + declination
                
                if pitch < 45 {
                    if trueHeading > 180 {
                        trueHeading -= 180
                    } else {
                        trueHeading += 180
                    }
                }
                
                // Store values
                self.latestSolarAzimuth = trueHeading
                self.latestSolarElevation = 90 - pitch
                
                // Update UI
                DispatchQueue.main.async {
                    self.rollIndicator.text = String(format: "Elevation: %.1f° | Azimuth: %.1f°", 90 - pitch, trueHeading)
                }
            }
        }
    }
}
