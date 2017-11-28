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

class ARViewController : SCNView
{
    
    override init(frame: NSRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: nil)
        print("tests")
        self.scene = SCNScene()
        self.scene?.background.contents = NSColor.black
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
}
