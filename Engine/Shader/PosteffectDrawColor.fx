#include FullscreenQuadHeader.fx

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color.a = 1;
  pso.Color.rgb = tex2D(ColorTextureSampler,psin.Tex).rgb;
  return pso;
}

#include FullscreenQuadFooter.fx