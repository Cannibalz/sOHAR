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

class ViewController: NSViewController,SCNSceneRendererDelegate {
    @IBOutlet weak var silderTvec0: NSSlider!
    @IBOutlet weak var silderTvec1: NSSlider!
    
    @IBOutlet weak var silderTvec2: NSSlider!
    @IBOutlet weak var btnChangeSetting: NSButton!
    @IBOutlet weak var colorView: NSImageView!
    @IBOutlet weak var depthView: NSImageView!
    @IBOutlet weak var C2DView: NSImageView!
    
    
    @IBOutlet weak var mergeView: SCNView!
    
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
    var replacedScene = SCNScene()
    var offscreenView : SCNView!
    var offscreenScene : SCNScene!
    override func viewDidLoad() {
        super.viewDidLoad()
        rs.initRealsense()
        //DM = DepthMask2D(scnView: self.scnARView, downSample: 2, aroundMarkerOnly: true)
        MS = markerSystem(scnView: scnARView)
//        offscreenView = SCNView(frame: NSRect(x: 0, y: 0, width: 640, height: 480))
//        offscreenScene = SCNScene()
//        offscreenView.scene = offscreenScene
//        MS = markerSystem(offscreenView: offscreenView, offscreenScene: offscreenScene)
//        offscreenScene.rootNode.addChildNode(MS)
        scnARView.scene?.rootNode.addChildNode(DM)
        scnARView.scene?.rootNode.addChildNode(MS)
        scnARView.antialiasingMode = .multisampling4X
        scnARView.delegate = self
        //scnARView.isPlaying = true
        var cameraNode : SCNNode!
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 0, 0)
        cameraNode.name = "camera"
        replacedScene.background.contents = NSColor.black
        mergeView.scene = replacedScene
        replacedScene.rootNode.addChildNode(cameraNode)
        mergeView.delegate = self
        mergeView.isPlaying = true
        mergeView.antialiasingMode = .multisampling4X
        mergeView.showsStatistics = true
        //replacedView.scene?.rootNode.addChildNode(planeNode)
        scnARView.preferredFramesPerSecond = 60
        
        if let metalLayer = scnARView.layer as? CAMetalLayer
        {
            metalLayer.framebufferOnly = false
        }
        occlusionHandler = OcclusionHandler(augmentedView: self.scnARView,mergeScene:replacedScene)
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
        //replacedView.isPlaying = false
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
        var imageData = rs.nsD2CImage().tiffRepresentation
        var bitmapRep = NSBitmapImageRep.init(data: imageData!)
        scnARView.scene?.background.contents = rs.nsDetectedColorImage()
        //offscreenScene.background.contents = rs.nsDetectedColorImage()
        //print(offscreenScene.rootNode.childNodes.count)
        //mergeView.scene?.background.contents = NSColor.black
        time = time + timestep
        let markerPoseJsonString = rs.getPoseInformation()
        MS.setMarkers(byJsonString: markerPoseJsonString!)
        
        if let nsImage = rs.nsDetectedColorImage()
        {
            var imageRect:CGRect = CGRect(x: 0, y: 0, width: nsImage.size.width, height: nsImage.size.height)
            var imageRef = nsImage.cgImage(forProposedRect: &imageRect, context: nil, hints: nil)
            occlusionHandler.getFrame()
            occlusionHandler.findComparingNeededArea(rawDepthImage:bitmapRep!,rawColorImage: imageRef!)
            //print(imageRef)
            
        }
        
        
        //previousXY = [projectPoint.x,projectPoint.y] //2D的xy
    }
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        //replacedView.backgroundColo
        if let layer = scnARView.layer as? CAMetalLayer
        {
            //print(texture)
            //print(texture?.pixelFormat.rawValue)
        }
        //CalculateExecuteTime(title: "All render time", call: {
            renderImg()
        //})
        
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
