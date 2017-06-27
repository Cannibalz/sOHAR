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
    @IBOutlet weak var colorView: NSImageView!
    @IBOutlet weak var depthView: NSImageView!
    @IBOutlet weak var C2DView: NSImageView!
    @IBOutlet weak var scnARView: SCNView!
    @IBOutlet weak var arView: MTKView!
    var timer : Timer = Timer()
    var rs : objCRealsense = objCRealsense()
    var nsImg : NSImage? = nil
    var renderer: Renderer!
    var scnScene : SCNScene!
    override func viewDidLoad() {
        super.viewDidLoad()
        rs.initRealsense()
        timer = Timer.scheduledTimer(timeInterval: 0.03, target: self, selector: #selector(renderImg), userInfo: nil, repeats: true)
        renderer = Renderer(mtkView: arView)
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
        colorView.image = rs.nsDetectedColorImage()
        depthView.image = rs.nsDepthImage()
        C2DView.image = rs.nsC2DImage()
        scnScene.background.contents = rs.nsColorImage()
    }
    func setupScene()
    {
        scnScene = SCNScene()
        let bundle = Bundle.main
        let path = bundle.path(forResource: "MKY",ofType:"obj",inDirectory: "model.scnassets")
        let url = NSURL(fileURLWithPath: path!)
        let asset = MDLAsset(url:url as URL)
        let stageObject = asset.object(at: 0)
        let stage = SCNNode(mdlObject: stageObject)
        let texture = SCNMaterial()
        //texture.diffuse.contents = NSImage(named: "model.scnassets/MKY.jpg")
        texture.diffuse.contents = NSImage(named: "MKY.jpg")
        stage.geometry?.firstMaterial = texture
        scnARView.scene = scnScene
    }
}


