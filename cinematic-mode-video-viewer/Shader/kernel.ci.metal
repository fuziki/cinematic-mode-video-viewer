//
//  kernel.ci.metal
//  cinematic-mode-video-viewer
//
//  Created by fuziki on 2024/02/12.
//

#include <metal_stdlib>
#include <CoreImage/CoreImage.h>

using namespace metal;

extern "C" {
    namespace coreimage {
        float4 grayscale(coreimage::sample_h i, coreimage::destination dest) {
            return float4(i.r * 0.1);
        }
    }
}
