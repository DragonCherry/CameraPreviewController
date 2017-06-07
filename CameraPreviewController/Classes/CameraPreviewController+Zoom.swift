//
//  CameraPreviewController+Zoom.swift
//  Pods
//
//  Created by DragonCherry on 6/7/17.
//
//

import UIKit

// MARK: - Pinch to Zoom
extension CameraPreviewController {
    
    func setupPinchZooming() {
        clearPinchZooming()
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(pinchedCameraPreview))
        pinchGesture.delegate = self
        preview.addGestureRecognizer(pinchGesture)
        self.pinchToZoomGesture = pinchGesture
    }
    
    func clearPinchZooming() {
        if let pinchGesture = self.pinchToZoomGesture {
            pinchGesture.removeTarget(self, action: #selector(pinchedCameraPreview))
            preview.removeGestureRecognizer(pinchGesture)
            self.tapFocusingRecognizer = nil
        }
    }
    
    func pinchedCameraPreview(gesture: UIPinchGestureRecognizer) {
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
