#include FullscreenQuadHeader.fx

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color.a = 1;
  #ifdef DX11
    pso.Color.rgb = ColorTexture.Load(float3(psin.Tex * viewport_size, 0)).rgb;
  #else
	  pso.Color.rgb = tex2Dlod(ColorTextureSampler, float4(psin.Tex, 0, 0)).rgb;
  #endif
  return pso;
}

#include FullscreenQuadFooter.fx