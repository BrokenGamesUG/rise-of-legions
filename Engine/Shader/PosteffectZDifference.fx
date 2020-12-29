#include FullscreenQuadHeader.fx

cbuffer local : register(b1)
{
  float range;
};

#define BIAS 0.1

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  float depth = tex2D(ColorTextureSampler, psin.Tex).a;
  depth = depth == 0 ? 1000.0 : depth;
  float blurredDepth = tex2D(NormalTextureSampler, psin.Tex).a;
  pso.Color.a = 1;
  float darkness = (1 - (abs(depth - blurredDepth) / range))/(1 - BIAS);
  pso.Color.rgb = darkness <= 0 ? 1 : darkness;

  return pso;
}

#include FullscreenQuadFooter.fx