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
    
    let maxX : Float = 0.769800186158227
    let maxY : Float = 0.57735019922565
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
    var planePositionIn2D = SCNVector3(480,360,0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //scnARView = ARViewController(frame: NSRect.init(x: 0, y: 0, width: 640, height: 480), options: nil)
        MS = markerSystem(scnView: scnARView)
        rs.initRealsense()
        timer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(renderImg), userInfo: nil, repeats: true)
        //renderer = Renderer(mtkView: arView)
        
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
    func renderImg()
    {
        rs.waitForNextFrame()
        rs.getPoseInformation()
        colorView.image = rs.nsDetectedColorImage()
        depthView.image = rs.nsDepthImage()
        C2DView.image = rs.nsC2DImage()
        scnARView.scene?.background.contents = rs.nsColorImage()
        MS.scnScene.background.contents = rs.nsColorImage()
        
        time = time + timestep
        let markerPoseJsonString = rs.getPoseInformation()
        MS.setMarkers(byJsonString: markerPoseJsonString!)
        planePositionIn2D = SCNVector3(338.706115722656,258.706146240234,0.883838415145874)
        print(scnARView.unprojectPoint(planePositionIn2D))
        var planePosition = SCNVector3(0,0,-2)
        
        planePosition.x = CGFloat(silderTvec0.floatValue)
        planePosition.y = CGFloat(silderTvec1.floatValue)
        planePosition.z = CGFloat(silderTvec2.floatValue)
        
        
        let projectPoint = scnARView.projectPoint(planePosition)
        print(projectPoint)
        previousXY = [projectPoint.x,projectPoint.y] //2D的xy
        
        self.scnARView.scene?.rootNode.childNode(withName: "bigPlane", recursively: false)?.position = planePosition
        
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

