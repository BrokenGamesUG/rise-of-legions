#include FullscreenQuadHeader.fx

cbuffer local : register(b1)
{
  float rangex, rangey;
};

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  float2 offset = (tex2D(NormalTextureSampler,psin.Tex).rg - 0.5) * 2;
  //clip(dot(offset, offset) - 0.01);
  pso.Color = float4(tex2D(ColorTextureSampler,psin.Tex + (offset * float2(rangex, rangey))).rgb, 1);
  return pso;
}

#include FullscreenQuadFooter.fx
