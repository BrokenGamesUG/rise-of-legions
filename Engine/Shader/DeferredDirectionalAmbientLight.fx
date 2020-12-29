#include Shaderglobals.fx
#include Shadertextures.fx

#define MAX_LIGHTS 4

cbuffer local : register(b1)
{
  float4 DirectionalLightDirs[MAX_LIGHTS];
  float4 DirectionalLightColors[MAX_LIGHTS];
  int DirectionalLightCount;
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
  vsout.Position = float4(vsin.Position, 1.0);
  #ifdef DX9
    vsout.Position.xy -= float2(1.0, -1.0) / viewport_size;
  #endif
  vsout.Tex = vsin.Tex;
  return vsout;
}

struct PSInput
{
  float4 Position : POSITION0;
  float2 Tex : TEXCOORD0;
  float4 TexPos : VPOS;
};

struct PSOutput
{
  float4 Color : COLOR0;
  #ifdef LIGHTBUFFER
    float4 Lightbuffer : COLOR1;
  #endif
};

PSOutput MegaPixelShader(PSInput psin){
  PSOutput pso;
  float3 Specular = 0;
  float3 LightIntensity = 0;
  #ifdef DX9
    float4 Color = tex2D(ColorTextureSampler,psin.Tex);
    clip(Color.a-0.001);
    float3 Position = tex2D(VariableTexture1Sampler,psin.Tex).rgb;
    float3 Normal = tex2D(NormalTextureSampler,psin.Tex).rgb;
    float4 Material = tex2D(VariableTexture2Sampler,psin.Tex);
    #ifdef SHADOWMASK
      float Shadowmask = tex2D(VariableTexture3Sampler,psin.Tex).a;
    #endif
  #else
    float4 Color = ColorTexture.Load(float3(psin.TexPos.xy, 0));
    clip(Color.a-0.001);
    float3 Position = VariableTexture1.Load(float3(psin.TexPos.xy, 0)).rgb;
    float3 Normal = NormalTexture.Load(float3(psin.TexPos.xy, 0)).rgb;
    float4 Material = VariableTexture2.Load(float3(psin.TexPos.xy, 0));
    #ifdef SHADOWMASK
      float Shadowmask = VariableTexture3.Load(float3(psin.TexPos.xy, 0)).a;
    #endif
  #endif

  for(float i=0; i < DirectionalLightCount; i++) {
    float3 Halfway = normalize(normalize(CameraPosition-Position)+DirectionalLightDirs[i].xyz);
    #ifdef SHADOWMASK
      //LightIntensity += BeleuchtungsBerechnungMitSchatten(Normal,DirectionalLightDirs[i].xyz,Shadowmask) * DirectionalLightColors[i].rgb * DirectionalLightColors[i].a;
      LightIntensity += saturate(dot(Normal,DirectionalLightDirs[i].xyz)) * (1-Shadowmask) * DirectionalLightColors[i].rgb * DirectionalLightColors[i].a;
      // only first light is affected by shadow
      Shadowmask = 0;
    #else
      //LightIntensity += BeleuchtungsBerechnung(Normal,DirectionalLightDirs[i].xyz) * DirectionalLightColors[i].rgb * DirectionalLightColors[i].a;
      LightIntensity += saturate(dot(Normal,DirectionalLightDirs[i].xyz)) * DirectionalLightColors[i].rgb * DirectionalLightColors[i].a;
    #endif
    Specular += lerp(DirectionalLightColors[i].rgb, Color.rgb, Material.b) * pow(saturate(dot(Normal,Halfway)),(Material.g * 255.0)+1) * Material.r;
  }

  pso.Color.rgb = Color.rgb * lerp(LightIntensity + Ambient, 1.0, Material.a) + Specular * LightIntensity;
  pso.Color.a = Color.a;
  #ifdef LIGHTBUFFER
    pso.Lightbuffer = float4(lerp((1 + Specular) * LightIntensity + Ambient, 1, Material.b),1);
  #endif
  return pso;
}

#include FullscreenQuadFooter.fx