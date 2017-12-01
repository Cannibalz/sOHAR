//
//  depthMask.swift
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/11/29.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

import Foundation
import SceneKit

class DepthMask2D
{
    var depthValueArray : [[CGFloat]] = Array(repeating: Array(repeating: 0, count: 480), count: 640)
    var depthPointCloud : [SCNVector3] = Array()
    var pcNode : SCNNode = SCNNode()
    //var valueArray : [[NSColor]] = Array(repeating: Array(repeating: 0, count: 480), count: 640)
    init() {
        print(depthValueArray[0].count)
    }
    func setDepthValue(data:[[Int]])
    {
        
    }
    func setDepthValue(bitmapImageRep:NSBitmapImageRep,view:SCNView)
    {
        depthPointCloud = []
        for var x in stride(from: 0, to: depthValueArray.count, by: 2)
        //for var x in 0..<depthValueArray.count
        {
            for var y in stride(from: 0, to: depthValueArray[x].count, by: 2)
            //for var y in 0..<depthValueArray[x].count
            {
                depthValueArray[x][y] = bitmapImageRep.colorAt(x: x, y: y)!.whiteComponent
                if(depthValueArray[x][y] != 0)
                {
                    depthPointCloud.append(view.unprojectPoint(SCNVector3(CGFloat(x),CGFloat(y),depthValueArray[x][y])))
                }
            }
        }
    }
    public func getNode() -> SCNNode
    {
        let points = self.depthPointCloud
        var vertices = Array(repeating: PointCloudVertex(x: 0,y: 0,z: 0,r: 0,g: 0,b: 0), count: points.count)
        
        for i in 0...(points.count-1) {
            let p = points[i]
            vertices[i].x = Float(p.x)
            vertices[i].y = -Float(p.y)
            vertices[i].z = Float(p.z)
            vertices[i].r = Float(0.0)
            vertices[i].g = Float(1.0)
            vertices[i].b = Float(1.0)
        }
        
        let node = buildNode(points: vertices)
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
            dataOffset: MemoryLayout<Float>.size * 3,//往後三格取顏色
            dataStride: MemoryLayout<PointCloudVertex>.size
        )
        let elements = SCNGeometryElement(
            data: nil,
            primitiveType: .point,
            primitiveCount: points.count,
            bytesPerIndex: MemoryLayout<Int>.size
        )
        let pointsGeometry = SCNGeometry(sources: [positionSource, colorSource], elements: [elements])
        if #available(OSX 10.13, *) {
            pointsGeometry.firstMaterial?.colorBufferWriteMask = SCNColorMask(rawValue: 0)
        } else {
            // Fallback on earlier versions
        }
        return SCNNode(geometry: pointsGeometry)
    }
//    private func buildNode() -> SCNNode {
//        let vertexData = NSData(
//            bytes: depthPointCloud,
//            length: MemoryLayout<SCNVector3>.size * depthPointCloud.count
//        )
//        let positionSource = SCNGeometrySource(
//            data: vertexData as Data,
//            semantic: SCNGeometrySource.Semantic.vertex,
//            vectorCount: depthPointCloud.count,
//            usesFloatComponents: true,
//            componentsPerVector: 3,
//            bytesPerComponent: MemoryLayout<Float>.size,
//            dataOffset: 0,
//            dataStride: MemoryLayout<SCNVector3>.size
//        )
//        let colorSource = SCNGeometrySource(
//            data: vertexData as Data,
//            semantic: SCNGeometrySource.Semantic.color,
//            vectorCount: depthPointCloud.count,
//            usesFloatComponents: true,
//            componentsPerVector: 3,
//            bytesPerComponent: MemoryLayout<Float>.size,
//            dataOffset: MemoryLayout<Float>.size * 3,
//            dataStride: MemoryLayout<SCNVector3>.size
//        )
//        let elements = SCNGeometryElement(
//            data: nil,
//            primitiveType: .point,
//            primitiveCount: depthPointCloud.count,
//            bytesPerIndex: MemoryLayout<Int>.size
//        )
//        //let pointsGeometry = SCNGeometry(sources: [positionSource, colorSource], elements: [elements])
//        let pointsGeometry = SCNGeometry(sources: [positionSource], elements: [elements])
//        return SCNNode(geometry: pointsGeometry)
//    }
}
