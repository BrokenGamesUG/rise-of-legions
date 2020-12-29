#include Shaderglobals.fx
#include Shadertextures.fx

struct VSInput
{
  float3 Position : POSITION0;
  float3 Normal : NORMAL0;
  float4 Color : COLOR0;
  float2 Tex : TEXCOORD0;
  float3 Size : TEXCOORD1;
};

struct VSOutput
{
  float4 Position : POSITION0;
  float4 Color : COLOR0;
  float2 Tex : TEXCOORD0;
  float2 DepthSize : TEXCOORD1;
};

struct PSInput
{
  float4 Position : POSITION0;
  float4 Color : COLOR0;
  float2 Tex : TEXCOORD0;
  float2 DepthSize : TEXCOORD1;
};

struct PSOutput
{
  float4 Color : COLOR0;
};

VSOutput MegaVertexShader(VSInput vsin) {
  VSOutput vsout;

  float4 Worldposition = float4(vsin.Position, 1);
  float distance = abs(dot(normalize(CameraDirection), Worldposition.xyz - CameraPosition));
  vsout.DepthSize = float2(distance, min(vsin.Size.x, vsin.Size.y));
  float4 ViewPos = mul(View, Worldposition);
  vsout.Position = mul(Projection, ViewPos);
  vsout.Tex = vsin.Tex;
  vsout.Color = vsin.Color;

  return vsout;
}

PSOutput MegaPixelShader(PSInput psin) {
  PSOutput pso;

  float4 Color = tex2D(ColorTextureSampler, psin.Tex) * psin.Color;

  float4 NormalDepth = tex2D(NormalTextureSampler, psin.Tex);
  float3 Normal = normalize(NormalDepth.rgb * 2 - 1);

  // apply depthadjustment
  float DepthOffset = NormalDepth.a * psin.DepthSize.y / 2;

  psin.DepthSize.x -= DepthOffset;

  // minimal particledepth
  pso.Color.r = 1000 - psin.DepthSize.x;
  // maxmimal particledepth
  pso.Color.g = psin.DepthSize.x + 2 * DepthOffset;

  pso.Color.a = Color.a * 0.4;
  // no fix shadow wall
  pso.Color.b = 0;

  return pso;
}

technique MegaTec {
  pass p0 {
    VertexShader = compile vs_3_0 MegaVertexShader();
    PixelShader = compile ps_3_0 MegaPixelShader();
  }
}
