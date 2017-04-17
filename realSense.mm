//
//  realSense.m
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/4/17.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

#import <vector>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>
#import <librealsense/rs.hpp>
#include <stdio.h>
#include <cstdio>

#import <Foundation/Foundation.h>
#import "Bridging.h"

@implementation realSense
rs::context ctx;
rs::device *dev;
- (id)init
{
    printf("There are %d connected RealSense devices.\n", ctx.get_device_count());
    if(ctx.get_device_count() == 0)
    {
        printf("no device connected");
    }
    
    // This tutorial will access only a single device, but it is trivial to extend to multiple devices
    dev = ctx.get_device(0); //裝置
    dev->enable_stream(rs::stream::depth, rs::preset::best_quality);
    dev->enable_stream(rs::stream::color, rs::preset::best_quality);
    printf("\nUsing device 0, an %s\n", dev->get_name());
    printf("Serial number: %s\n", dev->get_serial());
    printf("Firmware version: %s\n", dev->get_firmware_version());
    // Configure all streams to run at VGA resolution at 60 frames per second
    dev->enable_stream(rs::stream::depth, 640, 480, rs::format::z16, 30);
    dev->enable_stream(rs::stream::color, 640, 480, rs::format::bgr8, 30);
    dev->enable_stream(rs::stream::infrared, 640, 480, rs::format::y8, 30);
    try { dev->enable_stream(rs::stream::infrared2, 640, 480, rs::format::y8, 30); }
    catch(...) { printf("Device does not provide infrared2 stream.\n"); }
    dev->start(); //start streaming
    return nil;
}


@end
