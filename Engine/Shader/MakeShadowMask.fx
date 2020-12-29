#include FullscreenQuadHeader.fx
#include Shadowmapping.fx

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  float3 PixelPos = tex2Dlod(VariableTexture1Sampler, float4(psin.Tex,0,0)).rgb;
  float3 PixelNormal = normalize(tex2Dlod(NormalTextureSampler, float4(psin.Tex,0,0)).rgb);
  float ShadowStrength = GetShadowStrength(PixelPos, PixelNormal, ColorTextureSampler
  #ifdef DX11
    ,ColorTexture
  #endif
  );
  pso.Color = float4(0, 0, 0, ShadowStrength);
  return pso;
}

#include FullscreenQuadFooter.fx
