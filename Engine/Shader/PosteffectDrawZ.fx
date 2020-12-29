#include FullscreenQuadHeader.fx

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color.a = 1;
  float depth = tex2D(ColorTextureSampler,psin.Tex).r/1000;
  depth = depth == 0 ? 1 : depth;
  pso.Color.rgb = (1-depth)*1.2-0.2;
  return pso;
}

#include FullscreenQuadFooter.fx