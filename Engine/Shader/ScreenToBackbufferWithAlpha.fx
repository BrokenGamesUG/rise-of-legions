#include FullscreenQuadHeader.fx

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color = tex2D(ColorTextureSampler,psin.Tex);
  return pso;
}

#include FullscreenQuadFooter.fx