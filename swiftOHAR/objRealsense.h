//
//  objRealsense.h
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/4/18.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
@interface objCRealsense : NSObject
-(void)initRealsense;
-(void)stop;
-(NSString *)getPoseInformation;
-(NSImage *)nsColorImage;
-(NSImage *)nsDepthImage;
-(NSImage *)nsDetectedColorImage;
-(NSImage *)nsC2DImage;
-(NSImage *)nsD2CImage;
-(void)printHelloWorld;
-(void)waitForNextFrame;

@end


