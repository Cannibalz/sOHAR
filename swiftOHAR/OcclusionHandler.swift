//
//  OcclusionHandler.swift
//  swiftOHAR
//
//  Created by viplab on 2018/5/18.
//  Copyright © 2018年 Tom Cruise. All rights reserved.
//

import Cocoa
import Metal
import MetalKit
import SceneKit
class OcclusionHandler: NSObject,SCNSceneRendererDelegate {
    var device : MTLDevice!
    var commandQueue : MTLCommandQueue!
    var renderer : SCNRenderer!
    var depthImageBuffer : MTLBuffer!
    var colorTexture : MTLTexture!
    var depthTexture : MTLTexture!
    var replacedTexture : MTLTexture!
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = Int(4)
    let bitsPerComponent = Int(8)
    let viewWidth = Int(640)
    let viewheight = Int(480)
    var depthValueArray = Array<Float>()
    var scnView:SCNView!
    var plane : SCNPlane!
    override init()
    {
        super.init()
    }
    convenience init(scnView:SCNView) {
        self.init()
        self.scnView = scnView
        setupMetal()
        setupRenderer()
        plane = SCNPlane(width: 1, height: 1)
        self.scnView.scene?.rootNode.addChildNode(SCNNode(geometry: plane))
    }
    func getFrame()
    {
        let viewPort : CGRect = CGRect(x: 0, y: 0, width: viewWidth, height: viewheight)
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = colorTexture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        renderPassDescriptor.depthAttachment.texture = depthTexture
        renderPassDescriptor.depthAttachment.loadAction = .clear
        renderPassDescriptor.depthAttachment.storeAction = .store
        renderPassDescriptor.depthAttachment.clearDepth = 1.0
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        renderer.scene = scnView.scene
        renderer.pointOfView = scnView.pointOfView
        renderer!.render(atTime: 0, viewport: viewPort, commandBuffer: commandBuffer, passDescriptor: renderPassDescriptor)
        
        let blitCommandEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        blitCommandEncoder.copy(from: renderPassDescriptor.depthAttachment.texture!, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(viewWidth, viewheight, 1), to: depthImageBuffer, destinationOffset: 0, destinationBytesPerRow: 4*viewWidth, destinationBytesPerImage: 4*viewWidth*viewheight)
        blitCommandEncoder.endEncoding()
        
        commandBuffer.addCompletedHandler({(buffer) -> Void in
            let rawPointer: UnsafeMutableRawPointer = UnsafeMutableRawPointer(mutating: self.depthImageBuffer.contents())
            let typedPointer: UnsafeMutablePointer<Float> = rawPointer.assumingMemoryBound(to: Float.self)
            //self.currentMap = Array(UnsafeBufferPointer(start: typedPointer, count: Int(241)*Int(240)))
            self.depthValueArray = Array(UnsafeBufferPointer(start: typedPointer, count: self.viewWidth*self.viewheight))
        })
        for var i in 0..<depthValueArray.count
        {
            if depthValueArray[i] != 1.0
            {
                print("in x:\(Int(i%viewWidth)) y:\(Int(i/viewWidth)) : \(depthValueArray[i])")
            }
        }
        commandBuffer.commit()
        replaceTexture(texture: colorTexture, needsWidth: 50, needsHeight: 50, startX: 50, startY: 50)
    }
    func setupMetal() {
        if self.scnView.renderingAPI == SCNRenderingAPI.metal {
            device = MTLCreateSystemDefaultDevice()
            commandQueue = device.makeCommandQueue()
            renderer = SCNRenderer(device: device, options: nil)
            print("setup done")
        } else {
            fatalError("Sorry, Metal only")
        }
    }
    func setupRenderer()
    {
        let colorDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: viewWidth, height: viewheight, mipmapped: false)
        colorDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        let colorTexture = device.makeTexture(descriptor: colorDescriptor)
        self.colorTexture = colorTexture
        self.colorTexture.label = "colorTexturee"
        
