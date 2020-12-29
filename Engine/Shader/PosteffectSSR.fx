#include Shaderglobals.fx
#include Shadertextures.fx

struct VSInput
{
  float4 Position : POSITION0;
};

struct VSOutput
{
  float4 Position : POSITION0;
  float4 Tex : TEXCOORD0;
};

struct PSOutput
{
  float4 Color : COLOR0;
};

VSOutput MegaVertexShader(VSInput vsin){
  VSOutput vsout;
  vsout.Position = mul(Projection, mul(View, mul(World, vsin.Position)));
  vsout.Tex = vsout.Position;
  return vsout;
}

float range,width,height,alpha;
int raysamples;
float4 bgcolor;
float4x4 ViewProj;

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  psin.Tex.xy=(psin.Tex.xy/psin.Tex.w)*float2(0.5,-0.5)+0.5;

  float3 position = tex2D(VariableTexture1Sampler,psin.Tex).rgb;
  float4 normalDepth = tex2D(VariableTexture2Sampler,psin.Tex);
  normalDepth.xyz=normalize(normalDepth.xyz);
  float3 lookdir = normalize(CameraPosition-position);

  lookdir = (lookdir+2*((dot(lookdir,normalDepth.xyz)*normalDepth.xyz)-lookdir))*(range/raysamples);

  float4 raypos = float4(position+lookdir,1);
  pso.Color.argb = float4(alpha,bgcolor.rgb);
  float tracing = 1;
  for(int i=0;i<raysamples;++i){
    float4 projpoint = mul(ViewProj, raypos);
    float2 tex = (projpoint.xy/projpoint.w)*float2(0.5,-0.5)+0.5;
    float sampledepth = tex2D(VariableTexture2Sampler,tex).a;
    sampledepth = sampledepth==0?1000.0:sampledepth;
    if ((tracing>0)&&(sampledepth<=length(raypos-CameraPosition))) {
       pso.Color.argb = float4(alpha,tex2D(VariableTexture3Sampler,tex).rgb);
       tracing = -1;
    }
    raypos.xyz += lookdir;
  }
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