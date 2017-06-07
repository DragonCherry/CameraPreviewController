//
//  CameraPreviewController+Video.swift
//  Pods
//
//  Created by DragonCherry on 6/7/17.
//
//

import UIKit
import TinyLog
import GPUImage

extension CameraPreviewController {
    
    open func startRecordingVideo(completion: (() -> Void)? = nil) {
        
        if !isRecordingVideo {
            
            guard let formatDescription = camera.inputCamera.activeFormat.formatDescription else { return }
            
            findOrientation(completion: { (orientation) in
                
                let dimensions = CMVideoFormatDescriptionGetDimensions(formatDescription)
                let path = (NSTemporaryDirectory() as NSString).appendingPathComponent("\(UUID().uuidString).m4v")
                let url = URL(fileURLWithPath: path)
                let videoWidth = CGFloat(min(dimensions.width, dimensions.height))
                let videoHeight = CGFloat(max(dimensions.width, dimensions.height))
                
                if let writer = GPUImageMovieWriter(movieURL: url, size: CGSize(width: videoWidth, height: videoHeight)) {
                    self.lastFilter.addTarget(writer)
                    self.videoWriter = writer
                    self.videoUrl = url
                    writer.delegate = self
                    
                    let radian: ((CGFloat) -> CGFloat) = { degree in
                        return CGFloat(Double.pi) * degree / CGFloat(180)
                    }
                    
                    var transform: CGAffineTransform?
                    switch orientation {
                    case .landscapeLeft:
                        transform = CGAffineTransform(rotationAngle: radian(90))
                    case .landscapeRight:
                        transform = CGAffineTransform(rotationAngle: radian(-90))
                    case .portraitUpsideDown:
                        transform = CGAffineTransform(rotationAngle: radian(180))
                    default:
                        break
                    }
                    
                    if self.cameraPosition == .front, orientation.isLandscape {
                        transform = transform?.scaledBy(x: -1, y: 1)
                    }
                    
                    DispatchQueue.main.async {
                        if let transform = transform {
                            writer.startRecording(inOrientation: transform)
                        } else {
                            writer.startRecording()
                        }
                        logi("Recording video with size: \(videoWidth)x\(videoHeight)")
                        completion?()
                    }
                }
            })
        }
    }
    
    open func finishRecordingVideo(completion: (() -> Void)? = nil) {
        if isRecordingVideo {
            if let writer = self.videoWriter {
                DispatchQueue.main.async {
                    if let completion = completion {
                        writer.finishRecording(completionHandler: completion)
                    } else {
                        writer.finishRecording()
                    }
                    self.lastFilter.removeTarget(writer)
                }
            } else {
                logc("Invalid status error.")
            }
        }
    }
    
    func clearRecordingVideo() {
        videoWriter = nil
        videoUrl = nil
    }
}

// MARK: - GPUImageMovieWriterDelegate
extension CameraPreviewController: GPUImageMovieWriterDelegate {
    
    public func movieRecordingCompleted() {
        if let videoUrl = self.videoUrl, isRecordingVideo {
            clearRecordingVideo()
            DispatchQueue.main.async {
                self.delegate?.cameraPreview(self, didSaveVideoAt: videoUrl)
            }
        }
    }
    
    public func movieRecordingFailedWithError(_ error: Error!) {
        logi("\(error?.localizedDescription ?? "")")
        if isRecordingVideo {
            clearRecordingVideo()
            DispatchQueue.main.async {
                self.delegate?.cameraPreview(self, didFailSaveVideoWithError: error)
            }
        }
    }
}
