//
//  scnView.swift
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/6/27.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

import Foundation
import SceneKit

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
