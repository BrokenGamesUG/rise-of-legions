#include FullscreenQuadHeader.fx

cbuffer local : register(b1)
{
  float amount;
};

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color.a = 1;
  float3 scene = tex2D(ColorTextureSampler, psin.Tex).rgb;
  float3 blurred_scene = tex2D(NormalTextureSampler, psin.Tex).rgb;
  float3 difference = scene - blurred_scene;
  // add the differences between blurred scene and scene to highlight edges with
  // contrast overshooting
  pso.Color.rgb = scene + difference * amount;
  return pso;
}

#include FullscreenQuadFooter.fx
