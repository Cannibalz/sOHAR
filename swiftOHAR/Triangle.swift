//
//  Triangle.swift
//  metalBasic
//
//  Created by Kaofan on 2017/11/23.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

import Foundation
import Metal

class Triangle: Node {
    
    init(device: MTLDevice){
        
        let V0 = Vertex(x:  0.0, y:   0.3, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
        let V1 = Vertex(x: -0.3, y:  -0.3, z:   0.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0)
        let V2 = Vertex(x:  0.3, y:  -0.3, z:   0.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0)
        
        let verticesArray = [V0,V1,V2]
        super.init(name: "Triangle", vertices: verticesArray, device: device)
    }
    
}