        let depthDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float , width: viewWidth, height: viewheight, mipmapped: false)
        depthDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        depthDescriptor.resourceOptions = .storageModePrivate
        let depthTexture = device.makeTexture(descriptor: depthDescriptor)
        self.depthTexture = depthTexture
        self.depthTexture.label = "depthTexturee"
        
        self.depthImageBuffer = device.makeBuffer(length: viewWidth*viewheight*4, options: .storageModeShared)
        self.depthImageBuffer.label = "Depth Buffer 2"
    }
    func pixelValues(fromCGImage imageRef: CGImage?) -> (pixelValues: [UInt8]?, width: Int, height: Int)
    {
        var width = 0
        var height = 0
        var pixelValues: [UInt8]?
        if let imageRef = imageRef {
            width = imageRef.width
            height = imageRef.height
            let bitsPerComponent = imageRef.bitsPerComponent
            let bytesPerRow = imageRef.bytesPerRow
            let totalBytes = height * bytesPerRow
            
            let colorSpace = CGColorSpaceCreateDeviceGray()
            var intensities = [UInt8](repeating: 0, count: totalBytes)
            
            let contextRef = CGContext(data: &intensities, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: 0)
            contextRef?.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(width), height: CGFloat(height)))
            
            pixelValues = intensities
        }
        
        return (pixelValues, width, height)
    }
    func replaceTexture(texture:MTLTexture,needsWidth:Int,needsHeight:Int,startX:Int,startY:Int)->MTLTexture
    {
        texture.label = "inputTexture"
        print(texture.pixelFormat.rawValue)
        var rawData = [UInt8](repeating: 0, count: 4*needsWidth*needsHeight)
        let bitmapInfo=CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        let context = CGContext(data:&rawData,width:needsWidth,height:needsHeight,bitsPerComponent:Int(8),bytesPerRow:4*needsWidth,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:bitmapInfo)!
        context.setFillColor(NSColor.brown.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: needsWidth, height: needsHeight))
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm , width: viewWidth, height: viewheight, mipmapped: false)
        textureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        let textureA = device.makeTexture(descriptor: textureDescriptor)
        
        let region = MTLRegionMake2D(startX, startY, needsWidth, needsHeight)
        texture.replace(region: region, mipmapLevel: 0, withBytes: &rawData, bytesPerRow: 4*needsWidth)
        let replacedTexture = texture
        replacedTexture.label = "rep"
        plane.firstMaterial?.diffuse.contents = replacedTexture //getTexNow
        
        return replacedTexture
    }
}

extension MTLTexture {
    
    func bytes() -> UnsafeMutableRawPointer {
        let width = self.width
        let height   = self.height
        let rowBytes = self.width * 4
        let p:UnsafeMutableRawPointer = malloc(width * height * 4)
        
        self.getBytes(p, bytesPerRow: rowBytes, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        
        return p
    }
    
    func toImage() -> CGImage? {
        let p = bytes()
        
        let pColorSpace = CGColorSpaceCreateDeviceRGB()
        
        let rawBitmapInfo = CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let bitmapInfo:CGBitmapInfo = CGBitmapInfo(rawValue: rawBitmapInfo)
        
        let selftureSize = self.width * self.height * 4
        let rowBytes = self.width * 4
        //let provider = CGDataProviderCreateWithData(nil, p, selftureSize, nil)
        let releaseMaskImagePixelData: CGDataProviderReleaseDataCallback = { (info: UnsafeMutableRawPointer?, data: UnsafeRawPointer, size: Int) -> () in
            // https://developer.apple.com/reference/coregraphics/cgdataproviderreleasedatacallback
            // N.B. 'CGDataProviderRelease' is unavailable: Core Foundation objects are automatically memory managed
            return
        }
        let provider = CGDataProvider.init(dataInfo: nil, data: p, size: selftureSize, releaseData: releaseMaskImagePixelData)
        let cgImageRef = CGImage(width: self.width, height: self.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: rowBytes, space: pColorSpace, bitmapInfo: bitmapInfo, provider: provider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)!
        
        return cgImageRef
    }
}
