//
//  ViewController.swift
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/4/17.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

import Cocoa
import Metal
import MetalKit
class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        print("helloWorld")
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    @IBAction func btnPress(_ sender: Any) {
        var rs = objCRealsense.init()
        rs.initRealsense()
    }


}

