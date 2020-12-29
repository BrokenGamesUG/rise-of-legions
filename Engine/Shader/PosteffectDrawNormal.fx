#include FullscreenQuadHeader.fx

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color.a = 1;
  pso.Color.rgb = ((tex2D(ColorTextureSampler,psin.Tex).rgb)+1)/2;
  return pso;
}

#include FullscreenQuadFooter.fx