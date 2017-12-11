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
        self.renderingOrder = -10
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
                    {
                        let unprojectPointVector = view.unprojectPoint(SCNVector3(CGFloat(x),CGFloat(y),depthValueArray[x][y]))
                        depthVertexArray.append(PointCloudVertex(x: Float(unprojectPointVector.x), y: -Float(unprojectPointVector.y), z: Float(unprojectPointVector.z), r: Float(arc4random()) / Float(UINT32_MAX), g: Float(arc4random()) / Float(UINT32_MAX), b: Float(arc4random()) / Float(UINT32_MAX)))
                        //depthVertexArray.append(PointCloudVertex(x: Float(unprojectPointVector.x), y: -Float(unprojectPointVector.y), z: Float(unprojectPointVector.z), r: 1.0, g: 0, b: 0))
                        depthPointCloud.append(unprojectPointVector)
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
                //print(view.scene?.rootNode.childNode(withName:"markerObjectNode", recursively: true)?.childNodes[i].name)
                //let boundingBoxRange = view.scene?.rootNode.childNode(withName: "planeFromView", recursively: false)?.boundingBox
                print("MaxIn3D:\(node.boundingBox.max)")
                print("MinIn3D:\(node.boundingBox.min)")
                let nodeMax2D = view.projectPoint(node.boundingBox.max)
                let nodeMin2D = view.projectPoint(node.boundingBox.min)
                print("MaxIn2D:\(nodeMax2D)")
                print("MInIn2D:\(nodeMin2D)")
                print("unPorjectMax:\(view.unprojectPoint(nodeMax2D))")
                print("unPorjectMin:\(view.unprojectPoint(nodeMin2D))")
                //var minmaxXY = highlightNode(node)
                var test = calNodeSize(node: node, view: view)
                //createLineNode(fromPos: node.boundingBox.min, toPos: node.boundingBox.max, color: .yellow)
//                var projectPointBBRmax = view.projectPoint((boundingBoxRange?.max)!)
//                var projectPointBBRmin = view.projectPoint((boundingBoxRange?.min)!)
//                if projectPointBBRmax.x > 640
//                {
//                    projectPointBBRmax.x = 640
//                }
//                if projectPointBBRmin.y > 480
//                {
//                    projectPointBBRmax.y = 480
//                }
                var x = test.minX
                while x < test.maxX
                {
                    var y = test.minY
                    while y < test.maxY
                    {
                        let whiteValue = bitmapImageRep.colorAt(x: x, y: y)!.whiteComponent
                                                //depthValueArray[x][y] = bitmapImageRep.colorAt(x: x, y: y)!.whiteComponent
                        if(whiteValue != 0)
                        {
                            let unprojectPointVector = view.unprojectPoint(SCNVector3(CGFloat(x),CGFloat(y),whiteValue))
                            //depthVertexArray.append(PointCloudVertex(x: Float(unprojectPointVector.x), y: Float(unprojectPointVector.y), z: Float(unprojectPointVector.z), r: Float(arc4random()) / Float(UINT32_MAX), g: Float(arc4random()) / Float(UINT32_MAX), b: Float(arc4random()) / Float(UINT32_MAX)))
                            depthVertexArray.append(PointCloudVertex(x: Float(unprojectPointVector.x), y: Float(unprojectPointVector.y), z: Float(unprojectPointVector.z), r: 1.0, g: 0, b: 0))
                            //depthPointCloud.append(unprojectPointVector)
                        }
                        y += downSample
                    }
                    x += downSample
                }
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
        //let points = self.depthPointCloud
        //var vertices = Array(repeating: PointCloudVertex(x: 0,y: 0,z: 0,r: 0,g: 0,b: 0), count: points.count)
        var vertices = depthVertexArray
        
//        for i in 0..<(points.count) {
//            let p = points[i]
//            vertices[i].x = Float(p.x)
//            vertices[i].y = -Float(p.y)
//            vertices[i].z = Float(p.z)
//            vertices[i].r = Float(0)
//            vertices[i].g = Float(p.z)
//            vertices[i].b = Float(0)
//        }
        
        let node = buildNode(points: vertices)
        //node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
//        node.physicsBody?.categoryBitMask = CollisionTypes.realDepth.rawValue
//        node.physicsBody?.collisionBitMask = CollisionTypes.object.rawValue
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
        )
        let pointsGeometry = SCNGeometry(sources: [positionSource,colorSource], elements: [elements])
        //pointsGeometry.firstMaterial?.isDoubleSided = true
//        pointsGeometry.firstMaterial?.transparency = 1

        //pointsGeometry.firstMaterial?.diffuse.contents = NSColor.white.withAlphaComponent(1)//NSImage(named: "MKY.jpg")
        //pointsGeometry.firstMaterial?.lightingModel = .lambert
        //pointsGeometry.firstMaterial?.shaderModifiers = [SCNShaderModifierEntryPoint.geometry : "PointSize = 1.0;"]
        //pointsGeometry.firstMaterial?.shaderModifiers = [SCNShaderModifierEntryPoint.fragment : "_output.color.rgb = vec3(1.0) - _output.color.rgb;"]

        if #available(OSX 10.13, *) {
            
            if !coloredMask
            {
                pointsGeometry.firstMaterial?.colorBufferWriteMask = SCNColorMask(rawValue: 0)
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
                minmaxXY[0][1] = 0
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
//        print(pointArray)
//        print(minmaxXY)
        let zCoord = node.position.z
        
        let topLeft = SCNVector3Make(min.x, max.y, max.z)
        let bottomLeft = SCNVector3Make(min.x, min.y, min.z)
        let topRight = SCNVector3Make(max.x, max.y, max.z)
        let bottomRight = SCNVector3Make(max.x, min.y, min.z)
        print(scnView.projectPoint(topLeft))
        
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
    func calNodeSize(node:SCNNode,view:SCNView) -> nodePos
    {
        let (localMin,localMax) = node.boundingBox
        let min = node.convertPosition(localMin, to: nil)
        let max = node.convertPosition(localMax, to: nil)
        let vertices = [
            SCNVector3(min.x, min.y, min.z),
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
        return nodePos(minX: Int(minX), minY: Int(minY), maxX: Int(maxX), maxY: Int(maxY))
        //let depth = maxZ - minZ
    }
}
