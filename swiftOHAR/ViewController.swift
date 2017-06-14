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
    @IBOutlet weak var colorView: NSImageView!
    @IBOutlet weak var arView: MTKView!
    var rs : objCRealsense = objCRealsense()
    var nsImg : NSImage? = nil
    override func viewDidLoad() {
        super.viewDidLoad()
        let queue = DispatchQueue(label: "rs")
        queue.sync {
            rs.initRealsense()
        }
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    override func viewDidDisappear() {
        super.viewDidDisappear()
        rs.stop()
        print("viewDidDisappear")
    }
    @IBAction func getImg(_ sender: Any) {
        while true==true
        {
            delay(1)
            {
                self.renderImg()
            }
        }
    }
    func renderImg()
    {
        rs.waitForNextFrame()
        colorView.image = rs.nsColorImage()
        print(nsImg)
    }
    

    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
}

