//
//  CameraPreviewController+GIF.swift
//  Pods
//
//  Created by DragonCherry on 1/16/17.
//
//

import UIKit
import ImageIO
import MobileCoreServices
import CoreMedia
import TinyLog

public extension CameraPreviewController {
    
    internal func initGIF() {
        guard !isCapturingGIF else {
            loge("Already capturing GIF images. This call is ignored.")
            return
        }
        guard let _ = initGIFDirectory() else {
            loge("Failed to find root directory to create temporary directory for creating GIF.")
            return
        }
        clearGIFDirectory()
        temporaryGIFFile = UUID().uuidString
        temporaryGIFSequence = 0
    }
    
    internal func saveGIFFragment(_ sampleBuffer: CMSampleBuffer) {
        guard isCapturingGIF else {
            return
        }
        serialGIFQueue.sync {
            guard let image = image(from: sampleBuffer) else {
                logw("Failed to create UIImage object from CMSampleBuffer object.")
                return
            }
            guard let jpegData = UIImageJPEGRepresentation(image, GIFSourceQuality) else {
                logw("Failed to create JPEG data from UIImage object.")
                return
            }
            guard let GIFDirectory = initGIFDirectory() else {
                loge("Failed to find root directory to create temporary directory for creating GIF.")
                return
            }
            
            let fragmentPath = "\(GIFDirectory)/\(temporaryGIFFile)_\(temporaryGIFSequence).jpg"
            
            if !FileManager.default.createFile(atPath: fragmentPath, contents: jpegData, attributes: nil) {
                logw("Failed to create JPG fragment file.")
            } else {
                temporaryGIFSequence += 1
            }
        }
    }
    
    internal func createGIF(_ completion: ((URL?) -> Void)?) {
        guard isCapturingGIF else {
            loge("You should call initGIF first before call createGIF.")
            return
        }
        serialGIFQueue.sync {
            
            guard self.temporaryGIFSequence > 0 else {
                loge("JPG fragment count is 0. You need at lease one fragment to create GIF file.")
                completion?(nil)
                return
            }
            
            guard let gifDirectory = self.temporaryGIFDirectory else {
                loge("Failed to get temporary GIF directory.")
                completion?(nil)
                return
            }
            
            // stitch up all fragments into GIF image and clear all temporary files.
            let fileProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFLoopCount as String: 5]]
            let frameProperties = [kCGImagePropertyGIFDictionary as String: [kCGImagePropertyGIFDelayTime as String: 0]]
            
            let url = URL(fileURLWithPath: gifDirectory).appendingPathComponent("animated.gif")
            
            guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypeGIF, Int(temporaryGIFSequence + 1), nil) else {
                loge("Failed to create GIF destination file with URL.")
                return
            }
            CGImageDestinationSetProperties(destination, fileProperties as CFDictionary)
            
            for i in 0..<temporaryGIFSequence {
                let fragmentPath = (gifDirectory as NSString).appendingPathComponent("\(temporaryGIFFile)_\(i).jpg")
                if let image = UIImage(contentsOfFile: fragmentPath), let cgImage = image.cgImage {
                    CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
                    logd("Added \(fragmentPath) into GIF.")
                }
            }
            
            if CGImageDestinationFinalize(destination) {
                completion?(url)
            } else {
                completion?(nil)
            }
        }
    }
    
    private func initGIFDirectory() -> String? {
        
        guard let libraryDirectory = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true).first else {
            loge("Failed locate library directory.")
            return nil
        }
        
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = true
        let gifPath = (libraryDirectory as NSString).appendingPathComponent(temporaryGIFDirectoryName)
        let gifURL = URL(fileURLWithPath: gifPath)
        
        if !fileManager.fileExists(atPath: gifPath, isDirectory: &isDirectory) || !isDirectory.boolValue {
            do {
                try fileManager.createDirectory(at: gifURL, withIntermediateDirectories: true, attributes: nil)
            } catch {
                loge(error)
                return nil
            }
            
            if fileManager.fileExists(atPath: gifPath, isDirectory: &isDirectory) {
                if !isDirectory.boolValue {
                    // May not reach here.
                    loge("Unexpected file status.")
                    return nil
                }
            } else {
                loge("Failed to create directory.")
                return nil
            }
        }
        
        temporaryGIFDirectory = gifPath
        return temporaryGIFDirectory
    }
    
    private func clearGIFDirectory() {
        guard let GIFDirectory = self.initGIFDirectory() else { return }
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = true
        guard fileManager.fileExists(atPath: GIFDirectory, isDirectory: &isDirectory) && isDirectory.boolValue else { return }
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: GIFDirectory)
            for file in files {
                do {
                    try fileManager.removeItem(atPath: "\((GIFDirectory as NSString).appendingPathComponent(file))")
                } catch {
                    loge(error)
                    return
                }
            }
        } catch {
            loge(error)
            return
        }
    }
    
    fileprivate func tempFileList() -> [String] {
        
        var list = [String]()
        let fileManager = FileManager.default
        
        if let path = temporaryGIFDirectory, let objectArray = fileManager.enumerator(atPath: path)?.allObjects {
            for URLObject in objectArray {
                if let path = URLObject as? String {
                    list.append(path)
                } else {
                    logw("Failed to get path from enumeratorAtPath: \(path)")
                }
            }
        }
        return list
    }
}
