//
//  MTKViewController.swift
//  swiftOHAR
//
//  Created by Tom Cruise on 2017/4/25.
//  Copyright © 2017年 Tom Cruise. All rights reserved.
//

import Foundation
import Metal
import MetalKit

struct Constants {
    var modelViewProjectionMatrix = matrix_identity_float4x4
    var normalMatrix = matrix_identity_float3x3
}

//class mtkVC : NSObject//, MTKViewDelegate
//{
//    weak var view: MTKView!
//
//    let device: MTLDevice
//    let commandQueue: MTLCommandQueue
//    let renderPipelineState: MTLRenderPipelineState
//    let depthStencilState: MTLDepthStencilState
//    let sampler: MTLSamplerState
//    let texture: MTLTexture
//    //let mesh: Mesh
//    var time = TimeInterval(0.0)
//    var constants = Constants()
//    
//    init?(mtkVIew: MTKView)
//    {
//        view = mtkVIew
//        view.sampleCount = 4
//        view.clearColor = MTLClearColorMake(1,1,1,1)
//        view.colorPixelFormat = .bgra8Unorm
//        view.depthStencilPixelFormat = .depth32Float
//        view.framebufferOnly = true
//        view.frame = (view.layer?.frame)!
//    }
//}

