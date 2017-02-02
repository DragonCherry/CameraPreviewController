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
    var btnTakePhoto: UIButton!
    
    // Buttons for creating GIF
    var btnCreateGIF: UIButton!
    
    // Buttons for recognization functionalities
    var btnToggleDetectFace: UIButton!
    
    // Buttons for effect functionalities
    var btnAddFilter: UIButton!
    var btnClearFilters: UIButton!
    
    override func loadView() {
        super.loadView()
        cameraPosition = .back          // initial camera position
        
        // set delegates
        delegate = self
        layoutSource = self
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
        btnTakePhoto = UIButton(height: height, title: "Take Photo", textSize: textSize, textColor: textColor, backgroundColor: basicColor, target: self, selector: #selector(pressedTakePhoto))
        btnCreateGIF = UIButton(height: height)
        btnCreateGIF.setTitle("Create GIF", for: .normal)
        btnCreateGIF.setTitleColor(textColor, for: .normal)
        btnCreateGIF.backgroundColor = basicColor
        btnCreateGIF.titleLabel?.font = UIFont.systemFont(ofSize: textSize)
        btnCreateGIF.addTarget(self, action: #selector(startCreateGIF), for: .touchDown)
        btnCreateGIF.addTarget(self, action: #selector(finishCreateGIF), for: .touchUpInside)
        
        // Buttons for recognization functionalities
        btnToggleDetectFace = UIButton(height: height, title: "Enable Face Detection", textSize: textSize, textColor: textColor, backgroundColor: recognitionColor, target: self, selector: #selector(pressedToggleDetect))
        
        // Buttons for effect functionalities
        btnAddFilter = UIButton(height: height, title: "Add Filter", textSize: textSize, textColor: textColor, backgroundColor: effectColor, target: self, selector: #selector(pressedAddFilter))
        btnClearFilters = UIButton(height: height, title: "Clear Filters", textSize: textSize, textColor: textColor, backgroundColor: effectColor, target: self, selector: #selector(pressedClearFilters))
        
        // auto layout
        _ = view.attach(btnAddFilter, at: .bottomLeft, widthMultiplier: 1/2)
        _ = view.attach(btnClearFilters, on: .right, of: btnAddFilter, widthMultiplier: 1/2)
        
        _ = view.attach(btnToggleDetectFace, on: .top, of: btnAddFilter, widthMultiplier: 0)
        
        _ = view.attach(btnToggleCamera, on: .top, of: btnToggleDetectFace, widthMultiplier: 1/4)
        _ = view.attach(btnToggleFlash, on: .right, of: btnToggleCamera, widthMultiplier: 1/4)
        _ = view.attach(btnTakePhoto, on: .right, of: btnToggleFlash, widthMultiplier: 1/4)
        _ = view.attach(btnCreateGIF, on: .right, of: btnTakePhoto, widthMultiplier: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        btnToggleCamera.showBorder()
        btnToggleFlash.showBorder()
        btnTakePhoto.showBorder()
        btnCreateGIF.showBorder()
        btnToggleDetectFace.showBorder()
        btnAddFilter.showBorder()
        btnClearFilters.showBorder()
    }
}

extension ViewController {
    
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
    
    public func pressedTakePhoto(sender: UIButton) {
        takePhoto({ image in
            let photoVC = PhotoViewController()
            photoVC.image = image
            self.present(photoVC, animated: true, completion: nil)
        })
    }
    
    public func startCreateGIF(sender: UIButton) {
        isCapturingGIF = true
    }
    
    public func finishCreateGIF(sender: UIButton) {
        isCapturingGIF = false
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

// MARK: - Implementation for CameraPreviewControllerDelegate
extension ViewController: CameraPreviewControllerDelegate {
    func cameraPreview(_ controller: CameraPreviewController, willOutput sampleBuffer: CMSampleBuffer, with sequence: UInt64) {
        
    }
    func cameraPreview(_ controller: CameraPreviewController, willFocusInto locationInView: CGPoint, tappedLocationInImage locationInImage: CGPoint) {
        logi("Focusing location in view: \(locationInView)")
        logi("Focusing location(ratio) in image: \(locationInImage)")
    }
    func cameraPreview(_ controller: CameraPreviewController, willOutputGIF gifURL: URL?) {
        guard let gifURL = gifURL else {
            logw("Failed to create GIF file.")
            return
        }
        do {
            let gifData = try Data(contentsOf: gifURL)
            if let image = UIImage(data: gifData) {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(finishedWriteImageToSavedPhotosAlbum), nil)
            }
        } catch {
            loge("\(error.localizedDescription)")
        }
    }
    
    func finishedWriteImageToSavedPhotosAlbum(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            logi("Failed to save GIF image to photos album with error: \(error)")
        } else {
            logi("Successfully saved GIF image to photos album.")
        }
    }
}

// MARK: - Implementation for CameraPreviewControllerLayoutSource
extension ViewController: CameraPreviewControllerLayoutSource {
    func cameraPreviewNeedsLayout(_ controller: CameraPreviewController, preview: GPUImageView) {
        _ = view.attachFilling(preview, insets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
    }
    func cameraPreviewNeedsFillMode(_ controller: CameraPreviewController) -> Bool {
        return true     // false to aspect fit mode
    }
}

// MARK: - Implementation for CameraPreviewControllerFaceDetectionDelegate
extension ViewController: CameraPreviewControllerFaceDetectionDelegate {
    func cameraPreview(_ controller: CameraPreviewController, detected faceFeatures: [CIFaceFeature]?, aperture: CGRect, orientation: UIDeviceOrientation) {
        
        showFaceRects(faceFeatures, aperture: aperture, orientation: orientation)
        
        if let faces = faceFeatures {
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
}


