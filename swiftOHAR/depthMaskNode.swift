//
//  depthMask.swift
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/11/29.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

import Foundation
import SceneKit
struct nodePos {
    var minX: Int
    var minY: Int
    var maxX: Int
    var maxY: Int
}

class DepthMask2D : SCNNode
{
    static let sharedInstance = DepthMask2D()
    
    var depthValueArray : [[CGFloat]] = Array(repeating: Array(repeating: 0, count: 480), count: 640)
    var depthPointCloud : [SCNVector3] = Array()
    var depthVertexArray : [PointCloudVertex] = Array()
//    var pcNode : SCNNode = SCNNode()
    var downSample = 2
    var aroundMarkerOnly = false
    var enable = true
    var performEvery_Times = 2
    var coloredMask = true
    var scnView = SCNView()
    //var valueArray : [[NSColor]] = Array(repeating: Array(repeating: 0, count: 480), count: 640)
    override init() {
        super.init()
        self.name = "depthMask"
        self.renderingOrder = -100
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
//    convenience init(view:SCNView) {
//        //super.init()
//        self.init()
//        scnView = view
//    }
    

    func setDepthValue(bitmapImageRep:NSBitmapImageRep,view:SCNView,idDictionary:Dictionary<Int, Int>)
    {
        depthPointCloud = []
        depthVertexArray = []
        var maxminXY : [String:Float] = ["maxX": -100,"minX": 100,"maxY": -100,"minY": 100]
        if aroundMarkerOnly == false
        {
            for var x in stride(from: 0, to: depthValueArray.count, by: downSample)
                //for var x in 0..<depthValueArray.count
            {
                for var y in stride(from: 0, to: depthValueArray[x].count, by: downSample)
                    //for var y in 0..<depthValueArray[x].count
                {
                    depthValueArray[x][y] = bitmapImageRep.colorAt(x: x, y: y)!.whiteComponent
                    if(depthValueArray[x][y] != 0)
                    //if(true)
                    {
                        for var stepX in 0..<downSample
                        {
                            for var stepY in 0..<downSample
                            {
                                let unprojectPointVector = view.unprojectPoint(SCNVector3(CGFloat(x+stepX),CGFloat(y+stepY),depthValueArray[x][y]))
                                //depthVertexArray.append(PointCloudVertex(x: Float(unprojectPointVector.x), y: -Float(unprojectPointVector.y), z: Float(unprojectPointVector.z), r: Float(arc4random()) / Float(UINT32_MAX), g: Float(arc4random()) / Float(UINT32_MAX), b: Float(arc4random()) / Float(UINT32_MAX)))
                                depthVertexArray.append(PointCloudVertex(x: Float(unprojectPointVector.x), y: -Float(unprojectPointVector.y), z: Float(unprojectPointVector.z), r: Float(depthValueArray[x][y]), g: Float(depthValueArray[x][y]), b: Float(depthValueArray[x][y])))
                                depthPointCloud.append(unprojectPointVector)
                                if Float(unprojectPointVector.x) > maxminXY["maxX"]!
                                {
                                    maxminXY["maxX"] = Float(unprojectPointVector.x)
                                }
                                else if Float(unprojectPointVector.x) < maxminXY["minX"]!
                                {
                                    maxminXY["minX"] = Float(unprojectPointVector.x)
                                }
                                if Float(unprojectPointVector.y) > maxminXY["maxY"]!
                                {
                                    maxminXY["maxY"] = Float(unprojectPointVector.y)
                                }
                                else if Float(unprojectPointVector.y) < maxminXY["minY"]!
                                {
                                    maxminXY["minY"] = Float(unprojectPointVector.y)
                                }
                            }
                        }
                    }
                }
            }
            
        }
        else if aroundMarkerOnly
        {
            //print(view.scene?.rootNode.childNode(withName:"markerObjectNode", recursively: true)?.childNodes.count)
            //print(idDictionary)
            var markerIDstring = Array<String>()
            for var id in idDictionary
            {
                for var i in 0..<id.value
                {
                    markerIDstring.append("\(id.key)-\(i)")
                }
            }
            //for var markerName in markerIDstring
            
            for node in (view.scene?.rootNode.childNode(withName: "markerObjectNode", recursively: true)?.childNodes)!
            {
                highlightNode(node)
                var nodeBoundingSize = calNodeSize(node: node, view: view)
//                var PFVnode = view.scene?.rootNode.childNode(withName: "planeFromView", recursively: false)
//                PFVnode?.position = view.unprojectPoint(SCNVector3(Double(nodeBoundingSize.minX),Double(nodeBoundingSize.minY),0.23838415145874))
                var x = nodeBoundingSize.minX
                var maxminXY : [String:Float] = ["maxX": -100,"minX": 100,"maxY": -100,"minY": 100]
                while x < nodeBoundingSize.maxX
                {
                    var y = nodeBoundingSize.minY
                    while y < nodeBoundingSize.maxY
                    {
                        var convertY = 479-y
                        let whiteValue = bitmapImageRep.colorAt(x: x, y: convertY)!.whiteComponent
                                                //depthValueArray[x][y] = bitmapImageRep.colorAt(x: x, y: y)!.whiteComponent
                        if(whiteValue != 0)
                        {
                            for stepX in 0..<downSample
                            {
                                for stepY in 0..<downSample
                                {
                                    let unprojectPointVector = view.unprojectPoint(SCNVector3(CGFloat(x+stepX),CGFloat(y+stepY),whiteValue))
                                    depthVertexArray.append(PointCloudVertex(x: Float(unprojectPointVector.x), y: Float(unprojectPointVector.y), z: Float(unprojectPointVector.z), r: Float.randColor(), g: Float.randColor(), b: Float.randColor()))
                                    if Float(unprojectPointVector.x) > maxminXY["maxX"]!
                                    {
                                        maxminXY["maxX"] = Float(unprojectPointVector.x)
                                    }
                                    else if Float(unprojectPointVector.x) < maxminXY["minX"]!
                                    {
                                        maxminXY["minX"] = Float(unprojectPointVector.y)
                                    }
                                    if Float(unprojectPointVector.y) > maxminXY["maxY"]!
                                    {
                                        maxminXY["maxY"] = Float(unprojectPointVector.y)
                                    }
                                    else if Float(unprojectPointVector.y) < maxminXY["minY"]!
                                    {
                                        maxminXY["minY"] = Float(unprojectPointVector.y)
                                    }
                                    //depthVertexArray.append(PointCloudVertex(x: Float(unprojectPointVector.x), y: Float(unprojectPointVector.y), z: Float(unprojectPointVector.z), r: Float(depthValueArray[x][y]), g: Float(depthValueArray[x][y]), b: Float(depthValueArray[x][y])))
                                    //depthPointCloud.append(unprojectPointVector)
                                }
                            }
                            
                        }
                        y += downSample
                    }
                    x += downSample
                    //print(maxminXY)
                }
                //print("depth node point count is : \(depthValueArray.count)")
//                for var x in stride(from: test.minX,to: test.maxX, by: downSample)
//                {
//                    for var y in stride(from: test.minY,to: test.maxY, by: downSample)
//                    {
//                        let whiteValue = bitmapImageRep.colorAt(x: x, y: y)!.whiteComponent
//                        //depthValueArray[x][y] = bitmapImageRep.colorAt(x: x, y: y)!.whiteComponent
//                        if(whiteValue != 0)
//                        {
//                            let unprojectPointVector = view.unprojectPoint(SCNVector3(CGFloat(x),CGFloat(y),whiteValue))
//                            depthVertexArray.append(PointCloudVertex(x: Float(unprojectPointVector.x), y: -Float(unprojectPointVector.y), z: Float(unprojectPointVector.z), r: Float(arc4random()) / Float(UINT32_MAX), g: Float(arc4random()) / Float(UINT32_MAX), b: Float(arc4random()) / Float(UINT32_MAX)))
//                            //depthVertexArray.append(PointCloudVertex(x: Float(unprojectPointVector.x), y: -Float(unprojectPointVector.y), z: Float(unprojectPointVector.z), r: 1.0, g: 0, b: 0))
//                            //depthPointCloud.append(unprojectPointVector)
//                        }
//                    }
//                }
                
            }
            
        }
    }
    public func refresh()
    {
            getNode()
        //print(self.geometry?.firstMaterial?.diffuse)
        
    }
    public func getNode() -> SCNNode
    {
        var vertices = depthVertexArray
        
        let node = buildNode(points: vertices)
        node.renderingOrder = -1
        
        node.name = "pcNode" 
        return node
    }
    private func buildNode(points: [PointCloudVertex]) -> SCNNode {
        let vertexData = NSData(
            bytes: points,
            length: MemoryLayout<PointCloudVertex>.size * points.count
        )
        let positionSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.vertex,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: 0,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let colorSource = SCNGeometrySource(
            data: vertexData as Data,
            semantic: SCNGeometrySource.Semantic.color,
            vectorCount: points.count,
            usesFloatComponents: true,
            componentsPerVector: 3,
            bytesPerComponent: MemoryLayout<Float>.size,
            dataOffset: MemoryLayout<Float>.size * 3,
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let elements = SCNGeometryElement(
            data: nil,
            primitiveType: .point,
            primitiveCount: points.count,
            bytesPerIndex: MemoryLayout<Int>.size
            //pPointSize : 5
        )
        let pointsGeometry = SCNGeometry(sources: [positionSource,colorSource], elements: [elements])
        //pointsGeometry.firstMaterial?.diffuse.contents = NSColor.yellow
        //pointsGeometry.firstMaterial?.emission.contents = NSColor.yellow
        if #available(OSX 10.13, *) {
//            pointsGeometry.firstMaterial?.transparencyMode = .dualLayer
//            pointsGeometry.firstMaterial?.blendMode = .replace
            let dict: [SCNShaderModifierEntryPoint:String] = [.fragment : //改變顏色
                "_output.color = vec4( 0.5, 0.0, 0.5, 1.0 );"]
            pointsGeometry.shaderModifiers = dict
            if coloredMask
            {
                //pointsGeometry.firstMaterial?.colorBufferWriteMask = SCNColorMask(rawValue: 0)
            }
        } else {
            // Fallback on earlier versions
        }
        self.geometry = pointsGeometry
        return SCNNode(geometry: pointsGeometry)
    }
    private func maskAroundMarker()
    {
        
    }
}
extension DepthMask2D
{
    func calNodeSize(node:SCNNode,view:SCNView) -> nodePos
    {
        let (localMin,localMax) = node.boundingBox
        let min = node.convertPosition(localMin, to: nil)
        let max = node.convertPosition(localMax, to: nil)
        let midZ = (min.z + max.z) / 2
        let vertices = [
            SCNVector3(min.x, min.y, min.z), //4min 4max
            SCNVector3(max.x, min.y, min.z),
            SCNVector3(min.x, max.y, min.z),
            SCNVector3(max.x, max.y, min.z),
            SCNVector3(min.x, min.y, max.z),
            SCNVector3(max.x, min.y, max.z),
            SCNVector3(min.x, max.y, max.z),
            SCNVector3(max.x, max.y, max.z)
        ]
        let arr = vertices.map { view.projectPoint($0) }
        
        var minX: CGFloat = arr.reduce(CGFloat.infinity, { $0 > $1.x ? $1.x : $0 })
        var minY: CGFloat = arr.reduce(CGFloat.infinity, { $0 > $1.y ? $1.y : $0 })
        //let minZ: CGFloat = arr.reduce(CGFloat.infinity, { $0 > $1.z ? $1.z : $0 })
        var maxX: CGFloat = arr.reduce(-CGFloat.infinity, { $0 < $1.x ? $1.x : $0 })
        var maxY: CGFloat = arr.reduce(-CGFloat.infinity, { $0 < $1.y ? $1.y : $0 })
        //let maxZ: CGFloat = arr.reduce(-CGFloat.infinity, { $0 < $1.z ? $1.z : $0 })
        
        let width = maxX - minX
        let height = maxY - minY
        let meanX = (maxX+minX)/2
        let meanY = (maxY+minY)/2
        let length = ([width,height].max())!/2
        minX = meanX-length
        maxX = meanX+length
        minY = meanY-length
        maxY = meanY+length
        if minX < 0
        {
            minX = 0
        }
        if minY < 0
        {
            minY = 0
        }
        if maxX > 640
        {
            maxX = 640
        }
        if maxY > 480
        {
            maxY = 480
        }
        return nodePos(minX : Int(minX), minY : Int(minY), maxX: Int(maxX), maxY: Int(maxY))
    }
    
