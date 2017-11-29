//
//  depthMask.swift
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/11/29.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

import Foundation

class DepthMask2D
{
    var valueArray : [[CGFloat]] = Array(repeating: Array(repeating: 0, count: 480), count: 640)
    //var valueArray : [[NSColor]] = Array(repeating: Array(repeating: 0, count: 480), count: 640)
    init() {
        print(valueArray[0].count)
    }
    func setDepthValue(data:[[Int]])
    {
        
    }
    func setDepthValue(bitmapImageRep:NSBitmapImageRep)
    {
        for var x in stride(from: 0, to: valueArray.count, by: 2)
        {
            for var y in stride(from: 0, to: valueArray[x].count, by: 2)
            {
               valueArray[x][y] = bitmapImageRep.colorAt(x: x, y: y)!.whiteComponent
            
            }
        }
        //print(valueArray)
    }
}
