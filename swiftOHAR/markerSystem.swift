//
// Created by Kaofan on 2017/9/29.
// Copyright (c) 2017 Tom Cruise. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import SceneKit
import SceneKit.ModelIO

struct marker : Codable
{
    var id: Int
    var Tvec: [Double]
    var Rvec: [Double]
    var Corners : [[Double]]
}

class markerSystem : NSObject
{
    private var scnScene : SCNScene = SCNScene()
    private var Count : Int = 0
    var previousIdDictionary : Dictionary = [Int:Int]()
    var idDictionary : Dictionary = [Int:Int]()
    var virtualModelDictionary: Dictionary<Int, (String, String)> = [Int:(String,String)]()
    //id對應模型、材質的索引
    var markers : [marker] = []
    override init()
    {
        super.init()
        scnScene.rootNode.addChildNode(buildCameraNode(x: 0,y: 0,z: 5))
        virtualModelDictionary[228] = ("Mickey_Mouse","MKY.jpg")
    }
    func setMarkers(byJsonString : String)
    {
        if byJsonString != "[]"
        {
            let jsonData = byJsonString.data(using: .utf8)
            let decoder = JSONDecoder()
            let KingGeorge = try! decoder.decode([marker].self, from: jsonData!);
            self.markers = KingGeorge
            idCalculating()
        }
    }
    func idCalculating()
    {
        //var tempId : Dictionary = [Int:Int]() //now
        self.idDictionary = [Int:Int]()
        for marker in markers
        {
            if self.idDictionary[marker.id] == nil
            {
                self.idDictionary[marker.id] = 1
            }
            else
            {
                self.idDictionary[marker.id] = self.idDictionary[marker.id]!+1
            }
        }
        for id in idDictionary
        {
            if previousIdDictionary[id.key] == nil
            {
                //新增此id節點
            }
            else if previousIdDictionary[id.key] != nil
            {
                if previousIdDictionary[id.key]! > id.value
                {
                    //刪除此id多餘節點
                }
                else if previousIdDictionary[id.key]! < id.value
                {
                    //新增此id剩餘節點
                }
            }
        }
        for id in previousIdDictionary
        {
            if idDictionary[id.key] == nil
            {
                //刪除此id所有節點
            }
        }
    }
    func getCount() -> Int
    {
        return self.Count
    }
    func createNodeModel(objName:String,textureName:String,nodeName:String) -> SCNNode
    {
        let bundle = Bundle.main
        let path = bundle.path(forResource: objName,ofType:"obj")
        let url = NSURL(fileURLWithPath: path!)
        let asset = MDLAsset(url:url as URL)
        let stageObject = asset.object(at: 0)
        let objNode = SCNNode(mdlObject: stageObject)
        let texture = SCNMaterial()
        texture.diffuse.contents = NSImage(named: textureName)
        objNode.name = nodeName
        objNode.geometry?.firstMaterial = texture
        //renderObject.scale = SCNVector3(0.001,0.001,0.001)
        return objNode
    }
    func setMarkerPosition(marker:marker) -> SCNVector3
    {
        return SCNVector3()
    }
    func buildCameraNode(x:CGFloat,y:CGFloat,z:CGFloat) -> SCNNode!
    {
        var cameraNode : SCNNode!
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x:x, y:y, z:z)
        return cameraNode
    }
}
