#include FullscreenQuadHeader.fx

cbuffer local : register(b1)
{
  float4 fog_color;
  float start_range, range;
};

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color.rgb = fog_color.rgb;
  float scene_depth = tex2D(ColorTextureSampler,psin.Tex).a;
  // linear fog
  float fog_factor = saturate((scene_depth - start_range) / range);
  // fully fog background
  pso.Color.a = saturate(fog_factor + 1 - tex2D(NormalTextureSampler,psin.Tex).a);
  return pso;
}

#include FullscreenQuadFooter.fx