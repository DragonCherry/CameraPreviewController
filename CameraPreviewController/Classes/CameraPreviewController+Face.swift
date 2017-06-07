//
//  CameraPreviewController+Face.swift
//  Pods
//
//  Created by DragonCherry on 6/7/17.
//
//

import UIKit
import GPUImage
import TinyLog

// MARK: - Face Detection
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
    
    open func faceFeatures(from sampleBuffer: CMSampleBuffer, completion: (([CIFeature]?, CGRect, UIDeviceOrientation) -> Void)?) {
        
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
            
            faceFrame = faceFrame.offsetBy(dx: preview.frame.origin.x, dy: preview.frame.origin.y)
            
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
