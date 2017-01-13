//
//  CameraPreviewController.swift
//  Pods
//
//  Created by DragonCherry on 1/5/17.
//
//

import UIKit
import TinyLog
import AttachLayout
import GPUImage

// MARK: - Declaration for CameraPreviewControllerDelegate
public protocol CameraPreviewControllerDelegate: class {
    func cameraPreview(_ controller: CameraPreviewController, willOutput sampleBuffer: CMSampleBuffer, with sequence: UInt64)
    func cameraPreview(_ controller: CameraPreviewController, willFocusInto tappedLocationInView: CGPoint, tappedLocationInImage: CGPoint)
}

// MARK: - Declaration for CameraPreviewControllerLayoutSource
public protocol CameraPreviewControllerLayoutSource: class {
    func cameraPreviewNeedsLayout(_ controller: CameraPreviewController, preview: GPUImageView)
    func cameraPreviewNeedsFillMode(_ controller: CameraPreviewController) -> Bool
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
    
    // MARK: Common Properties
    open var cameraPosition: AVCaptureDevicePosition = .front
    open var capturePreset: String = AVCaptureSessionPresetHigh
    open var captureSequence: UInt64 = 0
    private var _resolution: CGSize = .zero
    open var resolution: CGSize {
        get { return _resolution }
        set { _resolution = newValue }
    }
    
    fileprivate var camera: GPUImageStillCamera!
    fileprivate var preview: GPUImageView!
    
    // MARK: Filter
    /** Default filter for capturing still image, and this is recommeded by BradLarson in https://github.com/BradLarson/GPUImage/issues/1874 */
    fileprivate var defaultFilter: GPUImageFilter! = GPUImageFilter()
    fileprivate var filters = [GPUImageFilter]()
    fileprivate var lastFilter: GPUImageOutput? { return filters.last }
    
    // MARK: Face Detection
    fileprivate var faceDetector: CIDetector?
    fileprivate var faceViews = [UIView]()
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
    
    // MARK: Tap to Focus
    open var isTapToFocusEnabled: Bool = true {
        didSet {
            if isTapToFocusEnabled {
                initTapToFocusGesture()
            } else {
                deinitTapToFocusGesture()
            }
        }
    }
    fileprivate var tapToFocusGesture: UITapGestureRecognizer?
    
    // MARK: Pinch to Zoom
    open var isPinchToZoomEnabled: Bool = true {
        didSet {
            if isPinchToZoomEnabled {
                initPinchToZoomGesture()
            } else {
                deinitPinchToZoomGesture()
            }
        }
    }
    fileprivate var pinchToZoomGesture: UIPinchGestureRecognizer?
    fileprivate var pivotPinchScale: CGFloat = 1
    
    // MARK: - Lifecycle for UIViewController
    override open func viewDidLoad() {
        super.viewDidLoad()
        initPreview()
        initCamera()
        startCapture()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    deinit {
        deinitTapToFocusGesture()
        deinitCamera()
    }
}

// MARK: - Lifecycle APIs
extension CameraPreviewController: UIGestureRecognizerDelegate {
    
    open func initPreview() {
        if preview == nil {
            preview = GPUImageView()
            layoutSource?.cameraPreviewNeedsLayout(self, preview: preview)
            if preview.superview == nil {
                _ = view.attachFilling(preview)
            }
        }
        
        // config fill mode
        if let prefersFillMode = layoutSource?.cameraPreviewNeedsFillMode(self), prefersFillMode {
            preview.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
        }
        
        // transform preview by camera position
        switch cameraPosition {
        case .back:
            preview.transform = CGAffineTransform.identity
        default:
            preview.transform = preview.transform.scaledBy(x: -1, y: 1)
        }
        
        // tap to focus
        if isTapToFocusEnabled {
            initTapToFocusGesture()
        }
        
        // pinch to zoom
        if isPinchToZoomEnabled {
            initPinchToZoomGesture()
        }
    }
    
