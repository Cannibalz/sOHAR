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

struct markerPose : Codable
{
    var id: Int
    var Tvec: [Double]
    var Rvec: [Double]
    var Corners : [[Double]]
}
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
    
    var timer : Timer = Timer()
    var scnTimer = Timer()
    var rs : objCRealsense = objCRealsense()
    var nsImg : NSImage? = nil
    var renderer: Renderer!
    var scnScene : SCNScene!
    var time = TimeInterval(0.0)
    let timestep = 1.0 / 30
    var markersPose : [markerPose] = []
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
        scnScene.background.contents = rs.nsColorImage()
    }
    func setupScene()
    {
        scnScene = SCNScene()
        let bundle = Bundle.main
        let path = bundle.path(forResource: "MKY",ofType:"obj")
        //let path = bundle.path(forResource: "tikiPot",ofType:"stl")
        let url = NSURL(fileURLWithPath: path!)
        let asset = MDLAsset(url:url as URL)
        let stageObject = asset.object(at: 0)
        let renderObject = SCNNode(mdlObject: stageObject)
        let texture = SCNMaterial()
        //texture.diffuse.contents = NSImage(named: "model.scnassets/MKY.jpg")
        texture.diffuse.contents = NSImage(named: "MKY.jpg")
        renderObject.geometry?.firstMaterial = texture
        renderObject.name = "mky"
        //stage.scale = SCNVector3(x:0.5, y:0.5, z:0.5)
        renderObject.position = SCNVector3(x:0, y:0, z:-3)//z越大物體越近？
        
        scnScene.rootNode.addChildNode(buildCameraNode(x: 0,y: 0,z: 5))
        scnScene.rootNode.addChildNode(renderObject)
        scnARView.scene = scnScene
        
        scnARView.showsStatistics = true
        scnARView.allowsCameraControl = true
        scnARView.autoenablesDefaultLighting = true
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
        var markerPoseJsonString = rs.getPoseInformation()
        if markerPoseJsonString != "[]"
        {
            //let jsonData = markerPoseJsonString?.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            let jsonData = markerPoseJsonString?.data(using: .utf8)
            let decoder = JSONDecoder()
            let KingGeorge = try! decoder.decode([markerPose].self, from: jsonData!);
            markersPose = KingGeorge
        
            //print(Double.pi/180)
            //print(markersPose[0].Tvec)
            //yaw=[1] pitch=[0] roll=[2]
        }
        print(markersPose);
        for node in scnScene.rootNode.childNodes
        {
            if node.name == "mky" && markersPose.count > 0 && markersPose[0].id == 228
            {
                node.eulerAngles = SCNVector3Make(markersPose[0].Rvec[0].toCGFloatRadius()+3.14,
                                                  -markersPose[0].Rvec[1].toCGFloatRadius(),
                                                  -markersPose[0].Rvec[2].toCGFloatRadius())
                //node.position = SCNVector3Make(CGFloat(markersPose[0].Tvec[0]), -CGFloat(markersPose[0].Tvec[1]), -CGFloat(markersPose[0].Tvec[2]))
                node.position = SCNVector3Make(CGFloat(silderTvec0.doubleValue), CGFloat(silderTvec1.doubleValue), CGFloat(silderTvec2.doubleValue))
//                tvec0.doubleValue = silderTvec0.doubleValue
//                tvec1.doubleValue = silderTvec1.doubleValue
//                tvec2.doubleValue = silderTvec2.doubleValue
                tvec0.doubleValue = markersPose[0].Tvec[0]
                tvec1.doubleValue = markersPose[0].Tvec[1]
                tvec2.doubleValue = markersPose[0].Tvec[2]
            }
        }
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

