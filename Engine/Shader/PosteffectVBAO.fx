#include FullscreenQuadHeader.fx

cbuffer local : register(b1) {
  float range, width, height, JumpMax;
  float4x4 ViewProjection;
  float4 Kernel[KERNELSIZE];
};

#define BIAS 0.1
#define EPSILON 0.000001

PSOutput MegaPixelShader(VSOutput psin) {
  PSOutput pso;
  float occlusion = 0.0;
  float4 normalDepth = tex2D(NormalTextureSampler, psin.Tex);
  normalDepth.xyz = normalize(normalDepth.xyz);
  clip(normalDepth.w - 0.01);
  float4 position = float4(tex2D(ColorTextureSampler, psin.Tex).rgb, 1);
  position.xyz += normalDepth.xyz * (range / 2.0);
  normalDepth.w = distance(position.xyz, CameraPosition);
  position = mul(ViewProjection, position);
  position.xy /= position.w;
  position.xy = position.xy * float2(0.5, -0.5) + 0.5;
  float3 noise = tex2D(VariableTexture2Sampler, psin.Tex * float2(width, height)).rgb;
  float normalization = EPSILON;
  for (int i = 0; i < KERNELSIZE; ++i) {
    float4 sampleCoord = mul(Projection, float4(Kernel[i].xy, normalDepth.w, 1));
    sampleCoord.xy /= sampleCoord.w;
    sampleCoord.xy = float2(sampleCoord.x * noise.x - sampleCoord.y * noise.y, sampleCoord.x * noise.y + sampleCoord.y * noise.x) + position.xy;
    float sampleZ = tex2D(NormalTextureSampler, sampleCoord.xy).a;
    // background is 0.0 but must be infinite far away
    sampleZ = (sampleZ <= 0.0) ? 1000.0 : sampleZ;
    float zEntry = normalDepth.w - Kernel[i].z;
    float deltaZ = sampleZ - zEntry;
    float range_check = ((deltaZ <= 0) ? saturate(1 + deltaZ / range) : 1.0);
    deltaZ = clamp(deltaZ, 0, 2.0 * Kernel[i].z);
    occlusion += deltaZ;
    normalization += Kernel[i].z * 2.0 * range_check;
  }
  pso.Color.rgb = ((occlusion / normalization * (1 + BIAS))) + (normalization <= EPSILON ? 1.0 : 0.0);
  pso.Color.a = 1.0;
  return pso;
}

#include FullscreenQuadFooter.fx