    open func initCamera() {
        deinitCamera()
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
    
    open func flipCamera() {
        switch cameraPosition {
        case .back:
            cameraPosition = .front
        default:
            cameraPosition = .back
        }
        camera.rotateCamera()
        initPreview()
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
    
    open func deinitCamera() {
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
}

// MARK: - Internal Methods
extension CameraPreviewController {
    
    fileprivate func fetchMetaInfo(_ sampleBuffer: CMSampleBuffer) {
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
}

// MARK: - Tap to Focus
extension CameraPreviewController {
    
    open func initTapToFocusGesture() {
        deinitTapToFocusGesture()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedCameraPreview))
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        tapGesture.delegate = self
        preview.addGestureRecognizer(tapGesture)
        self.tapToFocusGesture = tapGesture
    }
    
    open func deinitTapToFocusGesture() {
        if let tapGesture = self.tapToFocusGesture {
            tapGesture.removeTarget(self, action: #selector(tappedCameraPreview))
            preview.removeGestureRecognizer(tapGesture)
            self.tapToFocusGesture = nil
        }
    }
    
    open func tappedCameraPreview(gesture: UITapGestureRecognizer) {
        logi("User tapped camera preview.")
        guard resolution != .zero else {
            logw("Cannot convert and locate point to focus into since resolution for current image is not ready yet.")
            return
        }
        let point = gesture.location(in: preview)
        
        let scaleX = point.x / preview.width
        let scaleY = point.y / preview.height
        
        if camera.inputCamera.isFocusPointOfInterestSupported {
            lockForConfiguration({ (device, locked) in
                guard let device = device, locked else { return }
                let locationInImage = CGPoint(x: scaleX, y: scaleY)
                device.focusPointOfInterest = locationInImage
                if device.isFocusModeSupported(.continuousAutoFocus) {
                    device.focusMode = .continuousAutoFocus
                } else if device.isFocusModeSupported(.autoFocus) {
                    device.focusMode = .autoFocus
                }
                switch self.cameraPosition {
                case .back:
                    self.delegate?.cameraPreview(self, willFocusInto: point, tappedLocationInImage: locationInImage)
                default:
                    self.delegate?.cameraPreview(
                        self,
                        willFocusInto: CGPoint(x: self.preview.width - point.x, y: point.y),
                        tappedLocationInImage: CGPoint(x: 1 - locationInImage.x, y: point.y)
                    )
                }
            })
        }
    }
}

// MARK: - Pinch to Zoom
extension CameraPreviewController {
    
    open func initPinchToZoomGesture() {
        deinitPinchToZoomGesture()
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchedCameraPreview))
        pinchGesture.delegate = self
        preview.addGestureRecognizer(pinchGesture)
        self.pinchToZoomGesture = pinchGesture
    }
    
    open func deinitPinchToZoomGesture() {
        if let pinchGesture = self.pinchToZoomGesture {
            pinchGesture.removeTarget(self, action: #selector(pinchedCameraPreview))
            preview.removeGestureRecognizer(pinchGesture)
            self.tapToFocusGesture = nil
        }
    }
    
    open func pinchedCameraPreview(gesture: UIPinchGestureRecognizer) {
        lockForConfiguration { (device, locked) in
            guard let device = device, locked else { return }
            
            switch gesture.state {
            case .began:
                self.pivotPinchScale = device.videoZoomFactor
            case .changed:
                var factor = self.pivotPinchScale * gesture.scale
                factor = max(1, min(factor, device.activeFormat.videoMaxZoomFactor))
                device.videoZoomFactor = factor
            case .failed, .ended:
                break
            default:
                break
            }
        }
    }
}

// MARK: - Camera APIs
extension CameraPreviewController {
    
    fileprivate func lockForConfiguration(_ task: ((AVCaptureDevice?, Bool) -> Void)?) {
        guard let device = camera.inputCamera else {
            loge("Failed to get inputCamera.")
            task?(nil, false)
            return
        }
        do {
            try device.lockForConfiguration()
            task?(device, true)
            device.unlockForConfiguration()
        } catch {
            logw("Failed to lock camera for configuration.")
            task?(device, false)
        }
    }
    
    open var torchMode: AVCaptureTorchMode {
        set(newMode) {
            if let device = camera.inputCamera, device.hasTorch {
                lockForConfiguration({ (_, locked) in
                    if locked {
                        device.torchMode = newMode
                    }
                })
            } else {
                logw("Torch is not available in current camera.")
            }
        }
        get {
            return camera.inputCamera.torchMode
        }
    }
    
    open func image(from sampleBuffer: CMSampleBuffer) -> UIImage? {
        
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            loge("Failed to get image buffer from CMSampleBuffer object.")
            return nil
        }
        
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer, .readOnly)
        
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        // Create a bitmap graphics context with the sample buffer data
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        if let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue) {
            // Create a Quartz image from the pixel data in the bitmap graphics context
            if let quartzImage = context.makeImage() {
                // Create an image object from the Quartz image
                let image = UIImage(cgImage: quartzImage)
                // Unlock the pixel buffer
                CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
                return image
            }
        }
        CVPixelBufferUnlockBaseAddress(imageBuffer, .readOnly)
        return nil
    }
    
