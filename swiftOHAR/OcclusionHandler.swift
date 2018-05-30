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
import Accelerate
import CoreGraphics
class OcclusionHandler: NSObject,SCNSceneRendererDelegate {
    var device : MTLDevice!
    var commandQueue : MTLCommandQueue!
    var renderer : SCNRenderer!
    var depthImageBuffer : MTLBuffer!
    var colorImageBuffer : MTLBuffer!
    var colorTexture : MTLTexture!
    var depthTexture : MTLTexture!
    var replacedTexture : MTLTexture!
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    let bytesPerPixel = Int(4)
    let bitsPerComponent = Int(8)
    let viewWidth = Int(640)
    let viewheight = Int(480)
    var depthValueArray = Array<Float>()
    var augmentedView:SCNView!
    var plane : SCNPlane!
    var mergeView:SCNView!
    var augmentedScene:SCNScene!
    var mergeScene:SCNScene!
    var rawColorData = Array<UInt8>()
    override init()
    {
        super.init()
    }
    convenience init(scnView:SCNView) {
        self.init()
        self.augmentedView = scnView
        setupMetal()
        setupRenderer()
        //self.scnView.scene?.rootNode.addChildNode(SCNNode(geometry: plane))
    }
    convenience init(augmentedView:SCNView,mergeScene:SCNScene) {
        self.init()
        self.augmentedView = augmentedView
        self.augmentedScene = augmentedView.scene
        self.mergeScene = mergeScene
        setupMetal()
        setupRenderer()
        buildBackgroundPlane()
        //self.mergeView.scene?.rootNode.addChildNode(backgroundNode)
    }
    func buildBackgroundPlane()
    {
        plane = SCNPlane(width: 6, height: 4.5)
        let bgNode = SCNNode(geometry: plane)
        bgNode.position = SCNVector3Make(0, 0, -4)
        mergeScene.rootNode.addChildNode(bgNode)
    }
    func findComparingNeededArea(rawDepthImage:NSBitmapImageRep,rawColorImage:CGImage)
    {
        var measureRangeArray = Array<applyDepthWindow>()
        for node in (augmentedScene?.rootNode.childNode(withName: "markerObjectNode", recursively: true)?.childNodes)!
        {
            let nodeBoundingSize = calNodeSize(node: node, view: augmentedView)
            measureRangeArray.append(applyDepthWindow(minX: nodeBoundingSize.minX, minY: nodeBoundingSize.minY, maxX: nodeBoundingSize.maxX, maxY: nodeBoundingSize.maxY, needsConvert: true))
        }
        if measureRangeArray.count > 0
        {
            CalculateExecuteTime(title: "replaceTexture", call: {
                replaceTexture(texture: colorTexture, areas: measureRangeArray,rawDepthImage:rawDepthImage,rawColorImage:rawColorImage)
            })
        }
    }
    func getFrame() //copy buffer
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
        renderer.scene = augmentedScene
        //renderer.pointOfView = scnView.pointOfView
        renderer!.render(atTime: 0, viewport: viewPort, commandBuffer: commandBuffer, passDescriptor: renderPassDescriptor)
        
        let blitCommandEncoder: MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
        blitCommandEncoder.copy(from: renderPassDescriptor.depthAttachment.texture!, sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(viewWidth, viewheight, 1), to: depthImageBuffer, destinationOffset: 0, destinationBytesPerRow: 4*viewWidth, destinationBytesPerImage: 4*viewWidth*viewheight)
        blitCommandEncoder.endEncoding()
        
