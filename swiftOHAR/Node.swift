//
//  Node.swift
//  metalBasic
//
//  Created by Tom Cruise on 2017/11/22.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

import Foundation
import Metal
import QuartzCore

class Node
{
    let device: MTLDevice
    let name : String
    var vertexCount : Int
    var vertexBuffer : MTLBuffer
    var doTimes : Float = 0.0;
    init(name : String, vertices: Array<Vertex>, device: MTLDevice)
    {
        var vertexData = Array<Float>()
        for vertex in vertices
        {
            vertexData += vertex.floatBuffer()
        }
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
        
        self.name = name
        self.device = device
        vertexCount = vertices.count
        
    }
    func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState, drawable: CAMetalDrawable, clearColor: MTLClearColor?){
        changevertexBuffer()
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor =
            MTLClearColor(red: 0.0, green: 104.0/255.0, blue: 5.0/255.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: vertexCount,
                                     instanceCount: vertexCount/3)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    func changevertexBuffer()
    {
        
        let V0 = Vertex(x:  0.0, y:   0.3+(0.05*doTimes), z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0)
        
        let V1 = Vertex(x: -0.3+(0.05*doTimes), y:  -0.3, z:   0.0, r:  0.0, g:  1.0, b:  0.0, a:  1.0)
        let V2 = Vertex(x:  0.3, y:  -0.3, z:   0.0, r:  0.0, g:  0.0, b:  1.0, a:  1.0)
        doTimes += 1
        let verticesArray = [V0,V1,V2]
        
        var vertexData = Array<Float>()
        for vertex in verticesArray
        {
            vertexData += vertex.floatBuffer()
        }
        
        let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])
        
        vertexCount = verticesArray.count
    }
}
