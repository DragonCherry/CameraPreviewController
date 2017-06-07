//
//  CameraPreviewController+API.swift
//  Pods
//
//  Created by DragonCherry on 6/7/17.
//
//

import UIKit
import TinyLog
import GPUImage

// MARK: - Basic Camera
extension CameraPreviewController {
    
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
    
    func lockForConfiguration(_ task: ((AVCaptureDevice?, Bool) -> Void)?) {
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
        var imageOrientation: UIImageOrientation!
        switch cameraPosition {
        case .back:
            imageOrientation = .up
        default:
            imageOrientation = .upMirrored
        }
        camera.capturePhotoAsImageProcessedUp(toFilter: lastFilter, with: imageOrientation) { (image, error) in
            completion?(image)
        }
    }
}
