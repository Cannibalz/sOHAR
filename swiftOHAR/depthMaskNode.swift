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
struct depthWindow {
    var minX: Int
    var minY: Int
    var maxX: Int
    var maxY: Int
    var needsConvert : Bool
    func getY(Y:Int)->Int
    {
        if needsConvert
        {
            return 479-Y
        }
        else
        {
            return Y
        }
    }
}
class DepthMask2D : SCNNode
{
    static let sharedInstance = DepthMask2D()
    
    var depthValueArray : [[CGFloat]] = Array(repeating: Array(repeating: 0, count: 480), count: 640)
    var depthPointCloud : [SCNVector3] = Array()
    var depthVertexArray : [PointCloudVertex] = Array()
//    var pcNode : SCNNode = SCNNode()
    var downSample = 2
    var aroundMarkerOnly = true
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
    init(scnView: SCNView,downSample:Int,aroundMarkerOnly:Bool)
    {
        super.init()
        self.name = "depthMask"
        self.renderingOrder = -100
        self.scnView = scnView
        self.downSample = downSample
        self.aroundMarkerOnly = aroundMarkerOnly
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func setDepthValue(bitmapImageRep:NSBitmapImageRep,view:SCNView,idDictionary:Dictionary<Int, Int>)
    {
        depthPointCloud = []
        depthVertexArray = []
        var measureRangeArray = Array<depthWindow>()
        if aroundMarkerOnly == false
        {
            //all pixel in image
            measureRangeArray.append(depthWindow(minX: 0, minY: 0, maxX: depthValueArray.count, maxY: depthValueArray[0].count, needsConvert: false))
        }
        else if aroundMarkerOnly
        {
            //lony pixel around object
            for node in (view.scene?.rootNode.childNode(withName: "markerObjectNode", recursively: true)?.childNodes)!
            {
                let nodeBoundingSize = calNodeSize(node: node, view: view)
                measureRangeArray.append(depthWindow(minX: nodeBoundingSize.minX, minY: nodeBoundingSize.minY, maxX: nodeBoundingSize.maxX, maxY: nodeBoundingSize.maxY, needsConvert: true))
            }
        }
        for measureRange in measureRangeArray
        {
            for var x in stride(from: measureRange.minX, to: measureRange.maxX, by: downSample)
            {
                for var y in stride(from: measureRange.minY, to: measureRange.maxY, by: downSample)
                {
                    let cvrtY = measureRange.getY(Y: y)
                    let whiteValue = bitmapImageRep.colorAt(x: x, y: cvrtY)!.whiteComponent
                    if whiteValue != 0
                    {
                        for stepX in 0..<downSample
                        {
                            for stepY in 0..<downSample
                            {
                                let unprojectPointVector = view.unprojectPoint(SCNVector3(CGFloat(x+stepX),CGFloat(y+stepY),whiteValue))
                                depthVertexArray.append(PointCloudVertex(x: Float(unprojectPointVector.x), y: Float(unprojectPointVector.y), z: Float(unprojectPointVector.z), r: Float.randColor(), g: Float.randColor(), b: Float.randColor()))
                            }
                        }
                    }
                }
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
