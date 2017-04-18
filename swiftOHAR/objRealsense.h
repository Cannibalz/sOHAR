//
//  objRealsense.h
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/4/18.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#ifdef __cplus
#import "cRealsense.hpp"

@interface objCRealsense : NSObject
{
    cRealsense rs;
}
-(void)initRealsense;
-(NSImage *)nsColorImage;
-(void)printHelloWorld;
@end
#endif

