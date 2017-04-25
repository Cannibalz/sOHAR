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
    var commandQueue: MTLCommandQueue?
    var imageTexture: MTLTexture?
    var rs : objCRealsense = objCRealsense()
    var nsImg : NSImage? = nil
    var metalDevice = MTLCreateSystemDefaultDevice()
    //var metalCommandQueue
    
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
            renderImg()
    }
    func renderImg()
    {
        rs.waitForNextFrame()
        nsImg = rs.nsColorImage()
        var imageRect:CGRect = CGRect(x: 0, y: 0, width: (nsImg?.size.width)!, height: (nsImg?.size.height)!)
        var imageRef = nsImg?.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        do{
            imageTexture = try MTKTextureLoader(device: metalDevice!).newTexture(with: imageRef!)
            let inputImage = CIImage(mtlTexture: imageTexture!, options: nil)
        }
        catch
        {
            
        }
        

    }


}

