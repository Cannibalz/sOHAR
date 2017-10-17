//
// Created by Kaofan on 2017/9/29.
// Copyright (c) 2017 Tom Cruise. All rights reserved.
//

import Foundation
import Metal
import MetalKit
import SceneKit
import SceneKit.ModelIO

struct Marker : Codable
{
    var id: Int
    var Tvec: [Double]
    var Rvec: [Double]
    var Corners : [[Double]]
}

class markerSystem : NSObject
{
    var scnScene : SCNScene = SCNScene()
    private var Count : Int = 0
    var previousIdDictionary : Dictionary = [Int:Int]()
    var idDictionary : Dictionary = [Int:Int]()
    var virtualModelDictionary: Dictionary<Int, (String, String)> = [Int:(String,String)]()
    //id對應模型、材質的索引
    var markers : [Marker] = []
    
    override init()
    {
        super.init()
        scnScene.rootNode.addChildNode(buildCameraNode(x: 0,y: 0,z: 5))
        virtualModelDictionary[228] = ("Mickey_Mouse","MKY.jpg")
        virtualModelDictionary[10] = ("Mickey_Mouse","MKY.jpg")
    }
    func setMarkers(byJsonString : String)
    {
        //if byJsonString != "[]"
        //{
            let jsonData = byJsonString.data(using: .utf8)
            let decoder = JSONDecoder()
            let KingGeorge = try! decoder.decode([Marker].self, from: jsonData!);
            var filterMarker = [Marker]()
            for crew in KingGeorge  //刪除沒在資料庫內的marker
            {
                if virtualModelDictionary[crew.id] != nil
                {
                    filterMarker.append(crew)
                }
            }
            self.markers = filterMarker
            idCalculating()
            setVirtualObject()
        //}
        previousIdDictionary = idDictionary
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
                for nodeId in 0..<id.value
                {
                    print("\(id.key):\(id.value)")
                    var node = createNodeModel(objName: (virtualModelDictionary[id.key]?.0)!, textureName: (virtualModelDictionary[id.key]?.1)!, nodeName: "\(id.key)-\(nodeId)")
                    scnScene.rootNode.addChildNode(node)
                }
                //新增此id節點
            }
            else if previousIdDictionary[id.key] != nil
            {
                if previousIdDictionary[id.key]! > id.value
                {
                    for nodeId in id.value..<previousIdDictionary[id.key]!
                    {
                        scnScene.rootNode.childNode(withName: "\(id.key)-\(nodeId)", recursively: true)?.removeFromParentNode()
                    }
                    //刪除此id多餘節點
                }
                else if previousIdDictionary[id.key]! < id.value
                {
                    print(previousIdDictionary)
                    for nodeId in previousIdDictionary[id.key]!..<id.value
                    {
                        var node = createNodeModel(objName: (virtualModelDictionary[id.key]?.0)!, textureName: (virtualModelDictionary[id.key]?.1)!, nodeName: "\(id.key)-\(nodeId)")
                        scnScene.rootNode.addChildNode(node)
                    }
                    //新增此id剩餘節點
                }
            }
        }
        for id in previousIdDictionary
        {
            if idDictionary[id.key] == nil
            {
                for nodeId in 0..<id.value
                {
                    scnScene.rootNode.childNode(withName: "\(id.key)-\(nodeId)", recursively: true)?.removeFromParentNode()
                }
            }
            //刪除此id所有節點
        }
    }
    func setVirtualObject()
    {
        let arrIDKey = idDictionary.keys
        print(arrIDKey)
        print(scnScene.rootNode.childNodes)
        for IDKey in arrIDKey
        {
            print("IDKey:\(IDKey)")
            let arrID = markers.filter{ (marker) -> Bool in //取得Markers中所有特定ID的元素
                return marker.id == IDKey}
            for i in 0..<arrID.count
            {
                var positionAndScale = objPositionCalculating(Corners: arrID[i].Corners)
                scnScene.rootNode.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.position = positionAndScale["position"]!
                scnScene.rootNode.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.scale = positionAndScale["scale"]!
                scnScene.rootNode.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.eulerAngles = makeEularAngles(rvec: arrID[i].Rvec)
                var scnn = scnScene.rootNode.childNode(withName: "\(IDKey)-\(i)", recursively: false)
                print(scnn?.name)
                print(scnn?.position)
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
    func setMarkerPosition(marker:Marker) -> SCNVector3
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
    func objPositionCalculating(Corners: [[Double]]) -> [String:SCNVector3]
    {
        var middleX = Double()
        var middleY = Double()
        var avgLength = Double()
        for corner in Corners
        {
            middleX += corner[0]
            middleY += corner[1]
        }
        
        for i in 0..<Corners.count
        {
            if i == (Corners.count-1)
            {
                avgLength += sqrt(pow((Corners[i][0]-Corners[0][0]), 2) + pow((Corners[i][1]-Corners[0][1]),2))
            }
            else
            {
                avgLength += sqrt(pow((Corners[i][0]-markers[0].Corners[i+1][0]), 2) + pow((Corners[i][1]-Corners[i+1][1]),2))
            }
        }
        middleX = (middleX/4-320)/50
        middleY = -(middleY/4-240)/50
        avgLength = avgLength/4
        //node.eulerAngles = makeEularAngles(rvec : markers[0].Rvec)
        //node.position = SCNVector3Make(CGFloat(middleX),CGFloat(middleY),-3)
//        node.scale = SCNVector3Make(CGFloat(avgLength/200),CGFloat(avgLength/200),CGFloat(avgLength/200))
        return ["position" :SCNVector3Make(CGFloat(middleX),CGFloat(middleY),-3),"scale":SCNVector3Make(CGFloat(avgLength/200),CGFloat(avgLength/200),CGFloat(avgLength/200))]
    }
    func makeEularAngles(rvec : [Double]) -> SCNVector3
    {
        let eulerAngles = SCNVector3Make(rvec[0].toCGFloatRadius()+CGFloat(Double.pi) ,-rvec[1].toCGFloatRadius(), -rvec[2].toCGFloatRadius())
        return eulerAngles
    }
}
