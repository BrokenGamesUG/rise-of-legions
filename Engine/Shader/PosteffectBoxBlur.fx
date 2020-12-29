#include FullscreenQuadHeader.fx

float pixelwidth,pixelheight;

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color.rgb = float3(0,0,0);
  for (int i = -1; i < 3; ++i) {
    for (int j = -1; j < 3; ++j) {
      float2 offset = float2(pixelwidth * j, pixelheight * i);
      float3 pixelfarbe = tex2D(ColorTextureSampler, psin.Tex + offset).rgb;
      pso.Color.rgb += pixelfarbe * pixelfarbe;
    }
  }
  pso.Color.rgb *= 0.0625;
  pso.Color.rgb = tex2D(ColorTextureSampler, psin.Tex);
  pso.Color.a = 1;
  return pso;
}

technique MegaTec
{
   pass p0
   {
      VertexShader = compile vs_2_0 MegaVertexShader();
      PixelShader = compile ps_3_0 MegaPixelShader();
   }
}
