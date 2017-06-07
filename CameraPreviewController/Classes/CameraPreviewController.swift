//
//  CameraPreviewController.swift
//  Pods
//
//  Created by DragonCherry on 1/5/17.
//
//

import UIKit
import CoreMotion
import TinyLog
import PureLayout
import GPUImage

// MARK: - Declaration for CameraPreviewControllerDelegate
public protocol CameraPreviewControllerDelegate: class {
    func cameraPreview(_ controller: CameraPreviewController, didSaveVideoAt url: URL)
    func cameraPreview(_ controller: CameraPreviewController, didFailSaveVideoWithError error: Error)
    func cameraPreview(_ controller: CameraPreviewController, willOutput sampleBuffer: CMSampleBuffer, with sequence: UInt64)
    func cameraPreview(_ controller: CameraPreviewController, willFocusInto tappedLocationInView: CGPoint, tappedLocationInImage: CGPoint)
}

// MARK: - Declaration for CameraPreviewControllerLayoutSource
public protocol CameraPreviewControllerLayoutSource: class {
    func cameraPreviewNeedsLayout(_ controller: CameraPreviewController, preview: GPUImageView)
}

// MARK: - Declaration for CameraPreviewControllerFaceDetectionDelegate
public protocol CameraPreviewControllerFaceDetectionDelegate: class {
    func cameraPreview(_ controller: CameraPreviewController, detected faceFeatures: [CIFaceFeature]?, aperture: CGRect, orientation: UIDeviceOrientation)
}

// MARK: - Declaration for CameraPreviewController
open class CameraPreviewController: UIViewController {
    
    // MARK: Delegates
    open weak var delegate: CameraPreviewControllerDelegate?
    open weak var layoutSource: CameraPreviewControllerLayoutSource?
    open weak var faceDetectionDelegate: CameraPreviewControllerFaceDetectionDelegate?
    
    // MARK: Layout
    fileprivate var didSetupConstraints = false
    fileprivate var customConstraints = false
    
    // MARK: Basic
    open var cameraPosition: AVCaptureDevicePosition = .front
    open var capturePreset: String = AVCaptureSessionPresetHigh
    open var captureSequence: UInt64 = 0
    open var fillMode: GPUImageFillModeType = kGPUImageFillModePreserveAspectRatioAndFill
    open var resolution: CGSize = .zero
    
    let preview: GPUImageView = { return GPUImageView.newAutoLayout() }()
    var camera: GPUImageStillCamera!
    
    // MARK: Face
    var faceDetector: CIDetector?
    var faceViews = [UIView]()
    /** Setting this true invokes cameraPreviewDetectedFaces one per faceDetectFrequency frame. Default frequency is 10, if you want to detect face more frequent, set faceDetectFrequency as smaller number. */
    open var isFaceDetectorEnabled: Bool = false {
        willSet(isEnabled) {
            if isEnabled {
                if faceDetector == nil {
                    let detectorOptions = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
                    faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: detectorOptions)
                }
            } else {
                removeFaceViews()
            }
        }
    }
    /** Setting smaller number makes it detect face more frequent. Regards zero as default value 30. */
    open var faceDetectFrequency: UInt = 30
    
    // MARK: Filter
    /** Default filter for capturing still image, and this is recommeded by BradLarson in https://github.com/BradLarson/GPUImage/issues/1874 */
    var defaultFilter = GPUImageFilter()
    var filters = [GPUImageFilter]()
    var lastFilter: GPUImageOutput { return filters.last ?? defaultFilter }
    
    // MARK: Focus
    open var isTapFocusingEnabled: Bool = true {
        didSet {
            if isTapFocusingEnabled {
                setupTapFocusing()
            } else {
                clearTapFocusing()
            }
        }
    }
    var tapFocusingRecognizer: UITapGestureRecognizer?
    
    // MARK: Video
    var motionManager = CMMotionManager()
    var videoWriter: GPUImageMovieWriter?
    var videoUrl: URL?
    open var isRecordingVideo: Bool {
        if let videoWriter = self.videoWriter, let _ = self.videoUrl, !videoWriter.isPaused {
            return true
        } else {
            return false
        }
    }
    
    // MARK: Pinch to Zoom
    open var isPinchZoomingEnabled: Bool = true {
        didSet {
            if isPinchZoomingEnabled {
                setupPinchZooming()
            } else {
                clearPinchZooming()
            }
        }
    }
    var pinchToZoomGesture: UIPinchGestureRecognizer?
    var pivotPinchScale: CGFloat = 1
    
    // MARK: - Lifecycle for UIViewController
    override open func loadView() {
        super.loadView()
        view = UIView()
        view.backgroundColor = .white
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupPreview()
        setupCamera()
        setupNotification()
        startCapture()
        view.setNeedsUpdateConstraints()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override open func updateViewConstraints() {
        if !didSetupConstraints {
            if !customConstraints {
                preview.autoPinEdgesToSuperviewEdges()
            }
            didSetupConstraints = true
        }
        super.updateViewConstraints()
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        logd("Released \(type(of: self)).")
        clearTapFocusing()
        clearCamera()
        clearNotification()
    }
}

