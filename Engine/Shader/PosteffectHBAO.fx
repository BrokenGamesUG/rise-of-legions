#include FullscreenQuadHeader.fx

cbuffer local : register(b1)
{
  float range,width,height,JumpMax;
  float4x4 ViewProjection;
  float4 Kernel[KERNELSIZE];
};

#define BIAS 0.3

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  float urbackground = tex2D(VariableTexture1Sampler,psin.Tex).a;
  clip(urbackground-0.5);
  float endocclusion = 0.0;
  float4 normalDepth = tex2D(NormalTextureSampler,psin.Tex);
  float3 noise = tex2D(VariableTexture2Sampler,psin.Tex*float2(width,height)).rgb;
  float3 position = tex2D(ColorTextureSampler,psin.Tex).rgb;
  for(int i=0;i<KERNELSIZE;++i){
    float2 direction = Kernel[i].xy/normalDepth.w;
    direction = float2(direction.x*noise.x-direction.y*noise.y,direction.x*noise.y+direction.y*noise.x)*noise.z;
    float2 offset = 0;
    float occlusion = BIAS;
    for(int j=0;j<SAMPLES;++j){
      offset += direction;
      float3 samplePosition = tex2D(ColorTextureSampler,psin.Tex+offset).rgb;
      float3 sampleDir = (samplePosition-position);
      float rayLength = length(sampleDir);
      float range_check = rayLength < range ? 1.0 : 0.0;
      occlusion = max(occlusion,dot((sampleDir/rayLength),normalDepth.xyz)*range_check);
    }
    endocclusion+=(occlusion-BIAS)/(1-BIAS);
  }
  pso.Color.rgb = 1-(endocclusion/(KERNELSIZE/2));
  pso.Color.a = 1.0;
  return pso;
}

#include FullscreenQuadFooter.fx
