//
//  objcRealsense.m
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/4/18.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "objRealsense.h"
#import "cRealsense.hpp"
//#import "cImageProcess.hpp"
@interface NSImage (NSImage_openCV)
+(NSImage*)imageWithCVMat:(const cv::Mat&)cvMat;
-(id)initWithCVMat:(const cv::Mat&)cvMat;
@end
@implementation NSImage (NSImage_openCV)
-(CGImageRef)CGImage
{
    CGContextRef bitmapCtx = CGBitmapContextCreate(NULL/*data - pass NULL to let CG allocate the memory*/,
                                                   [self size].width,
                                                   [self size].height,
                                                   8 /*bitsPerComponent*/,
                                                   0 /*bytesPerRow - CG will calculate it for you if it's allocating the data.  This might get padded out a bit for better alignment*/,
                                                   [[NSColorSpace genericRGBColorSpace] CGColorSpace],
                                                   kCGBitmapByteOrder32Host|kCGImageAlphaPremultipliedFirst);
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:[NSGraphicsContext graphicsContextWithGraphicsPort:bitmapCtx flipped:NO]];
    [self drawInRect:NSMakeRect(0,0, [self size].width, [self size].height) fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
    [NSGraphicsContext restoreGraphicsState];
    
    CGImageRef cgImage = CGBitmapContextCreateImage(bitmapCtx);
    CGContextRelease(bitmapCtx);
    
    return cgImage;
}
+ (NSImage *)imageWithCVMat:(const cv::Mat&)cvMat
{
    return [[NSImage alloc] initWithCVMat:cvMat];
}
- (id)initWithCVMat:(const cv::Mat&)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    int BPC = 8;
    int BPP = 0;
    if (cvMat.elemSize() == 1 || cvMat.elemSize() == 4)
    {
        colorSpace = CGColorSpaceCreateDeviceGray();
        BPP = 8;
    }
    else
    {
        colorSpace = CGColorSpaceCreateDeviceRGB();
        BPP = 24;
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
                                        cvMat.rows,                                     // Height
                                        BPC,                                              // Bits per component
                                        /*BPC * cvMat.elemSize()*/BPP,                           // Bits per pixel
                                        cvMat.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
    NSImage *image = [[NSImage alloc] init];
    [image addRepresentation:bitmapRep];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}
@end


@implementation objCRealsense
{
    cRealsense crs;
    //cImageProcess cIP;
}
- (void)initRealsense
{
    crs.init();
}
- (void)stop
{
    crs.stop();
}
- (void)waitForNextFrame
{
    crs.waitForNextFrame();
}
- (NSString *)getPoseInformation
{
    NSString *jsonInformation = [NSString stringWithCString:crs.getPoseInformation().c_str()
                                                   encoding:[NSString defaultCStringEncoding]];
    
    //vector<cv::Vec3d> Tvecs = crs.Tvecs();
    //NSArray *myArray = [NSArray arrayWithObjects:&Tvecs[0] count:Tvecs.size()];
    return jsonInformation;
}
- (NSImage *)nsColorImage
{
    return [[NSImage alloc]initWithCVMat:crs.colorImage()];
}
- (NSImage *)nsDepthImage
{
    NSLog(@"ColorSize: %d",crs.colorImage().elemSize());
    NSLog(@"DepthSize: %d",crs.depthImage().elemSize());
    return [[NSImage alloc]initWithCVMat:crs.depthImage()];
}
- (NSImage *)nsC2DImage
{
    return [[NSImage alloc]initWithCVMat:crs.C2DImage()];
}
- (NSImage *)nsDetectedColorImage
{
    return [[NSImage alloc]initWithCVMat:crs.detectedImage()];
}
@end
