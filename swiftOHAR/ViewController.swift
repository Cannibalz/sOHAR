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
    var renderer: Renderer!
    var time = TimeInterval(0.0)
    let timestep = 1.0 / 30
    var markers : [Marker] = []
    var MS = markerSystem()
    var DM = DepthMask2D()
    var planePositionIn2D = SCNVector3(480,360,0.4)
    var countt = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rs.initRealsense()
        
        MS = markerSystem(scnView: scnARView)
        scnARView.scene?.rootNode.addChildNode(DM)
        scnARView.scene?.rootNode.addChildNode(MS)
        scnARView.antialiasingMode = .multisampling4X
        let pc = PointCloud()
        let pcNode = pc.getNode()
        pcNode.position = SCNVector3(x: 0, y: -0.1, z: 0)
        pcNode.scale = SCNVector3(5,5,5)
        let plane = SCNPlane(width: 0.3, height: 0.3)
        plane.firstMaterial?.diffuse.contents = NSColor.black.withAlphaComponent(0.5)
        plane.firstMaterial?.isDoubleSided = true
        if #available(OSX 10.13, *) {
            //plane.firstMaterial?.colorBufferWriteMask = SCNColorMask(rawValue: 0)
        }
        let planeNode = SCNNode(geometry: plane)
        planeNode.renderingOrder = -3
        planeNode.name = "planeFromView"
        planeNode.position = scnARView.unprojectPoint(SCNVector3(338.706115722656,258.706146240234,0.23838415145874))
        //scnARView.scene?.rootNode.addChildNode(planeNode)
        scnARView.scene?.rootNode.addChildNode(pcNode)
        DM.scnView = self.scnARView
        DM.downSample = 2
        DM.aroundMarkerOnly = true
        
//        var pcNode = SCNNode()
//        pcNode.name = "pcNode"
//        pcNode.renderingOrder = -2
//        scnARView.scene?.rootNode.addChildNode(pcNode)
        
        scnARView.delegate = self
        scnARView.isPlaying = true
        scnARView.preferredFramesPerSecond = 60
        //timer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(renderImg), userInfo: nil, repeats: true)
        
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
        print("viewDidDisappear")
        exit(0)
    }
    @IBAction func fdsfdsfsd(_ sender: Any) {
        if cbUsingMask.state == NSOnState
        {
            DM.enable = true
        }
        else
        {
            DM.enable = false
        }
        if cbMaskColor.state == NSOnState
        {
            DM.coloredMask = true
        }
        else
        {
            DM.coloredMask = false
        }
    }
    func renderImg()
    {
        doDepthMap = !doDepthMap
        rs.waitForNextFrame()
        rs.getPoseInformation()
        //nsView只能在mainThread處理
        //colorView.image = rs.nsDetectedColorImage()
        //depthView.image = rs.nsD2CImage()
        //C2DView.image = rs.nsC2DImage()
        if doDepthMap && countt < 10 && DM.enable == true
        {
            //countt += 1
            var imageData = rs.nsD2CImage().tiffRepresentation
            var bitmapRep = NSBitmapImageRep.init(data: imageData!) //深度
            DM.setDepthValue(bitmapImageRep: bitmapRep!, view: scnARView,idDictionary: MS.idDictionary)
            DM.refresh()
//            scnARView.scene?.rootNode.childNode(withName: "pcNode", recursively: true)?.removeFromParentNode()
//            scnARView.scene?.rootNode.addChildNode(DM.getNode())
        }
        rs.nsDetectedColorImage()
        if cbMarkerDetection.state == NSOnState
        {
            MS.scnScene.background.contents = rs.nsDetectedColorImage()
        }
        else
        {
            MS.scnScene.background.contents = NSColor.black
        }
        //MS.scnScene.background.contents = rs.nsDetectedColorImage()
        time = time + timestep
        let markerPoseJsonString = rs.getPoseInformation()
        MS.setMarkers(byJsonString: markerPoseJsonString!)
        planePositionIn2D = SCNVector3(338.706115722656,258.706146240234,0.883838415145874)
        //print(scnARView.unprojectPoint(planePositionIn2D))
        var planePosition = SCNVector3(320,240,0.1)
        //planePosition.x = CGFloat(silderTvec0.floatValue)
        //planePosition.y = CGFloat(silderTvec1.floatValue)
        //planePosition.z = CGFloat(silderTvec2.floatValue)
        
        let projectPoint = scnARView.projectPoint(planePosition)
        //print(projectPoint)
        previousXY = [projectPoint.x,projectPoint.y] //2D的xy
    }
    
}
extension ViewController : SCNSceneRendererDelegate
{
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        renderImg()
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

