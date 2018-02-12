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
    var Rmat: [Double]
}

class markerSystem : SCNNode
{
    static let sharedInstance = markerSystem()
    var view : SCNView = SCNView()
    var depthArray = DepthMask2D()
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
        self.name = "markerObjectNode"
        scnScene.rootNode.addChildNode(buildCameraNode(x: 0,y: 0,z: 5))
        let plane = SCNPlane(width: 1, height: 1)
        //let plane = SCNBox(width: 1, height: 1, length: 1, chamferRadius: 1)
        if #available(OSX 10.13, *) {
            //plane.firstMaterial?.colorBufferWriteMask = SCNColorMask(rawValue: 0)
        } else {
            // Fallback on earlier versions
        }
        plane.firstMaterial?.isDoubleSided = true
        let planeNode = SCNNode(geometry: plane)
        planeNode.renderingOrder = 10
        planeNode.name = "bigPlane"
        
        //planeNode.position = view.unprojectPoint(SCNVector3(320,240,0.5))
        //print(view.projectPoint(planeNode.position))
        planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
//        planeNode.physicsBody?.categoryBitMask = CollisionTypes.realDepth.rawValue
//        planeNode.physicsBody?.collisionBitMask = CollisionTypes.object.rawValue
        planeNode.physicsBody?.categoryBitMask = CollisionTypes.object.rawValue
        planeNode.physicsBody?.collisionBitMask = CollisionTypes.object.rawValue|CollisionTypes.realDepth.rawValue
        //self.addChildNode(planeNode)
        virtualModelDictionary[228] = ("Mickey_Mouse","MKY.jpg")
        virtualModelDictionary[10] = ("Mickey_Mouse","MKY.jpg")
        virtualModelDictionary[0] = ("Mickey_Mouse","MKY.jpg")
        
    }
    convenience init(scnView:SCNView) {
        self.init()
        self.view = scnView
        self.view.scene = scnScene
        self.view.showsStatistics = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //fatalError("init(coder:) has not been implemented")
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
        if self.childNodes.count > 0
        {
            //print(self.childNodes[0].boundingBox)
        }
        //}
        previousIdDictionary = idDictionary
        //print(view.unprojectPoint(SCNVector3(0,0,0)))
        //print(view.scene?.rootNode.childNode(withName: "bigPlane", recursively: false)?.position)
        //print(view.projectPoint((view.scene?.rootNode.childNode(withName: "bigPlane", recursively: false)?.position)!))
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
                    //print("\(id.key):\(id.value)")
                    var node = createNodeModel(objName: (virtualModelDictionary[id.key]?.0)!, textureName: (virtualModelDictionary[id.key]?.1)!, nodeName: "\(id.key)-\(nodeId)")
                    //scnScene.rootNode.addChildNode(node)
                    self.addChildNode(node)
                }
                //新增此id節點
            }
            else if previousIdDictionary[id.key] != nil
            {
                if previousIdDictionary[id.key]! > id.value
                {
                    for nodeId in id.value..<previousIdDictionary[id.key]!
                    {
                        //scnScene.rootNode.childNode(withName: "\(id.key)-\(nodeId)", recursively: true)?.removeFromParentNode()
                        self.childNode(withName: "\(id.key)-\(nodeId)", recursively: true)?.removeFromParentNode()
                    }
                    //刪除此id多餘節點
                }
                else if previousIdDictionary[id.key]! < id.value
                {
                    //print(previousIdDictionary)
                    for nodeId in previousIdDictionary[id.key]!..<id.value
                    {
                        var node = createNodeModel(objName: (virtualModelDictionary[id.key]?.0)!, textureName: (virtualModelDictionary[id.key]?.1)!, nodeName: "\(id.key)-\(nodeId)")
                        //scnScene.rootNode.addChildNode(node)
                        self.addChildNode(node)
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
                    //scnScene.rootNode.childNode(withName: "\(id.key)-\(nodeId)", recursively: true)?.removeFromParentNode()
                    self.childNode(withName: "\(id.key)-\(nodeId)", recursively: true)?.removeFromParentNode()
                }
            }
            //刪除此id所有節點
        }
    }
    func setVirtualObject()
    {

        let arrIDKey = idDictionary.keys
//        print(arrIDKey)
//        print(scnScene.rootNode.childNodes)

        for IDKey in arrIDKey
        {
            //print("IDKey:\(IDKey)")
            let arrID = markers.filter{ (marker) -> Bool in //取得Markers中所有特定ID的元素
                return marker.id == IDKey}
            for i in 0..<arrID.count
            {
                var positionAndScale = objPositionCalculating(Corners: arrID[i].Corners)
                //scnScene.rootNode.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.position = positionAndScale["position"]!
                if(arrID[i].Rmat.count == 1)
                {
                    self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.eulerAngles = makeEularAngles(rvec: arrID[i].Rvec)
                }
                else if (arrID[i].Rmat.count == 9)
                {
                    self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.transform.m11 = CGFloat(arrID[i].Rmat[0])
                    self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.transform.m12 = CGFloat(-arrID[i].Rmat[1])
                    self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.transform.m13 = CGFloat(-arrID[i].Rmat[2])
                    self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.transform.m21 = CGFloat(arrID[i].Rmat[6])
                    self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.transform.m22 = CGFloat(-arrID[i].Rmat[7])
                    self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.transform.m23 = CGFloat(-arrID[i].Rmat[8])
                    self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.transform.m31 = CGFloat(-arrID[i].Rmat[3])
                    self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.transform.m32 = CGFloat(arrID[i].Rmat[4])
                    self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.transform.m33 = CGFloat(arrID[i].Rmat[5])
                }
                //print(self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.transform)
                self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.position = positionAndScale["position"]!
                //print(self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.transform)
                //scnScene.rootNode.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.scale = positionAndScale["scale"]!
                self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.scale = positionAndScale["scale"]!
                //scnScene.rootNode.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.eulerAngles = makeEularAngles(rvec: arrID[i].Rvec)
                //print(arrID[i].Rvec)
                //print(view.projectPoint((self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.boundingBox.min)!))
                //print(view.projectPoint((self.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.boundingBox.max)!))
                //var boundingBoxArray = scnScene.rootNode.childNode(withName: "\(IDKey)-\(i)", recursively: false)?.boundingBox
                
                
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
        texture.blendMode = .replace
        objNode.name = nodeName
        objNode.geometry?.firstMaterial = texture
        objNode.renderingOrder = -1
//        objNode.physicsBody = SCNPhysicsBody(type : .static,shape : nil)
//        objNode.physicsBody?.categoryBitMask = CollisionTypes.object.rawValue
//        objNode.physicsBody?.collisionBitMask = CollisionTypes.object.rawValue|CollisionTypes.realDepth.rawValue
        //renderObject.scale = SCNVector3(0.001,0.001,0.001)
        return objNode
    }
    func buildCameraNode(x:CGFloat,y:CGFloat,z:CGFloat) -> SCNNode!
    {
        var cameraNode : SCNNode!
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x:x, y:y, z:z)
        cameraNode.name = "camera"
        //cameraNode.camera?.zNear = 7.3
        return cameraNode
    }
    func objPositionCalculating(Corners: [[Double]]) -> [String:SCNVector3]
    {
        //print(Corners)
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
                avgLength += sqrt(pow((Corners[i][0]-Corners[i+1][0]), 2) + pow((Corners[i][1]-Corners[i+1][1]),2))
            }
        }
        //middleX = (middleX/4-320)/50
        middleX = middleX/4
        middleY = middleY/4
        //middleY = -(middleY/4-240)/50
        avgLength = avgLength/4
        //print(avgLength)
        //node.eulerAngles = makeEularAngles(rvec : markers[0].Rvec)
        //node.position = SCNVector3Make(CGFloat(middleX),CGFloat(middleY),-3)
//        node.scale = SCNVector3Make(CGFloat(avgLength/200),CGFloat(avgLength/200),CGFloat(avgLength/200))
        var position2D = SCNVector3(middleX,middleY,1-(avgLength/200))
        //print(position2D)
        position2D.y += -20 //拉高
        //return ["position" :SCNVector3Make(CGFloat(middleX),CGFloat(middleY),-3),"scale":SCNVector3Make(CGFloat(avgLength/200),CGFloat(avgLength/200),CGFloat(avgLength/200))]
        var position3D = view.unprojectPoint(position2D)
        position3D.y *= -1
        return ["position" :position3D,"scale":SCNVector3Make(CGFloat(0.1),CGFloat(0.1),CGFloat(0.1))]
    }
    func makeEularAngles(rvec : [Double]) -> SCNVector3
    {
        let eulerAngles = SCNVector3Make(rvec[0].toCGFloatRadius()+CGFloat(3*Double.pi/2) ,-rvec[1].toCGFloatRadius(), -rvec[2].toCGFloatRadius())
        return eulerAngles
    }
}
