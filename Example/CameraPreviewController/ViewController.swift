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

class ViewController: CameraPreviewController {
    
    var addButton: UIButton!
    var detectButton: UIButton!
    var clearButton: UIButton!
    
    override func loadView() {
        super.loadView()
        delegate = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addButton = UIButton(height: 50, title: "Add", textSize: 15, textColor: .black, backgroundColor: UIColor(rgbHex: 0xCCFFCC), target: self, selector: #selector(pressedAdd))
        detectButton = UIButton(height: 50, title: "Detect", textSize: 15, textColor: .black, backgroundColor: UIColor(rgbHex: 0xFFCCCC), target: self, selector: #selector(pressedDetect))
        clearButton = UIButton(height: 50, title: "Clear", textSize: 15, textColor: .black, backgroundColor: UIColor(rgbHex: 0xCCCCFF), target: self, selector: #selector(pressedClear))
        
        // auto layout
        _ = view.attach(addButton, at: .bottomLeft, widthMultiplier: 1/3)
        _ = view.attach(detectButton, on: .right, of: addButton, widthMultiplier: 1/3)
        _ = view.attach(clearButton, on: .right, of: detectButton, widthMultiplier: 0)       // fill remaining width
    }
}

extension CameraPreviewController: CameraPreviewControllerDelegate {
    
    public func cameraPreviewNeedsLayout(preview: GPUImageView) {
        _ = view.attachFilling(preview, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
    }
    
    public func cameraPreviewPreferredFillMode(preview: GPUImageView) -> Bool {
        return true
    }
    
    public func cameraPreviewDetectedFaces(preview: GPUImageView, features: [CIFeature]?, aperture: CGRect, orientation: UIDeviceOrientation) {
        
        guard let features = features, features.count > 0 else {
            return
        }
        var faces = [CIFaceFeature]()
        
        for feature in features {
            if let face = feature as? CIFaceFeature {
                faces.append(face)
            } else {
                print("CIFeature object is not a kind of CIFaceFeature.")
            }
        }
        
        showFaceRects(faces, aperture: aperture, orientation: orientation)
        
        print("detected face count: \(faces.count)")
        for (i, face) in faces.enumerated() {
            print("### FACE NO.\(i + 1)")
            print("hasFaceAngle: \(face.hasFaceAngle) -> \(face.faceAngle)")
            print("leftEyeClosed: \(face.leftEyeClosed)")
            print("hasLeftEyePosition: \(face.hasLeftEyePosition) -> \(face.leftEyePosition)")
            print("rightEyeClosed: \(face.rightEyeClosed)")
            print("hasRightEyePosition: \(face.hasRightEyePosition) -> \(face.rightEyePosition)")
            print("hasMouthPosition: \(face.hasMouthPosition) -> \(face.mouthPosition)")
            print("hasSmile: \(face.hasSmile)")
        }
    }
}

extension CameraPreviewController {
    
    public func pressedAdd(sender: UIButton) {
        
        let sepiaFilter = GPUImageSepiaFilter()
        sepiaFilter.intensity = 1
        add(filter: sepiaFilter)
    }
    
    public func pressedDetect(sender: UIButton) {
        faceDetectFrequency = 10
        isFaceDetectorEnabled = true
    }
    
    public func pressedClear(sender: UIButton) {
        removeFilters()
    }
}
