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
    var timer : Timer = Timer()
    var scnTimer = Timer()
    var rs : objCRealsense = objCRealsense()
    var nsImg : NSImage? = nil
    var renderer: Renderer!
    var scnScene = ARViewController()
    var time = TimeInterval(0.0)
    let timestep = 1.0 / 30
    var markers : [marker] = []
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
        scnScene.background.contents = rs.nsColorImage()
    }
    func setupScene()
    {
        //scnScene = SCNScene()
        let bundle = Bundle.main
        let path = bundle.path(forResource: "lowpolytree",ofType:"obj")
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
        //renderObject.scale = SCNVector3(0.001,0.001,0.001)
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
        let markerPoseJsonString = rs.getPoseInformation()
        MS.setMarkers(byJsonString: markerPoseJsonString!)

        if markerPoseJsonString != "[]"
        {
            //let jsonData = markerPoseJsonString?.data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            let jsonData = markerPoseJsonString?.data(using: .utf8)
            let decoder = JSONDecoder()
            let KingGeorge = try! decoder.decode([marker].self, from: jsonData!);
            markers = KingGeorge

            //print(Double.pi/180)
            //print(markersPose[0].Tvec)
            //yaw=[1] pitch=[0] roll=[2]
        }
        //print(markersPose);
        for Marker in markers
        {
            
        }
        for node in scnScene.rootNode.childNodes
        {
            if node.name == "mky" && markers.count > 0 && markers[0].id == 228
            {
                var middleX = Double()
                var middleY = Double()
                var avgLength = Double()
                for corner in markers[0].Corners
                {
                    middleX += corner[0]
                    middleY += corner[1]
                }
                
                for i in 0..<markers[0].Corners.count
                {
                    if i == (markers[0].Corners.count-1)
                    {
                        avgLength += sqrt(pow((markers[0].Corners[i][0]-markers[0].Corners[0][0]), 2) + pow((markers[0].Corners[i][1]-markers[0].Corners[0][1]),2))
                    }
                    else
                    {
                        avgLength += sqrt(pow((markers[0].Corners[i][0]-markers[0].Corners[i+1][0]), 2) + pow((markers[0].Corners[i][1]-markers[0].Corners[i+1][1]),2))
                    }
                }
                middleX = (middleX/4-320)/50
                middleY = -(middleY/4-240)/50
                avgLength = avgLength/4
                node.eulerAngles = makeEularAngles(rvec : markers[0].Rvec)
                node.position = SCNVector3Make(CGFloat(middleX),CGFloat(middleY),-3)
                node.scale = SCNVector3Make(CGFloat(avgLength/200),CGFloat(avgLength/200),CGFloat(avgLength/200))
//                tvec0.doubleValue = markersPose[0].Tvec[0]
//                tvec1.doubleValue = markersPose[0].Tvec[1]
//                tvec2.doubleValue = markersPose[0].Tvec[2]
                tvec0.doubleValue = silderTvec0.doubleValue
                tvec1.doubleValue = silderTvec1.doubleValue
                tvec2.doubleValue = silderTvec2.doubleValue
                //node.position = SCNVector3Make(CGFloat(silderTvec0.doubleValue),CGFloat(silderTvec1.doubleValue),CGFloat(silderTvec2.doubleValue))
            }
        }
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

