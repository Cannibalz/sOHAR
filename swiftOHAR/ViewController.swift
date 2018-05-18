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
import SceneKit
import SceneKit.ModelIO

class ViewController: NSViewController {
    @IBOutlet weak var silderTvec0: NSSlider!
    @IBOutlet weak var silderTvec1: NSSlider!
    
    @IBOutlet weak var silderTvec2: NSSlider!
    @IBOutlet weak var btnChangeSetting: NSButton!
    @IBOutlet weak var colorView: NSImageView!
    @IBOutlet weak var depthView: NSImageView!
    @IBOutlet weak var C2DView: NSImageView!
    
    @IBOutlet weak var arView: MTKView!
    @IBOutlet weak var scnARView: SCNView!
    @IBOutlet weak var tvec0: NSTextField!
    @IBOutlet weak var tvec1: NSTextField!
    @IBOutlet weak var tvec2: NSTextField!
    private var nodeArray : [SCNNode] = []
    
    var previousXY : [CGFloat] = [0,0]
    var previousZ : CGFloat = 0
    @IBOutlet weak var cbMarkerDetection: NSButton!
    
    var doDepthMap : Bool = true
    
    let maxX : Float = 0.769800186158227
    let maxY : Float = 0.57735019922565
    @IBOutlet weak var cbMaskColor: NSButton!
    @IBOutlet weak var cbUsingMask: NSButton!
    let tempX : Float = 480
    let tempY : Float = 360
    var timer : Timer = Timer()
    var rs : objCRealsense = objCRealsense()
    var nsImg : NSImage? = nil
    var scnRenderer: SCNRenderer!
    var time = TimeInterval(0.0)
    let timestep = 1.0 / 30
    var markers : [Marker] = []
    var MS = markerSystem()
    var DM = DepthMask2D()
    var occlusionHandler = OcclusionHandler()
    var planePositionIn2D = SCNVector3(480,360,0.4)
    var countt = 0
    
    var ssCount = 12;
    
    let device = MTLCreateSystemDefaultDevice()
    var commandQueue: MTLCommandQueue!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rs.initRealsense()
        DM = DepthMask2D(scnView: self.scnARView, downSample: 2, aroundMarkerOnly: true)
        MS = markerSystem(scnView: scnARView)
        occlusionHandler = OcclusionHandler(scnView: self.scnARView)
        //scnARView.scene?.rootNode.addChildNode(DM)
        scnARView.scene?.rootNode.addChildNode(MS)
        scnARView.antialiasingMode = .multisampling4X
        scnARView.delegate = self
        scnARView.isPlaying = true
        scnARView.preferredFramesPerSecond = 60
        if let metalLayer = scnARView.layer as? CAMetalLayer
        {
            metalLayer.framebufferOnly = false
        }
        //commandQueue = device?.makeCommandQueue()
        
    }
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    override func viewDidDisappear() {
        super.viewDidDisappear()
        timer.invalidate()
        rs.stop()
        scnARView.isPlaying = false
        print("viewDidDisappear")
        exit(0)
    }
    @IBAction func fdsfdsfsd(_ sender: Any) {
        let screenshot = scnARView.snapshot()
        let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileName = "ss\(ssCount).png"
        let folderUrl = documentURL?.appendingPathComponent("ssImage")
        let url = folderUrl?.appendingPathComponent(fileName)
        screenshot.pngWrite(to: url!)
        ssCount += 1
    }
    func renderImg()
    {
        doDepthMap = !doDepthMap
        rs.waitForNextFrame()
        if doDepthMap && countt < 10 && DM.enable == true
        {
            //countt += 1
            var imageData = rs.nsD2CImage().tiffRepresentation
            var bitmapRep = NSBitmapImageRep.init(data: imageData!) //深度
            CalculateExecuteTime(title: "Set Depth Value", call: {
                DM.setDepthValue(bitmapImageRep: bitmapRep!, view: scnARView,idDictionary: MS.idDictionary)
            })
            DM.refresh()
            
        }
        rs.nsDetectedColorImage()
//        if cbMarkerDetection.state == NSOnState
//        {
//            MS.scnScene.background.contents = rs.nsDetectedColorImage()
//        }
//        else
//        {
//            MS.scnScene.background.contents = NSColor.black
//        }
        MS.scnScene.background.contents = rs.nsDetectedColorImage()
        time = time + timestep
        let markerPoseJsonString = rs.getPoseInformation()
        MS.setMarkers(byJsonString: markerPoseJsonString!)
        
        //previousXY = [projectPoint.x,projectPoint.y] //2D的xy
    }
    
}
extension ViewController : SCNSceneRendererDelegate
{
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if let layer = scnARView.layer as? CAMetalLayer
        {
            //var texture = layer.currentSceneDrawable?.texture
            //print(texture)
        }
        occlusionHandler.getFrame()
        CalculateExecuteTime(title: "All render time", call: {
            renderImg()
//            let viewport: CGRect = CGRect(x: 0, y: 0, width: 640, height: 480)
//            let renderPassDescriptor = MTLRenderPassDescriptor()
//            let depthDescriptor : MTLTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float , width: 640, height: 480, mipmapped: false)
//            depthDescriptor.storageMode = .private
//            let device = MTLCreateSystemDefaultDevice()
//            //let depthTex = device?.makeTexture(descriptor: depthDescriptor)
//            let depthTex = self.scnARView.device!.makeTexture(descriptor: depthDescriptor)
//            depthTex.label = "Depth Texturyeeeeeeeeee"
//            renderPassDescriptor.depthAttachment.texture = depthTex
//            renderPassDescriptor.depthAttachment.loadAction = .clear
//            renderPassDescriptor.depthAttachment.clearDepth = 1.0
//            renderPassDescriptor.depthAttachment.storeAction = .store
//            commandQueue = device?.makeCommandQueue()
//            let commandBuffer = commandQueue.makeCommandBuffer()
//            var scene1 = SCNScene()
//            scene1 = scnARView.scene!
//            scnRenderer.scene = scene1
//            scnRenderer!.render(atTime: 0, viewport: viewport, commandBuffer: commandBuffer, passDescriptor: renderPassDescriptor)
//            
//            let depthImageBuffer:MTLBuffer = scnARView!.device!.makeBuffer(length: depthTex.width*depthTex.height*4, options: .storageModeShared)
//            depthImageBuffer.label = "Depth Bufferrrrr"
//            let blitCommandEncoder : MTLBlitCommandEncoder = commandBuffer.makeBlitCommandEncoder()
//            blitCommandEncoder.copy(from: renderPassDescriptor.depthAttachment.texture!,
//                                    sourceSlice: 0, sourceLevel: 0, sourceOrigin: MTLOriginMake(0, 0, 0), sourceSize: MTLSizeMake(640, 480, 1),
//                                    to: depthImageBuffer,
//                                    destinationOffset: 0, destinationBytesPerRow: 4*640, destinationBytesPerImage: 4*640*480)
//            blitCommandEncoder.endEncoding()
//            commandBuffer.commit()
//            print("DONE")
            
        })

    }
}
extension Double
{
    func toCGFloatRadius()->CGFloat
    {
        return CGFloat(self * .pi / 180)
        //用法： Radians = degree.toCGFloatRadius()
    }
}
extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .PNG, properties: [:])
    }
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error)
            return false
        }
    }
}
