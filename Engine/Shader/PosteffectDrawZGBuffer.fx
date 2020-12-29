#include FullscreenQuadHeader.fx

cbuffer local : register(b1)
{
  float near, far;
};

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color.a = 1;
  float depth = (tex2D(ColorTextureSampler,psin.Tex).a - near) / (far - near);
  pso.Color.rgb = (1 - saturate(depth));
  return pso;
}

#include FullscreenQuadFooter.fx