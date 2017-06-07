//
//  CameraPreviewController+Focus.swift
//  Pods
//
//  Created by DragonCherry on 6/7/17.
//
//

import UIKit
import TinyLog

// MARK: - Tap to Focus
extension CameraPreviewController {
    
    func setupTapFocusing() {
        clearTapFocusing()
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(tappedCameraPreview))
        recognizer.numberOfTapsRequired = 1
        recognizer.numberOfTouchesRequired = 1
        recognizer.delegate = self
        preview.addGestureRecognizer(recognizer)
        self.tapFocusingRecognizer = recognizer
    }
    
    func clearTapFocusing() {
        if let recognizer = self.tapFocusingRecognizer {
            recognizer.removeTarget(self, action: #selector(tappedCameraPreview))
            preview.removeGestureRecognizer(recognizer)
            self.tapFocusingRecognizer = nil
        }
    }
    
    func tappedCameraPreview(gesture: UITapGestureRecognizer) {
        guard resolution != .zero else {
            logw("Cannot convert and locate point to focus into since resolution for current image is not ready yet.")
            return
        }
        let point = gesture.location(in: preview)
        
        let scaleX = point.x / preview.bounds.width
        let scaleY = point.y / preview.bounds.height
        
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
                        willFocusInto: CGPoint(x: self.preview.bounds.width - point.x, y: point.y),
                        tappedLocationInImage: CGPoint(x: 1 - locationInImage.x, y: point.y)
                    )
                }
            })
        }
    }
}
