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
    private var Count : Int = 0
    var idDictionary : Dictionary = [Int:Int]()
    var dictionary: Dictionary<Int, (String, String)> = [Int:(String,String)]()
    var markers : [marker] = []

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
        var tempId : Dictionary = [Int:Int]() //now
        for marker in markers
        {
            if tempId[marker.id] == nil
            {
                tempId[marker.id] = 1
            }
            else
            {
                tempId[marker.id] = tempId[marker.id]!+1
            }
        }
        for ID in tempId
        {
           idDictionary[ID.key] = ID.value
        }
        for ID in idDictionary
        {
            if tempId[ID.key] == nil
            {
                idDictionary.removeValue(forKey: ID.key)
            }
        }
    }
    func getCount() -> Int
    {
        return self.Count
    }
    func createNodeModel(objName:String,textureName:String) -> SCNNode
    {
        let bundle = Bundle.main
        let path = bundle.path(forResource: objName,ofType:"obj")
        let url = NSURL(fileURLWithPath: path!)
        let asset = MDLAsset(url:url as URL)
        let stageObject = asset.object(at: 0)
        let objNode = SCNNode(mdlObject: stageObject)
        let texture = SCNMaterial()
        texture.diffuse.contents = NSImage(named: textureName)
        objNode.geometry?.firstMaterial = texture
        //renderObject.scale = SCNVector3(0.001,0.001,0.001)
        return objNode
    }
    
}
