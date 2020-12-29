#include FullscreenQuadHeader.fx

cbuffer local : register(b1) {
  float range, width, height, JumpMax;
  float4x4 ViewProjection;
  float4 Kernel[KERNELSIZE];
};

PSOutput MegaPixelShader(VSOutput psin) {
  PSOutput pso;
  float urbackground = tex2D(VariableTexture1Sampler, psin.Tex).a;
  clip(urbackground - 0.5);
  pso.Color.a = 1.0;

  float3 normal = normalize(tex2D(NormalTextureSampler, psin.Tex).rgb);
  float3 rvec = tex2D(VariableTexture2Sampler, psin.Tex * float2(width, height)).rgb;
  float3 tangent = normalize(rvec - normal * dot(rvec, normal));
  float3 bitangent = cross(normal, tangent);
  float3x3 tbn = float3x3(tangent, bitangent, normal);

  float count = 1.0;
  float occlusion = 0.0;
  float realZ, testZ, range_check;
  float3 samplePosition;
  float4 offset, sampleCoord;
  float4 position = float4(tex2D(ColorTextureSampler, psin.Tex).rgb, 1);
  for (int i = 0; i < KERNELSIZE; ++i) {
    offset = position + float4(mul(Kernel[i].xyz, tbn), 0);
    sampleCoord = mul(ViewProjection, offset);
    sampleCoord.xy /= sampleCoord.w;
    sampleCoord.xy = (sampleCoord.xy * float2(0.5, -0.5) + 0.5);
    sampleCoord.xy = sampleCoord.xy - psin.Tex;
    sampleCoord.xy /= clamp(length(sampleCoord.xy) / JumpMax, 1.0, 10000.0);
    sampleCoord.xy = sampleCoord.xy + psin.Tex;
    samplePosition = tex2D(ColorTextureSampler, sampleCoord.xy).rgb;
    realZ = length(samplePosition.xyz - CameraPosition);
    urbackground = tex2D(VariableTexture1Sampler, sampleCoord.xy).a;
    if (urbackground<0.5) realZ = 10000.0;
    // realZ = tex2D(NormalTextureSampler,sampleCoord.xy).a;
    testZ = length(offset.xyz - CameraPosition);
    range_check = abs(realZ - testZ) < range ? 1.0 : 0.0;
    occlusion += (realZ > testZ ? 0.0 : 1.0) * range_check;
    count += range_check;
  }
  pso.Color.rgb = 1.0 - ((occlusion / count));
  return pso;
}

#include FullscreenQuadFooter.fx
