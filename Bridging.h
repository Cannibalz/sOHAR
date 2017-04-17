//
//  Bridging.h
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/4/17.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

#ifndef Bridging_h
#define Bridging_h
#import <Cocoa/Cocoa.h>

@interface realSense : NSObject

- (id)init;
+ (NSImage *)colorImg;
+ (NSImage *)depthImg;
+ (NSImage *)C2DImg;
+ (void)waitFOrNextFrame;
+ (void)stop;
@end

#endif /* Bridging_h */
