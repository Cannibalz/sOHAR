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
    //var renderer: Renderer!
    var time = TimeInterval(0.0)
    let timestep = 1.0 / 30
    var markers : [Marker] = []
    var MS = markerSystem()
    var DM = DepthMask2D()
    var planePositionIn2D = SCNVector3(480,360,0.4)
    var countt = 0
    
    var ssCount = 12;
    override func viewDidLoad() {
        super.viewDidLoad()
        rs.initRealsense()
        DM = DepthMask2D(scnView: self.scnARView, downSample: 2, aroundMarkerOnly: true)
        MS = markerSystem(scnView: scnARView)
        scnARView.scene?.rootNode.addChildNode(DM)
        scnARView.scene?.rootNode.addChildNode(MS)
        scnARView.antialiasingMode = .multisampling4X
        scnARView.delegate = self
        scnARView.isPlaying = true
        scnARView.preferredFramesPerSecond = 60
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
        CalculateExecuteTime(title: "All render time", call: {
            renderImg()
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
