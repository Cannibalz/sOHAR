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
    @IBOutlet weak var scnARView: SCNView!
    @IBOutlet weak var arView: MTKView!
    @IBOutlet weak var tvec0: NSTextField!
    @IBOutlet weak var tvec1: NSTextField!
    @IBOutlet weak var tvec2: NSTextField!
    private var nodeArray : [SCNNode] = []
    
    let maxX : Float = 0.769800186158227
    let maxY : Float = 0.57735019922565
    
    var timer : Timer = Timer()
    var scnTimer = Timer()
    var rs : objCRealsense = objCRealsense()
    var nsImg : NSImage? = nil
    var renderer: Renderer!
    var scnScene = ARViewController()
    var time = TimeInterval(0.0)
    let timestep = 1.0 / 30
    var markers : [Marker] = []
    var MS = markerSystem()
    override func viewDidLoad() {
        super.viewDidLoad()
        rs.initRealsense()
        timer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(renderImg), userInfo: nil, repeats: true)
        //renderer = Renderer(mtkView: arView)
        setupScene()
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
        MS.scnScene.background.contents = rs.nsColorImage()
    }
    func setupScene()
    {

        scnARView.scene = MS.scnScene
        scnARView.pointOfView = buildCameraNode(x: 0, y: 0, z: 5)
        scnARView.showsStatistics = true
        scnARView.allowsCameraControl = true
        scnARView.autoenablesDefaultLighting = true
        let yy = SCNVector3(480,360,0)
        let oo = SCNVector3(maxX/2,maxY/2,4)
        print(scnARView.projectPoint(oo))
        
        
     scnTimer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(scnRender), userInfo: nil, repeats: true)
    }
    func buildCameraNode(x:CGFloat,y:CGFloat,z:CGFloat) -> SCNNode!
    {
        var cameraNode : SCNNode!
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x:x, y:y, z:z)
        return cameraNode
    }
    func scnRender()
    {
        time = time + timestep
        let markerPoseJsonString = rs.getPoseInformation()
        MS.setMarkers(byJsonString: markerPoseJsonString!)
    }
    func makeEularAngles(rvec : [Double]) -> SCNVector3
    {
        let eulerAngles = SCNVector3Make(rvec[0].toCGFloatRadius()+CGFloat(Double.pi) ,-rvec[1].toCGFloatRadius(), -rvec[2].toCGFloatRadius())
        return eulerAngles
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

