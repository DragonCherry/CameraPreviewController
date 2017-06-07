//
//  CameraPreviewController+Filter.swift
//  Pods
//
//  Created by DragonCherry on 6/7/17.
//
//

import UIKit
import GPUImage

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
        lastFilter.removeAllTargets()
        lastFilter.addTarget(filter)
        filter.addTarget(preview)
        if let videoWriter = self.videoWriter {
            filter.addTarget(videoWriter)
        }
        filters.append(filter)
    }
    
    open func add(newFilters: [GPUImageFilter]?) {
        guard let newFilters = newFilters, let firstNewFilter = newFilters.first, newFilters.count > 0 else { return }
        lastFilter.removeAllTargets()
        lastFilter.addTarget(firstNewFilter)
        filters.append(contentsOf: filters)
        if let videoWriter = self.videoWriter {
            filters.last?.addTarget(videoWriter)
        }
        filters.last?.addTarget(preview)
    }
    
    open func removeFilters() {
        defaultFilter.removeAllTargets()
        for filter in filters {
            filter.removeAllTargets()
            filter.removeFramebuffer()
        }
        filters.removeAll()
        if let videoWriter = self.videoWriter {
            defaultFilter.addTarget(videoWriter)
        }
        defaultFilter.addTarget(preview)
    }
}
