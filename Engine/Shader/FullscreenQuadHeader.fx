#include Shaderglobals.fx
#include Shadertextures.fx

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

struct PSOutput
{
  float4 Color : COLOR0;
};

VSOutput MegaVertexShader(VSInput vsin){
  VSOutput vsout;
  vsout.Position = float4(vsin.Position, 1.0);
  #ifdef DX9
    vsout.Position.xy -= float2(1.0, -1.0) / viewport_size;
  #endif
  vsout.Tex = vsin.Tex;
  return vsout;
}