// MARK: - Lifecycle
extension CameraPreviewController: UIGestureRecognizerDelegate {
    
    func setupPreview() {
        
        // layout
        layoutSource?.cameraPreviewNeedsLayout(self, preview: preview)
        if let _ = preview.superview {
            customConstraints = true
        } else {
            view.addSubview(preview)
        }
        
        // config fill mode
        preview.fillMode = fillMode
        
        // transform preview by camera position
        switch cameraPosition {
        case .back:
            preview.transform = CGAffineTransform.identity
        default:
            preview.transform = preview.transform.scaledBy(x: -1, y: 1)
        }
        
        // tap to focus
        if isTapFocusingEnabled {
            setupTapFocusing()
        }
        
        // pinch to zoom
        if isPinchZoomingEnabled {
            setupPinchZooming()
        }
    }
    
    func setupCamera() {
        clearCamera()
        camera = GPUImageStillCamera(sessionPreset: capturePreset, cameraPosition: cameraPosition)
        switch cameraPosition {
        case .back:
            camera.outputImageOrientation = .portrait
        default:
            camera.outputImageOrientation = .portrait
        }
        camera.delegate = self
        camera.addTarget(defaultFilter)
        defaultFilter.addTarget(preview)
    }
    
    func setupNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillResignActive), name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }
    
    open func flipCamera() {
        switch cameraPosition {
        case .back:
            cameraPosition = .front
        default:
            cameraPosition = .back
        }
        camera.rotateCamera()
        setupPreview()
    }
    
    open func pauseCapture() {
        camera.pauseCapture()
    }
    
    open func resumeCapture() {
        camera.resumeCameraCapture()
    }
    
    open func startCapture() {
        if !camera.captureSession.isRunning {
            camera.startCapture()
        }
    }
    
    open func stopCapture() {
        if camera.captureSession.isRunning {
            camera.stopCapture()
        }
    }
    
    open func clearCamera() {
        if let camera = self.camera {
            if camera.captureSession.isRunning {
                camera.stopCapture()
            }
            camera.removeAllTargets()
            camera.removeInputsAndOutputs()
            camera.removeAudioInputsAndOutputs()
            camera.removeFramebuffer()
        }
        captureSequence = 0
    }
    
    open func clearNotification() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIApplicationWillResignActive, object: nil)
    }
}

// MARK: - Internal Methods
extension CameraPreviewController {
    
    func applicationWillResignActive(notification: Notification) {
        if isRecordingVideo {
            finishRecordingVideo()
            clearRecordingVideo()
        }
    }
    
    func fetchMetaInfo(_ sampleBuffer: CMSampleBuffer) {
        if captureSequence == 0 {
            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                loge("Failed to get image buffer from CMSampleBuffer object.")
                return
            }
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            resolution = CGSize(width: width, height: height)
            logi("Successfully fetched meta info from sample buffer.")
        }
    }
    
    open func findOrientation(completion: @escaping ((UIDeviceOrientation) -> ())) {
        
        guard motionManager.isAccelerometerAvailable else { return }
        
        let queue = OperationQueue()
        var isFound: Bool = false
        motionManager.startAccelerometerUpdates(to: queue) { (data, error) in
            
            guard let data = data, !isFound else { return }
            
            let angle = (atan2(data.acceleration.y,data.acceleration.x)) * 180 / Double.pi;
            
            self.motionManager.stopAccelerometerUpdates()
            isFound = true
            
            if fabs(angle) <= 45 {
                completion(.landscapeLeft)
                print("landscapeLeft")
            } else if fabs(angle) > 45 && fabs(angle) < 135 {
                if angle > 0 {
                    completion(.portraitUpsideDown)
                    print("portraitUpsideDown")
                } else {
                    completion(.portrait)
                    print("portrait")
                }
            } else {
                completion(.landscapeRight)
                print("landscapeRight")
            }
        }
    }
}

// MARK: - Implementation for GPUImageVideoCameraDelegate
extension CameraPreviewController: GPUImageVideoCameraDelegate {
    
    open func willOutputSampleBuffer(_ sampleBuffer: CMSampleBuffer!) {
        
        fetchMetaInfo(sampleBuffer)
        delegate?.cameraPreview(self, willOutput: sampleBuffer, with: captureSequence)
        captureSequence += 1
        
        guard isFaceDetectorEnabled && captureSequence % UInt64(faceDetectFrequency) == 0 else { return }
        
        faceFeatures(from: sampleBuffer, completion: { features, aperture, orientation in
            guard let features = features else { return }
            var faceFeatures = [CIFaceFeature]()
            for feature in features {
                if let faceFeature = feature as? CIFaceFeature {
                    faceFeatures.append(faceFeature)
                } else {
                    logw("CIFeature object is not a kind of CIFaceFeature.")
                }
            }
            if faceFeatures.count > 0 {
                self.faceDetectionDelegate?.cameraPreview(self, detected: faceFeatures, aperture: aperture, orientation: orientation)
            } else {
                self.faceDetectionDelegate?.cameraPreview(self, detected: nil, aperture: aperture, orientation: orientation)
            }
        })
    }
}
