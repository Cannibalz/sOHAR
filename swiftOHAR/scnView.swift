//
//  scnView.swift
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/6/27.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import SceneKit
import SceneKit.ModelIO

struct marker : Codable
{
    var id: Int
    var Tvec: [Double]
    var Rvec: [Double]
    var Corners : [[Double]]
}

class ARViewController : SCNScene
{
    
    override init() {
        super.init()
        print("ARView Controller Init")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
