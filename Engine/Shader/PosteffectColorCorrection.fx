#include FullscreenQuadHeader.fx

cbuffer local : register(b1)
{
  float shadows, midtones, lights;
};

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  float3 scene_color = tex2D(ColorTextureSampler,psin.Tex).rgb;
  // rescale linear color scale
  scene_color = saturate((scene_color - shadows) / lights);
  // gamma correct
  scene_color = pow(scene_color, midtones);
  pso.Color = float4(scene_color, 1.0);
  return pso;
}

#include FullscreenQuadFooter.fx