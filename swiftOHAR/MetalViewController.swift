//
//  MetalViewController.swift
//  swiftOHAR
//
//  Created by Kaofan on 2017/4/29.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

import Foundation
import Metal
import MetalKit

class MetalViewController : MTKView
{
    var rs : objCRealsense = objCRealsense()
    var nsImg : NSImage? = nil
    var Inited = false
    let frameQueue = DispatchQueue(label: "frameQueue")
    
    func render() {
        let device = MTLCreateSystemDefaultDevice()!
        self.device = device
        let rpd = MTLRenderPassDescriptor()
        let bleen = MTLClearColor(red: 0, green: 0.5, blue: 0.5, alpha: 1)
        let textureLoader = MTKTextureLoader(device: self.device!)
        var imageRect:CGRect = CGRect(x: 0, y: 0, width: (nsImg?.size.width)!, height: (nsImg?.size.height)!)
        var imageRef = nsImg?.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
        self.print(nsImg?.size.width)
        do
        {
            rpd.colorAttachments[0].texture = try textureLoader.newTexture(with: imageRef!, options: nil)
        }
        catch let error as NSError {
            fatalError("Unexpected error ocurred: /(error.localizedDescription).")
        }
        rpd.colorAttachments[0].clearColor = bleen
        rpd.colorAttachments[0].loadAction = .clear
        let commandQueue = device.makeCommandQueue()
        let commandBuffer = commandQueue.makeCommandBuffer()
        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: rpd)
        encoder.endEncoding()
        commandBuffer.present(currentDrawable!)
        commandBuffer.commit()
    }

    override func draw(_ dirtyRect: NSRect) {
        if Inited == false
        {
            initDevice()
            Inited = true
            print("inited")
        }
        frameQueue.async {
            self.renderImg()
        }
        self.framebufferOnly = false
        self.colorPixelFormat = .bgra8Unorm
        super.draw(dirtyRect)
        render()
    }
    func renderImg()
    {
        rs.waitForNextFrame()
        nsImg = rs.nsColorImage()
        print(nsImg)
    }
    func initDevice()
    {
        let queue = DispatchQueue(label: "rs")
        queue.sync {
            
            rs.initRealsense()
        }
        renderImg()
    }
}
