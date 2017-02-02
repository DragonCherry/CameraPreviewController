//
//  CoreImageUtils.h
//  Pods
//
//  Created by DragonCherry on 1/18/17.
//
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

@interface CoreImageUtils: NSObject

+ (UIImage *)imageFromYUVSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