    open func takePhoto(_ completion: ((UIImage?) -> Void)?) {
        var filterToCapture: GPUImageOutput!
        if let lastFilter = self.lastFilter {
            filterToCapture = lastFilter
        } else {
            filterToCapture = defaultFilter
        }
        var imageOrientation: UIImageOrientation!
        switch cameraPosition {
        case .back:
            imageOrientation = .up
        default:
            imageOrientation = .upMirrored
        }
        camera.capturePhotoAsImageProcessedUp(toFilter: filterToCapture, with: imageOrientation) { (image, error) in
            completion?(image)
        }
    }
}


// MARK: - Filter APIs
extension CameraPreviewController {
    
    open func contains(targetFilter: GPUImageFilter?) -> Bool {
        guard let targetFilter = targetFilter else { return false }
        for filter in filters {
            if filter == targetFilter {
                return true
            }
        }
        return false
    }
    
    open func add(filter: GPUImageFilter?) {
        guard let filter = filter, !contains(targetFilter: filter) else { return }
        if let lastFilter = self.lastFilter {
            lastFilter.removeAllTargets()
            lastFilter.addTarget(filter)
        } else {
            defaultFilter.removeAllTargets()
            defaultFilter.addTarget(filter)
        }
        filter.addTarget(preview)
        filters.append(filter)
    }
    
    open func add(newFilters: [GPUImageFilter]?) {
        guard let newFilters = newFilters, let firstNewFilter = newFilters.first, newFilters.count > 0 else { return }
        if let lastFilter = self.lastFilter {
            lastFilter.removeAllTargets()
            lastFilter.addTarget(firstNewFilter)
        } else {
            defaultFilter.removeAllTargets()
            defaultFilter.addTarget(firstNewFilter)
        }
        filters.append(contentsOf: filters)
        filters.last?.addTarget(preview)
    }
    
    open func removeFilters() {
        defaultFilter.removeAllTargets()
        for filter in filters {
            filter.removeAllTargets()
            filter.removeFramebuffer()
        }
        filters.removeAll()
        defaultFilter.addTarget(preview)
    }
}

// MARK: - Detection APIs
extension CameraPreviewController {
    
    private enum EXIFOrientation: Int {
        case PHOTOS_EXIF_0ROW_TOP_0COL_LEFT		= 1 //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
        case PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT    = 2 //   2  =  0th row is at the top, and 0th column is on the right.
        case PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT = 3 //   3  =  0th row is at the bottom, and 0th column is on the right.
        case PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT  = 4 //   4  =  0th row is at the bottom, and 0th column is on the left.
        case PHOTOS_EXIF_0ROW_LEFT_0COL_TOP     = 5 //   5  =  0th row is on the left, and 0th column is the top.
        case PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP    = 6 //   6  =  0th row is on the right, and 0th column is the top.
        case PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM = 7 //   7  =  0th row is on the right, and 0th column is the bottom.
        case PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM  = 8 //   8  =  0th row is on the left, and 0th column is the bottom.
    }
    
