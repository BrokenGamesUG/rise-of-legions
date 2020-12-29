#include Shaderglobals.fx
#include Shadertextures.fx

struct VSInput
{
  float3 Position : POSITION0;
  float4 Color : COLOR0;
  float3 Direction : TEXCOORD0;
  float3 SourcePosition : TEXCOORD1;
  float3 RangeThetaPhi : TEXCOORD2;
};

struct VSOutput
{
  float4 Position : POSITION0;
  float4 Color : COLOR0;
  float3 ScreenTex : TEXCOORD0;
  float3 Direction : TEXCOORD1;
  float3 SourcePosition : TEXCOORD2;
  float3 RangeThetaPhi : TEXCOORD3;
};

VSOutput MegaVertexShader(VSInput vsin){
  VSOutput vsout;
  vsout.Position = mul(Projection, mul(View, float4(vsin.Position, 1)));
  vsout.ScreenTex = float3(vsout.Position.x,-vsout.Position.y,vsout.Position.w);
  vsout.SourcePosition = vsin.SourcePosition;
  vsout.Color = vsin.Color;
  vsout.Direction = vsin.Direction;
  vsout.RangeThetaPhi = vsin.RangeThetaPhi;
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
  psin.ScreenTex.xy = ((psin.ScreenTex.xy/psin.ScreenTex.z)+1)/2;
  #ifdef DX9
    psin.ScreenTex.xy -= 0.5/viewport_size;
  #endif
  float4 Color = tex2D(ColorTextureSampler,psin.ScreenTex.xy);
  clip(Color.a-0.001);
  float3 Position = (tex2D(VariableTexture1Sampler,psin.ScreenTex.xy).rgb);
  float3 Light = normalize(psin.SourcePosition-Position);
  float3 Halfway = normalize(normalize(CameraPosition-Position)+Light);
  float3 Normal = normalize(tex2D(NormalTextureSampler,psin.ScreenTex.xy).rgb);
  float3 Beleuchtung = BeleuchtungsBerechnung(Normal,Light)*saturate(1-(distance(psin.SourcePosition,Position)/psin.RangeThetaPhi.x));
  float4 Material = tex2D(VariableTexture2Sampler,psin.ScreenTex.xy);
  float Spotlightfactor = saturate((dot(-Light,psin.Direction)-psin.RangeThetaPhi.z)/(psin.RangeThetaPhi.y-psin.RangeThetaPhi.z));
  float3 Specular = lerp(psin.Color.rgb, Color.rgb, Material.b) * pow(saturate(dot(Normal,Halfway)),(Material.g*255)) * Material.r;
  pso.Color.rgb = (Color.rgb+Specular)*(Beleuchtung*psin.Color.rgb)*psin.Color.a;// + (Color.rgb * Material.a); Shading Reduction only for Directional light and Ambient
  pso.Color.a = Color.a * Spotlightfactor;
  #ifdef LIGHTBUFFER
    pso.Lightbuffer = float4((1+Specular)*(Beleuchtung*psin.Color.rgb)*psin.Color.a, 1);// + (Color.rgb * Material.a),1);
  #endif
  return pso;
}

technique MegaTec
{
    pass p0
    {
        #ifdef LIGHTBUFFER
          VertexShader = compile vs_3_0 MegaVertexShader();
          PixelShader = compile ps_3_0 MegaPixelShader();
        #else
          VertexShader = compile vs_2_0 MegaVertexShader();
          PixelShader = compile ps_2_0 MegaPixelShader();
        #endif
    }
}
