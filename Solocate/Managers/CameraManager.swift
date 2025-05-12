import UIKit
import AVFoundation

protocol CameraManagerDelegate: AnyObject {
    func didCapturePhoto(_ image: UIImage)
}

class CameraManager: NSObject {
    var captureSession: AVCaptureSession!
    var photoOutput: AVCapturePhotoOutput!
    var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    weak var delegate: CameraManagerDelegate?
    
    func setupCamera(on previewView: UIView) {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input)
        else {
            print("Failed to set up camera input")
            return
        }
        
        captureSession.addInput(input)
        
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        
        // Configure exposure and white balance to reduce glare
        do {
            try camera.lockForConfiguration()
            
            // Set a short exposure duration and low ISO
            let exposureDuration = CMTimeMake(value: 1, timescale: 60000) // 1 ms
            let targetISO: Float = 50.0
            if camera.isExposureModeSupported(.custom) {
                camera.setExposureModeCustom(duration: exposureDuration, iso: targetISO, completionHandler: nil)
            }
            
            // Lock white balance at a neutral color temperature
            if camera.isWhiteBalanceModeSupported(.locked) {
                let tempTint = AVCaptureDevice.WhiteBalanceTemperatureAndTintValues(temperature: 5000, tint: 0)
                let gains = camera.deviceWhiteBalanceGains(for: tempTint)
                camera.setWhiteBalanceModeLocked(with: gains, completionHandler: nil)
            }
            
            camera.unlockForConfiguration()
        } catch {
            print("Failed to configure camera settings: \(error)")
        }
        
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.frame = previewView.bounds
        previewView.layer.addSublayer(videoPreviewLayer)
        
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
}
