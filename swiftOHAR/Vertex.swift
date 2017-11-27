//
//  Vertex.swift
//  metalBasic
//
//  Created by Tom Cruise on 2017/11/22.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

import Foundation

struct Vertex{
    
    var x,y,z: Float     // position data
    var r,g,b,a: Float   // color data
    
    func floatBuffer() -> [Float] {
        return [x,y,z,r,g,b,a]
    }
    
}
