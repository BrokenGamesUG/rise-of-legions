#include FullscreenQuadHeader.fx

cbuffer local : register(b1)
{
  float darkness;
};

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  float3 factor = tex2D(NormalTextureSampler, psin.Tex).rgb;
  pso.Color.argb = tex2D(ColorTextureSampler, psin.Tex).argb;
  clip(tex2D(VariableTexture1Sampler, psin.Tex).a - 0.5);
  pso.Color.rgb *= pow(saturate(factor), darkness);
  return pso;
}

#include FullscreenQuadFooter.fx
