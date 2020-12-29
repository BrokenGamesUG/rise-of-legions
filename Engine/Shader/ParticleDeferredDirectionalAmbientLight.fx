#include Shaderglobals.fx
#include Shadertextures.fx

cbuffer local : register(b1)
{
  float pixelwidth, pixelheight, testvalue;
};

struct VSInput
{
  float3 Position : POSITION0;
  float2 Tex : TEXCOORD0;
};

struct VSOutput
{
  float4 Position : POSITION0;
  float2 Tex : TEXCOORD0;
};

VSOutput MegaVertexShader(VSInput vsin){
  VSOutput vsout;
  vsout.Position = float4(vsin.Position, 1);
  #ifdef DX9
    vsout.Position.xy -= float2(pixelwidth, -pixelheight);
  #endif
  vsout.Tex = vsin.Tex;
  return vsout;
}

struct PSOutput
{
  float4 Color : COLOR0;
  #ifdef LIGHTBUFFER
    float4 Lightbuffer : COLOR1;
  #endif
};

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;

  // discard fragment if no particles has drawn to this pixel
  float4 DensityCounter = tex2D(VariableTexture1Sampler,psin.Tex);
  clip(DensityCounter.g-0.0001);
  pso.Color.a=DensityCounter.g;
  float4 NormalMaxDepth = tex2D(ColorTextureSampler,psin.Tex);

  // fetch weighted normal, an enlight the particleeffekt with given directional light
  float3 Normal = NormalMaxDepth.rgb / DensityCounter.b;
  float3 Beleuchtung = BeleuchtungsBerechnung(normalize(Normal),DirectionalLightDir)*DirectionalLightColor.rgb*DirectionalLightColor.a;

  pso.Color.rgb = Beleuchtung;

  return pso;
}

technique MegaTec
{
   pass p0
   {
     VertexShader = compile vs_3_0 MegaVertexShader();
     PixelShader = compile ps_3_0 MegaPixelShader();
   }
}