        commandBuffer.addCompletedHandler({(buffer) -> Void in
            
            let rawPointer: UnsafeMutableRawPointer = UnsafeMutableRawPointer(mutating: self.depthImageBuffer.contents())
            let typedPointer: UnsafeMutablePointer<Float> = rawPointer.assumingMemoryBound(to: Float.self)
            self.depthValueArray = Array(UnsafeBufferPointer(start: typedPointer, count: self.viewWidth*self.viewheight))
            
        })
        commandBuffer.commit()
    }
    func setupMetal() {
        //if self.scnView.renderingAPI == SCNRenderingAPI.metal {
        if true{
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
        let colorDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm_srgb , width: viewWidth, height: viewheight, mipmapped: false)
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
    func pixelValues(fromCGImage imageRef: CGImage?) -> Array<UInt8>//(pixelValues: [UInt8]?, width: Int, height: Int)
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
        print(pixelValues![1442])
        return pixelValues!
    }
    func replaceTexture(texture:MTLTexture,needsWidth:Int,needsHeight:Int,startX:Int,startY:Int)->MTLTexture
    {
        texture.label = "inputTexture"
        //print(texture.pixelFormat.rawValue)
        var rawData = [UInt8](repeating: 0, count: 4*needsWidth*needsHeight)
        let bitmapInfo=CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        let context = CGContext(data:&rawData,width:needsWidth,height:needsHeight,bitsPerComponent:Int(8),bytesPerRow:4*needsWidth,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:bitmapInfo)!
        context.setFillColor(NSColor.brown.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: needsWidth, height: needsHeight))
        //print(rawData)
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm , width: viewWidth, height: viewheight, mipmapped: false)
        textureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.renderTarget.rawValue | MTLTextureUsage.shaderRead.rawValue)
        //let textureA = device.makeTexture(descriptor: textureDescriptor)
        
        let region = MTLRegionMake2D(startX, startY, needsWidth, needsHeight)
        texture.replace(region: region, mipmapLevel: 0, withBytes: &rawData, bytesPerRow: 4*needsWidth)
        self.replacedTexture = texture
        self.replacedTexture.label = "rep"
        plane.firstMaterial?.diffuse.contents = replacedTexture //getTexNow
        //self.mergeView.scene?.background.contents = replacedTexture.toImage()
        return replacedTexture
    }
    func replaceTexture(texture:MTLTexture,areas:Array<applyDepthWindow>,rawDepthImage:NSBitmapImageRep,rawColorImage:CGImage)->MTLTexture
    {
        //rawColorData = pixelValues(fromCGImage: rawColorImage)
        let CGAugmentedImage = texture.toImage()
        let nsi = NSImage(cgImage: rawColorImage, size: NSSize(width: 640, height: 480))
        
        let rawColorRef = NSBitmapImageRep(cgImage: rawColorImage)
        let augColorRef = NSBitmapImageRep(cgImage: (CGAugmentedImage)!)
        for area in areas
        {
            let needsWidth:Int = area.maxX-area.minX
            let needsHeight:Int = area.maxY-area.minY
            var rawData = [UInt8](repeating: 255, count: 4*needsWidth*needsHeight)
            let bitmapInfo=CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
            let context = CGContext(data:&rawData,width:needsWidth,height:needsHeight,bitsPerComponent:Int(8),bytesPerRow:4*needsWidth,space:CGColorSpaceCreateDeviceRGB(),bitmapInfo:bitmapInfo)!
            var data = UnsafeMutableRawPointer.allocate(bytes: 4*needsWidth*needsHeight, alignedTo: 4)
            defer{
                data.deallocate(bytes: 4*needsWidth*needsHeight, alignedTo: 4)
            }
            let region = MTLRegionMake2D(area.minX, area.getY(Y: area.maxY), needsWidth, needsHeight)
            texture.getBytes(data, bytesPerRow: 4*needsWidth, from: region, mipmapLevel: 0)
            for var i in area.minX..<area.maxX
            {
                for var j in area.getY(Y: area.maxY)..<area.getY(Y: area.minY)
                {
//                    let offset = j*viewWidth+i
//                    let yReverse = area.getY(Y: area.maxY)
//                    let offsetForRawData = ((j-yReverse)*needsWidth+(i-area.minX))*4
//                    //print("offset:\(offsetForRawData)")
//                    if rawDepthImage.colorAt(x:i,y:j)?.whiteComponent == 0
//                    {
//                        rawData[offsetForRawData] = UInt8((augColorRef.colorAt(x: i, y: j)?.redComponent)!*255)
//                        rawData[offsetForRawData+1] = UInt8((augColorRef.colorAt(x: i, y: j)?.greenComponent)!*255)
//                        rawData[offsetForRawData+2] = UInt8((augColorRef.colorAt(x: i, y: j)?.blueComponent)!*255)
//                        rawData[offsetForRawData+3] = 255
//                    }
//                    else if depthValueArray[offset] != 1.0 && depthValueArray[offset] < Float(rawDepthImage.colorAt(x:i,y:j)!.whiteComponent+45/255)//rawdata & buffer的深度都有值
//                    {
//                            //print("\(rawData[offsetForRawData]),\(rawData[offsetForRawData+1]),\(rawData[offsetForRawData+2]),\(rawData[offsetForRawData+3])")
//
//                            rawData[offsetForRawData] = UInt8((augColorRef.colorAt(x: i, y: j)?.redComponent)!*255)
//                            rawData[offsetForRawData+1] = UInt8((augColorRef.colorAt(x: i, y: j)?.greenComponent)!*255)
//                            rawData[offsetForRawData+2] = UInt8((augColorRef.colorAt(x: i, y: j)?.blueComponent)!*255)
//                            rawData[offsetForRawData+3] = 255
//                            //print("\(rawData[offsetForRawData]),\(rawData[offsetForRawData+1]),\(rawData[offsetForRawData+2]),\(rawData[offsetForRawData+3])\n--------------")
//
//                    }
//                    else
//                    {
//                        rawData[offsetForRawData] = UInt8((rawColorRef.colorAt(x: i, y: j)?.redComponent)!*255)
//                        rawData[offsetForRawData+1] = UInt8((rawColorRef.colorAt(x: i, y: j)?.greenComponent)!*255)
//                        rawData[offsetForRawData+2] = UInt8((rawColorRef.colorAt(x: i, y: j)?.blueComponent)!*255)
//                        rawData[offsetForRawData+3] = UInt8(255)
//                    }
                }
            }
            texture.replace(region: region, mipmapLevel: 0, withBytes: &rawData, bytesPerRow: 4*needsWidth)
        }
        self.replacedTexture = texture
        self.replacedTexture.label = "rep"
        plane.firstMaterial?.diffuse.contents = replacedTexture //getTexNow
        return texture
    }
    func calNodeSize(node:SCNNode,view:SCNView) -> nodePos
    {
        let (localMin,localMax) = node.boundingBox
        let min = node.convertPosition(localMin, to: nil)
        let max = node.convertPosition(localMax, to: nil)
        let midZ = (min.z + max.z) / 2
        let vertices = [
            SCNVector3(min.x, min.y, min.z), //4min 4max
            SCNVector3(max.x, min.y, min.z),
            SCNVector3(min.x, max.y, min.z),
            SCNVector3(max.x, max.y, min.z),
            SCNVector3(min.x, min.y, max.z),
            SCNVector3(max.x, min.y, max.z),
            SCNVector3(min.x, max.y, max.z),
            SCNVector3(max.x, max.y, max.z)
        ]
        let arr = vertices.map { view.projectPoint($0) }
        
        var minX: CGFloat = arr.reduce(CGFloat.infinity, { $0 > $1.x ? $1.x : $0 })
        var minY: CGFloat = arr.reduce(CGFloat.infinity, { $0 > $1.y ? $1.y : $0 })
        //let minZ: CGFloat = arr.reduce(CGFloat.infinity, { $0 > $1.z ? $1.z : $0 })
        var maxX: CGFloat = arr.reduce(-CGFloat.infinity, { $0 < $1.x ? $1.x : $0 })
        var maxY: CGFloat = arr.reduce(-CGFloat.infinity, { $0 < $1.y ? $1.y : $0 })
        //let maxZ: CGFloat = arr.reduce(-CGFloat.infinity, { $0 < $1.z ? $1.z : $0 })
        
        let width = maxX - minX
        let height = maxY - minY
        let meanX = (maxX+minX)/2
        let meanY = (maxY+minY)/2
        let length = ([width,height].max())!/2
        minX = meanX-length
        maxX = meanX+length
        minY = meanY-length
        maxY = meanY+length
        if minX < 0
        {
            minX = 0
        }
        if minY < 0
        {
            minY = 0
        }
        if maxX > 640
        {
            maxX = 640
        }
        if maxY > 480
        {
            maxY = 480
        }
        return nodePos(minX : Int(minX), minY : Int(minY), maxX: Int(maxX), maxY: Int(maxY))
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
        let ciInput = CIImage(cgImage: cgImageRef)
        let ctx = CIContext(options:nil)
        let swapKernel = CIColorKernel( string:
            "kernel vec4 swapRedAndGreenAmount(__sample s) {" +
                "return s.bgra;" +
            "}"
        )
        let ciOutput = swapKernel?.apply(withExtent: (ciInput.extent), arguments: [ciInput as Any])
        let cgConverted = ctx.createCGImage(ciOutput!, from: ciInput.extent)
        return cgConverted
    }
}
extension CGImage{
    func sRGB()->CGImage
    {
        var error = kvImageNoError
        var srcBuffer = vImage_Buffer()
        var destBuffer = vImage_Buffer()
        print(self.colorSpace!)
        var srcFormat = vImage_CGImageFormat(bitsPerComponent: UInt32(self.bitsPerComponent), bitsPerPixel: UInt32(self.bitsPerPixel), colorSpace:Unmanaged.passUnretained(self.colorSpace!), bitmapInfo: self.bitmapInfo, version: 0, decode: nil, renderingIntent: .defaultIntent)
        var dstFormat = vImage_CGImageFormat(bitsPerComponent: UInt32(self.bitsPerComponent), bitsPerPixel: UInt32(self.bitsPerPixel), colorSpace:Unmanaged.passUnretained(CGColorSpace(name: CGColorSpace.sRGB)!), bitmapInfo: self.bitmapInfo, version: 0, decode: nil, renderingIntent: .defaultIntent)
        let convertRef = vImageConverter_CreateWithCGImageFormat(&srcFormat, &dstFormat, nil, vImage_Flags(kvImageNoFlags), &error)
        let Converter = convertRef?.takeRetainedValue()
        vImageBuffer_Init(&destBuffer, vImagePixelCount(self.height), vImagePixelCount(self.width), UInt32(self.bitsPerPixel), vImage_Flags(kvImageNoFlags))
        vImageConvert_AnyToAny(Converter!, &srcBuffer, &destBuffer, nil, vImage_Flags(kvImagePrintDiagnosticsToConsole))
        let dstImage = vImageCreateCGImageFromBuffer(&destBuffer, &dstFormat, nil, nil, vImage_Flags(kvImageNoFlags), &error)
        free(srcBuffer.data)
        free(destBuffer.data)
        return (dstImage?.takeRetainedValue())!
        
    }
}
