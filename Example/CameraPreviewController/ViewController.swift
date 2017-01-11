//
//  ViewController.swift
//  CameraPreviewController
//
//  Created by DragonCherry on 01/10/2017.
//  Copyright (c) 2017 DragonCherry. All rights reserved.
//

import UIKit
import GPUImage
import AttachLayout
import SwiftARGB
import CameraPreviewController
import TinyLog

extension UIView {
    func showBorder() {
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
    }
}

class ViewController: CameraPreviewController {
    
    // Buttons for basic functionalities
    var btnToggleCamera: UIButton!
    var btnToggleFlash: UIButton!
    
    // Buttons for recognization functionalities
    var btnToggleDetectFace: UIButton!
    
    // Buttons for effect functionalities
    var btnAddFilter: UIButton!
    var btnClearFilters: UIButton!
    
    override func loadView() {
        super.loadView()
        delegate = self
        faceDetectionDelegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let height: CGFloat = 40
        let textSize: CGFloat = 10
        let basicColor: UIColor = UIColor(rgbHex: 0xEEEEFF)
        let recognitionColor: UIColor = UIColor(rgbHex: 0xEEFFEE)
        let effectColor: UIColor = UIColor(rgbHex: 0xFFEEEE)
        let textColor: UIColor = .black
        
        // Buttons for basic functionalities
        btnToggleCamera = UIButton(height: height, title: "Toggle Camera", textSize: textSize, textColor: textColor, backgroundColor: basicColor, target: self, selector: #selector(pressedToggleCamera))
        btnToggleFlash = UIButton(height: height, title: "Toggle Flash", textSize: textSize, textColor: textColor, backgroundColor: basicColor, target: self, selector: #selector(pressedToggleFlash))
        
        // Buttons for recognization functionalities
        btnToggleDetectFace = UIButton(height: height, title: "Enable Face Detection", textSize: textSize, textColor: textColor, backgroundColor: recognitionColor, target: self, selector: #selector(pressedToggleDetect))
        
        // Buttons for effect functionalities
        btnAddFilter = UIButton(height: height, title: "Add Filter", textSize: textSize, textColor: textColor, backgroundColor: effectColor, target: self, selector: #selector(pressedAddFilter))
        btnClearFilters = UIButton(height: height, title: "Clear Filters", textSize: textSize, textColor: textColor, backgroundColor: effectColor, target: self, selector: #selector(pressedClearFilters))
        
        // auto layout
        _ = view.attach(btnAddFilter, at: .bottomLeft, widthMultiplier: 1/2)
        _ = view.attach(btnClearFilters, on: .right, of: btnAddFilter, widthMultiplier: 1/2)
        
        _ = view.attach(btnToggleDetectFace, on: .top, of: btnAddFilter, widthMultiplier: 0)
        
        _ = view.attach(btnToggleCamera, on: .top, of: btnToggleDetectFace, widthMultiplier: 1/2)
        _ = view.attach(btnToggleFlash, on: .right, of: btnToggleCamera, widthMultiplier: 1/2)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btnToggleCamera.showBorder()
        btnToggleFlash.showBorder()
        btnToggleDetectFace.showBorder()
        btnAddFilter.showBorder()
        btnClearFilters.showBorder()
    }
}

extension CameraPreviewController {
    
    public func pressedToggleCamera(sender: UIButton) {
        flipCamera()
        switch cameraPosition {
        case .back:
            sender.setTitle("Front Camera", for: .normal)
        default:
            sender.setTitle("Back Camera", for: .normal)
        }
    }
    
    public func pressedToggleFlash(sender: UIButton) {
        switch torchMode {
        case .auto:
            torchMode = .on
            sender.setTitle("Torch: Turn on", for: .normal)
        case .on:
            torchMode = .off
            sender.setTitle("Torch: Turn off", for: .normal)
        case .off:
            torchMode = .auto
            sender.setTitle("Torch: Set auto", for: .normal)
        }
    }
    
    public func pressedToggleDetect(sender: UIButton) {
        isFaceDetectorEnabled = !isFaceDetectorEnabled
        if isFaceDetectorEnabled {
            faceDetectFrequency = 10
            sender.setTitle("Disable Face Detection", for: .normal)
        } else {
            sender.setTitle("Enable Face Detection", for: .normal)
        }
    }
    
    public func pressedAddFilter(sender: UIButton) {
        let sepiaFilter = GPUImageSepiaFilter()
        sepiaFilter.intensity = 1
        add(filter: sepiaFilter)
    }
    public func pressedClearFilters(sender: UIButton) {
        removeFilters()
    }
}

extension CameraPreviewController: CameraPreviewControllerDelegate {
    
    public func cameraPreviewWillOutputSampleBuffer(buffer: CMSampleBuffer, sequence: UInt64) {
        
    }
    
    public func cameraPreviewNeedsLayout(preview: GPUImageView) {
        _ = view.attachFilling(preview, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
    }
    
    public func cameraPreviewPreferredFillMode(preview: GPUImageView) -> Bool {
        return true
    }
    
}

extension CameraPreviewController: CameraPreviewControllerFaceDetectionDelegate {
    public func cameraPreviewDetectedFaces(preview: GPUImageView, features: [CIFeature]?, aperture: CGRect, orientation: UIDeviceOrientation) {
        
        guard let features = features, features.count > 0 else {
            return
        }
        var faces = [CIFaceFeature]()
        
        for feature in features {
            if let face = feature as? CIFaceFeature {
                faces.append(face)
            } else {
                logw("CIFeature object is not a kind of CIFaceFeature.")
            }
        }
        
        showFaceRects(faces, aperture: aperture, orientation: orientation)
        
        logd("detected face count: \(faces.count)")
        for (i, face) in faces.enumerated() {
            log("### FACE NO.\(i + 1)")
            log("hasFaceAngle: \(face.hasFaceAngle) -> \(face.faceAngle)")
            log("leftEyeClosed: \(face.leftEyeClosed)")
            log("hasLeftEyePosition: \(face.hasLeftEyePosition) -> \(face.leftEyePosition)")
            log("rightEyeClosed: \(face.rightEyeClosed)")
            log("hasRightEyePosition: \(face.hasRightEyePosition) -> \(face.rightEyePosition)")
            log("hasMouthPosition: \(face.hasMouthPosition) -> \(face.mouthPosition)")
            log("hasSmile: \(face.hasSmile)")
        }
    }
}


