//
//  Shaders.metal
//  RealityKitPostProcessing
//
//  Created by Dennis Ippel on 26/09/2021.
//

#include <metal_stdlib>
using namespace metal;

[[kernel]]
void inverseColorKernel(texture2d<float, access::read> sourceTexture [[texture(0)]],
                        texture2d<float, access::write> targetTexture [[texture(1)]],
                        uint2 gridPosition [[thread_position_in_grid]])
{
    float4 sourceColor = sourceTexture.read(gridPosition);
    float4 inverseColor = float4(1.0 - sourceColor.rgb, sourceColor.a);

    targetTexture.write(inverseColor, gridPosition);
}
