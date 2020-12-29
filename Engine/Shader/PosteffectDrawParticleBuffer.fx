#include FullscreenQuadHeader.fx

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color.a = 1;
  #ifdef DRAWNORMAL
    float Density = tex2D(MaterialTextureSampler,psin.Tex).b;
    pso.Color.rgb = (Density==0)?float3(0.5,0.5,1.0):(normalize(tex2D(ColorTextureSampler,psin.Tex).rgb/Density)/2+0.5);
  #endif
  #ifdef DRAWCOLOR
    float Density = tex2D(MaterialTextureSampler,psin.Tex).b;
    pso.Color.rgb = (Density==0)?float3(0,0,0):(tex2D(NormalTextureSampler,psin.Tex).rgb/Density);
  #endif
  #ifdef DRAWDENSITY
    float2 Density = (tex2D(MaterialTextureSampler,psin.Tex).rg);
    float n =  tex2D(VariableTexture2Sampler,psin.Tex).r;
    pso.Color.bg = saturate(1-pow(1-Density.r/n,n));
    pso.Color.r = saturate(1-pow(1-Density.g/n,n));
  #endif
  #ifdef DRAWDEPTH
    float2 Depth = float2(tex2D(ColorTextureSampler,psin.Tex).a,1000.0-tex2D(NormalTextureSampler,psin.Tex).a);
    pso.Color.rgb = float3(1-saturate(Depth.y/50.0),0*abs(Depth.x-Depth.y)/50.0,0*abs(Depth.x-Depth.y)/50.0);
  #endif
  #ifdef DRAWMIDDLEDEPTH
    float2 FBDepth = float2(tex2D(ColorTextureSampler,psin.Tex).a,1000.0-tex2D(NormalTextureSampler,psin.Tex).a);
    float2 Depth = tex2D(VariableTexture2Sampler,psin.Tex).rg;
    pso.Color.rgb = abs((Depth.g/Depth.r)-(FBDepth.x+FBDepth.y)/2)/10.0;
  #endif
  #ifdef DRAWLIGHT
    pso.Color.rgb = tex2D(VariableTexture1Sampler,psin.Tex).rgb;
  #endif
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
