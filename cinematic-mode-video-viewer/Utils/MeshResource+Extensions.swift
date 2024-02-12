//
//  MeshResource+Extensions.swift
//  cinematic-mode-video-viewer
//
//  Created by fuziki on 2024/02/12.
//

import Foundation
import RealityKit

extension MeshResource {
    static func generatePlane(width: Float, height: Float, segmentWidth: Int, segmentHeight: Int) -> MeshResource {
        var vertices: [SIMD3<Float>] = []
        var uv: [SIMD2<Float>] = []
        for i in 0...segmentHeight {
            for j in 0...segmentWidth {
                vertices.append(.init(x: (Float(j) / Float(segmentWidth) - 0.5) * width,
                                      y: (Float(i) / Float(segmentHeight) - 0.5) * height,
                                      z: 0))
                uv.append(.init(x: Float(j) / Float(segmentWidth), y: Float(i) / Float(segmentHeight)))
            }
        }

        var triangles: [UInt32] = []
        for i in 0..<segmentHeight {
            for j in 0..<segmentWidth {
                let index = UInt32(i * (segmentWidth + 1) + j)
                triangles += [
                    index, index + 1, index + UInt32(segmentWidth) + 1,
                    index + UInt32(segmentWidth) + 1, index + 1, index + UInt32(segmentWidth) + 2
                ]
            }
        }

        var desc = MeshDescriptor()
        desc.positions = MeshBuffer(vertices)
        desc.textureCoordinates = MeshBuffers.TextureCoordinates(uv)
        desc.primitives = .triangles(triangles)
        return try! .generate(from: [desc])
    }
}