    open func features(from sampleBuffer: CMSampleBuffer, completion: (([CIFeature]?, CGRect, UIDeviceOrientation) -> Void)?) {
        
        DispatchQueue.global(qos: .background).async(execute: {
            
            let orientation = UIDevice.current.orientation
            let failBlock = {
                DispatchQueue.main.async(execute: {
                    completion?(nil, .zero, orientation)
                })
            }
            
            guard let cvPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
                loge("Failed to get pixel buffer using CMSampleBuffer object.")
                failBlock()
                return
            }
            guard let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate) as? [String: Any] else {
                loge("Failed to get attachments using CVImageBuffer object.")
                failBlock()
                return
            }
            
            let ciImage = CIImage(cvPixelBuffer: cvPixelBuffer, options: attachments)
            var exifOrientation: EXIFOrientation = .PHOTOS_EXIF_0ROW_TOP_0COL_LEFT
            
            switch orientation {
            case .portraitUpsideDown:           // device oriented vertically, home button on the top
                exifOrientation = .PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
                break;
            case .landscapeLeft:                // device oriented horizontally, home button on the right
                if self.cameraPosition == .front {
                    exifOrientation = .PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT
                } else {
                    exifOrientation = .PHOTOS_EXIF_0ROW_TOP_0COL_LEFT
                }
            case .landscapeRight:               // device oriented horizontally, home button on the left
                if self.cameraPosition == .front {
                    exifOrientation = .PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
                } else {
                    exifOrientation = .PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
                }
            case .portrait, .faceUp, .faceDown: // device oriented vertically, home button on the bottom
                exifOrientation = .PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP
            default:
                exifOrientation = .PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP
            }
            
            let detectorOptions = [CIDetectorImageOrientation: NSNumber(value: exifOrientation.rawValue)]
            if let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) {
                let aperture = CMVideoFormatDescriptionGetCleanAperture(formatDescription, false)
                guard let faceFeatures = self.faceDetector?.features(in: ciImage, options: detectorOptions) else {
                    failBlock()
                    return
                }
                DispatchQueue.main.async(execute: {
                    completion?(faceFeatures, aperture, orientation)
                })
            } else {
                failBlock()
            }
        })
    }
    
    open func removeFaceViews() {
        for faceView in faceViews {
            faceView.removeFromSuperview()
        }
        faceViews.removeAll()
    }
    
    open func showFaceRects(_ faceFeatures: [CIFaceFeature]?, aperture: CGRect, orientation: UIDeviceOrientation, viewSource: (() -> UIView?)? = nil) {
        guard let faceFeatures = faceFeatures, faceFeatures.count > 0, isFaceDetectorEnabled else {
            removeFaceViews()
            return
        }
        
        let previewFrame = preview.frame
        removeFaceViews()
        
        for faceFeature in faceFeatures {
            var faceFrame = faceFeature.bounds
            
            // flip preview width and height
            var temp: CGFloat = faceFrame.width
            faceFrame.size.width = faceFrame.height
            faceFrame.size.height = temp
            temp = faceFrame.origin.x
            faceFrame.origin.x = faceFrame.origin.y
            faceFrame.origin.y = temp
            
            // scale coordinates so they fit in the preview box, which may be scaled
            let widthScaleBy = previewFrame.width / aperture.size.height
            let heightScaleBy = previewFrame.height / aperture.size.width
            
            faceFrame.origin.x *= widthScaleBy
            faceFrame.origin.y *= heightScaleBy
            faceFrame.size.width *= widthScaleBy
            faceFrame.size.height *= heightScaleBy
            
            faceFrame = faceFrame.offsetBy(dx: preview.origin.x, dy: preview.origin.y)
            
            var faceView: UIView!
            
            if let rectView = viewSource?() {
                faceView = rectView
                faceView.frame = faceFrame
            } else {
                faceView = UIView(frame: faceFrame)
                faceView.layer.borderWidth = 1
                faceView.layer.borderColor = UIColor.red.cgColor
            }
            preview.addSubview(faceView)
            faceViews.append(faceView)
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
        
        features(from: sampleBuffer, completion: { features, aperture, orientation in
            guard let features = features else { return }
            var faceFeatures = [CIFaceFeature]()
            for feature in features {
                if let faceFeature = feature as? CIFaceFeature {
                    faceFeatures.append(faceFeature)
                } else {
                    print("CIFeature object is not a kind of CIFaceFeature.")
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
