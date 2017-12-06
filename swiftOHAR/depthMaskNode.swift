//
//  depthMask.swift
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/11/29.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

import Foundation
import SceneKit

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
    //var valueArray : [[NSColor]] = Array(repeating: Array(repeating: 0, count: 480), count: 640)
    override init() {
        super.init()
        self.name = "depthMask"
        self.renderingOrder = -10
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    func setDepthValue(bitmapImageRep:NSBitmapImageRep,view:SCNView)
    {
        depthPointCloud = []
        depthVertexArray = []
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
                    depthVertexArray.append(PointCloudVertex(x: Float(unprojectPointVector.x), y: -Float(unprojectPointVector.y), z: Float(unprojectPointVector.z), r: 0, g: 1, b: 1))
                    depthPointCloud.append(unprojectPointVector)
                }
            }
        }
    }
    public func refresh()
    {
        
            getNode()
        print(self.geometry?.firstMaterial?.diffuse)
        
    }
    public func getNode() -> SCNNode
    {
        let points = self.depthPointCloud
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
        node.opacity = 0
        
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
//        pointsGeometry.firstMaterial?.lightingModel = .constant
//        pointsGeometry.firstMaterial?.readsFromDepthBuffer = true
//        pointsGeometry.firstMaterial?.writesToDepthBuffer = true
        //pointsGeometry.firstMaterial?.diffuse.contents = NSColor.green
        
//        pointsGeometry.firstMaterial?.lightingModel = .constant
//        pointsGeometry.firstMaterial?.writesToDepthBuffer = true
        if #available(OSX 10.13, *) {
            pointsGeometry.firstMaterial?.blendMode = .replace
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
}
