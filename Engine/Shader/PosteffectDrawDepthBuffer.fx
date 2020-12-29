#include FullscreenQuadHeader.fx

cbuffer local : register(b1)
{
  float near, far;
};

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color.a = 1;
  float depth = (1000.0-tex2D(ColorTextureSampler,psin.Tex).r)-near;
  pso.Color.rgb = depth/(far-near);
  return pso;
}

#include FullscreenQuadFooter.fx