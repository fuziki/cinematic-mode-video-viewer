//
//  custom_material.metal
//  cinematic-mode-video-viewer
//
//  Created by fuziki on 2024/02/12.
//

#include <metal_stdlib>
#include <RealityKit/RealityKit.h>
using namespace metal;

constexpr sampler textureSampler(address::clamp_to_edge, filter::bicubic);

[[visible]]
void geometry(realitykit::geometry_parameters params)
{
    auto uv = params.geometry().uv0();
    uv.y = 1.0 - uv.y;
    float scale = 10;
    auto d = params.textures().custom().sample(textureSampler, uv).r * scale;
    params.geometry().set_model_position_offset(float3(0, 0, d - 1));
}

[[visible]]
void surface(realitykit::surface_parameters params)
{
    float2 uv = params.geometry().uv0();
    uv.y = 1.0 - uv.y;
    half3 c = params.textures().base_color().sample(textureSampler, uv).rgb;
    params.surface().set_base_color(c);

    float scale = 10;
    auto d = params.textures().custom().sample(textureSampler, uv).r * scale;
    auto d1 = params.textures().custom().sample(textureSampler, float2(uv.x + 2.0 / 320.0, uv.y)).r * scale;
    auto d2 = params.textures().custom().sample(textureSampler, float2(uv.x - 2.0 / 320.0, uv.y)).r * scale;
    auto d3 = params.textures().custom().sample(textureSampler, float2(uv.x, uv.y + 2.0 / 180.0)).r * scale;
    auto d4 = params.textures().custom().sample(textureSampler, float2(uv.x, uv.y - 2.0 / 180.0)).r * scale;
    float t = 0.1;
    bool f = abs(d - d1) < t && abs(d - d2) < t && abs(d - d3) < t && abs(d - d4) < t;
    params.surface().set_opacity(f ? 1 : 0);
}
