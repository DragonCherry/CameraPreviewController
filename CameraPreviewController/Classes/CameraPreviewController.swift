//
//  CameraPreviewController.swift
//  Pods
//
//  Created by DragonCherry on 1/5/17.
//
//

import UIKit
import AttachLayout
import GPUImage

public protocol CameraPreviewControllerDelegate: class {
    func cameraPreviewWillOutputSampleBuffer(buffer: CMSampleBuffer, sequence: UInt64)
    func cameraPreviewNeedsLayout(preview: GPUImageView)
    func cameraPreviewPreferredFillMode(preview: GPUImageView) -> Bool
}

public protocol CameraPreviewControllerFaceDetectionDelegate: class {
    func cameraPreviewDetectedFaces(preview: GPUImageView, features: [CIFeature]?, aperture: CGRect, orientation: UIDeviceOrientation)
    
}

open class CameraPreviewController: UIViewController {
    
    open weak var delegate: CameraPreviewControllerDelegate?
    open weak var faceDetectionDelegate: CameraPreviewControllerFaceDetectionDelegate?
    
    open var cameraPosition: AVCaptureDevicePosition = .front
    open var capturePreset: String = AVCaptureSessionPresetHigh
    
    /** Setting this true invokes cameraPreviewDetectedFaces one per faceDetectFrequency frame. Default frequency is 10, if you want to detect face more frequent, set faceDetectFrequency as smaller number. */
    open var isFaceDetectorEnabled: Bool = false {
        willSet(isEnabled) {
            if isEnabled {
                if faceDetector == nil {
                    let detectorOptions = [CIDetectorAccuracy: CIDetectorAccuracyLow]
                    faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: detectorOptions)
                }
            } else {
                removeFaceViews()
            }
        }
    }
    /** Setting smaller number makes it detect face more frequent. Regards zero as default value 30. */
    open var faceDetectFrequency: UInt = 30
    open var captureCount: UInt64 = 0
    
    fileprivate var camera: GPUImageVideoCamera!
    fileprivate var preview: GPUImageView!
    fileprivate var filters = [GPUImageFilter]()
    fileprivate var lastFilter: GPUImageFilter? { return filters.last }
    fileprivate var faceDetector: CIDetector?
    fileprivate var faceViews = [UIView]()
    
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
        deinitCamera()
    }
}

// MARK: - Lifecycle APIs
extension CameraPreviewController {
    
    open func initPreview() {
        if preview == nil {
            preview = GPUImageView()
            
            if let prefersFillMode = delegate?.cameraPreviewPreferredFillMode(preview: preview), prefersFillMode {
                preview.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
            }
            
            switch cameraPosition {
            case .front:
                preview.transform = preview.transform.scaledBy(x: -1, y: 1)
                break
            default:
                break
            }
            
            delegate?.cameraPreviewNeedsLayout(preview: preview)
            if preview.superview == nil {
                _ = view.attachFilling(preview)
            }
        }
    }
    
    open func initCamera() {
        deinitCamera()
        camera = GPUImageVideoCamera(sessionPreset: capturePreset, cameraPosition: cameraPosition)
        camera.outputImageOrientation = .portrait
        camera.delegate = self
        camera.addTarget(preview)
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
        captureCount = 0
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
            camera.removeAllTargets()
            camera.addTarget(filter)
        }
        filter.addTarget(preview)
        filters.append(filter)
    }
    
    open func add(newFilters: [GPUImageFilter]?) {
        guard let newFilters = newFilters, let firstFilter = newFilters.first, newFilters.count > 0 else { return }
        if let lastFilter = self.lastFilter {
            lastFilter.removeAllTargets()
            lastFilter.addTarget(firstFilter)
        } else {
            camera.addTarget(firstFilter)
        }
        filters.append(contentsOf: filters)
        filters.last?.addTarget(preview)
    }
    
    open func removeFilters() {
        camera.removeAllTargets()
        for filter in filters {
            filter.removeAllTargets()
            filter.removeFramebuffer()
        }
        filters.removeAll()
        camera.addTarget(preview)
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
        guard let faceFeatures = faceFeatures, faceFeatures.count > 0 else { return }
        
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

extension CameraPreviewController: GPUImageVideoCameraDelegate {
    
    open func willOutputSampleBuffer(_ sampleBuffer: CMSampleBuffer!) {
        
        delegate?.cameraPreviewWillOutputSampleBuffer(buffer: sampleBuffer, sequence: captureCount)
        captureCount += 1
        
        guard isFaceDetectorEnabled && captureCount % UInt64(faceDetectFrequency) == 0 else { return }
        
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
            self.faceDetectionDelegate?.cameraPreviewDetectedFaces(preview: self.preview, features: faceFeatures, aperture: aperture, orientation: orientation)
        })
    }
}