    func createLineNode(fromPos origin: SCNVector3, toPos destination: SCNVector3, color: NSColor) -> SCNNode {
        let line = lineFrom(vector: origin, toVector: destination)
        let lineNode = SCNNode(geometry: line)
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = color
        line.materials = [planeMaterial]
        
        return lineNode
    }
    
    func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
    }
    
    
    func highlightNode(_ node: SCNNode) -> [[CGFloat]] {
        let (min, max) = node.boundingBox
        let boundingArray = [min,max]
        var pointArray = Array<SCNVector3>()
        var minmaxXY : [[CGFloat]] = [[640,480],[0,0]]
        for var i in 0..<2
        {
            for var j in 0..<2
            {
                for var k in 0..<2
                {
                    pointArray.append(SCNVector3(boundingArray[i].x,boundingArray[j].y,boundingArray[k].z))
                }
            }
        }
        
        for var point in pointArray
        {
            
            let TwoDpoint = scnView.projectPoint(point)
            if TwoDpoint.x < minmaxXY[0][0]
            {
                minmaxXY[0][0] = TwoDpoint.x
            }
            if TwoDpoint.x > minmaxXY[1][0]
            {
                minmaxXY[1][0] = TwoDpoint.x
            }
            if TwoDpoint.y < minmaxXY[0][1]
            {
                minmaxXY[0][1] = TwoDpoint.y
            }
            if TwoDpoint.y > minmaxXY[1][1]
            {
                minmaxXY[1][1] = TwoDpoint.y
            }
        }
        if minmaxXY[0][0] < 0
        {
            minmaxXY[0][0] = 0
        }
        if minmaxXY[0][1] < 0
        {
            minmaxXY[0][1] = 0
        }
        if minmaxXY[1][0] > 639
        {
            minmaxXY[1][0] = 639
        }
        if minmaxXY[1][1] > 479
        {
            minmaxXY[1][1] = 479
        }
//        print("pointArray : \(pointArray)")
//        print("minaxXY : \(minmaxXY)")
        let zCoord = node.position.z
        
        let topLeft = SCNVector3Make(min.x, max.y, max.z)
        let bottomLeft = SCNVector3Make(min.x, min.y, min.z)
        let topRight = SCNVector3Make(max.x, max.y, max.z)
        let bottomRight = SCNVector3Make(max.x, min.y, min.z)
        
        
        let bottomSide = createLineNode(fromPos: bottomLeft, toPos: bottomRight, color: .red)
        let leftSide = createLineNode(fromPos: bottomLeft, toPos: topLeft, color: .orange )
        let rightSide = createLineNode(fromPos: bottomRight, toPos: topRight, color: .yellow)
        let topSide = createLineNode(fromPos: topLeft, toPos: topRight, color: .green)
        
        [bottomSide, leftSide, rightSide, topSide].forEach {
            $0.name = "123" // Whatever name you want so you can unhighlight later if needed
            node.addChildNode($0)
        }
        return minmaxXY
    }
    
    func unhighlightNode(_ node: SCNNode) {
        let highlightningNodes = node.childNodes { (child, stop) -> Bool in
            child.name == "123"
        }
        highlightningNodes.forEach {
            $0.removeFromParentNode()
        }
    }
}

extension Float
{
    static func randColor() -> Float
    {
        return (Float(arc4random()) / Float(UINT32_MAX))
    }
}
