#include Shaderglobals.fx
#include Shadertextures.fx

struct VSInput
{
  float3 Position : POSITION0;
  float4 Color : COLOR0;
  float3 WorldPositionCenter : TEXCOORD0;
  float3 Range : TEXCOORD1;
};

struct VSOutput
{
  float4 Position : POSITION0;
  float4 Color : COLOR0;
  float3 WorldPositionCenter : TEXCOORD1;
  float3 Range : TEXCOORD2;
};

VSOutput MegaVertexShader(VSInput vsin){
  VSOutput vsout;
  vsout.Position = mul(Projection, mul(View, float4(vsin.Position, 1)));
  vsout.WorldPositionCenter = vsin.WorldPositionCenter;
  vsout.Color = vsin.Color;
  vsout.Range = vsin.Range;
  return vsout;
}

struct PSInput
{
  float4 ScreenPosition : VPOS;
  float4 Color : COLOR0;
  float3 WorldPositionCenter : TEXCOORD1;
  float3 Range : TEXCOORD2;
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

  #ifdef DX9
    psin.ScreenPosition.xy /= viewport_size;
    float4 Color = tex2D(ColorTextureSampler,psin.ScreenPosition.xy);
    clip(Color.a-0.001);
    float3 Position = (tex2D(VariableTexture1Sampler,psin.ScreenPosition.xy).rgb);
    float dist = distance(psin.WorldPositionCenter,Position);
    clip(psin.Range.x - dist);
    float3 Normal = normalize(tex2D(NormalTextureSampler,psin.ScreenPosition.xy).rgb);
    float4 Material = tex2D(VariableTexture2Sampler,psin.ScreenPosition.xy);
  #else
    float4 Color = ColorTexture.Load(float3(psin.ScreenPosition.xy, 0));
    clip(Color.a-0.001);
    float3 Position = VariableTexture1.Load(float3(psin.ScreenPosition.xy, 0)).rgb;
    float dist = distance(psin.WorldPositionCenter,Position);
    clip(psin.Range.x - dist);
    float3 Normal = normalize(NormalTexture.Load(float3(psin.ScreenPosition.xy, 0)).rgb);
    float4 Material = VariableTexture2.Load(float3(psin.ScreenPosition.xy, 0));
  #endif

  float3 Light = normalize(psin.WorldPositionCenter-Position);
  float3 Halfway = normalize(normalize(CameraPosition-Position)+Light);
  float intensity = (1 - pow(saturate(dist / psin.Range.x), psin.Range.y + 1)) * (psin.Range.z + 1);
  float3 Beleuchtung = BeleuchtungsBerechnung(Normal,Light) * intensity;
  float3 Specular = lerp(psin.Color.rgb, Color.rgb, Material.b) * pow(saturate(dot(Normal,Halfway)),(Material.g*255)) * Material.r;
  pso.Color.rgb = (Color.rgb + Specular) * (Beleuchtung * psin.Color.rgb) * psin.Color.a; // + (Material.a * Color.rgb); Shading Reduction only for Directional light and Ambient
  pso.Color.a = Color.a;
  #ifdef LIGHTBUFFER
    pso.Lightbuffer = float4((1+Specular)*(Beleuchtung*psin.Color.rgb)*psin.Color.a, 1);// + (Color.rgb * Material.a),1);
  #endif
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