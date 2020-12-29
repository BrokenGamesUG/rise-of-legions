#include Shaderglobals.fx
#include Shadertextures.fx

#block defines
#endblock

#undef LIGHTING

cbuffer local : register(b1)
{
  float4x4 World, WorldInverseTranspose;
  float3 LightPosition;
  float AlphaTestRef;

  #ifdef MORPH
    float4 Morphweights[2];
  #endif

  #block custom_parameters
  #endblock
};

cbuffer bones : register(b2)
{
  float4x3 BoneTransforms[MAX_BONES];
};

#block custom_methods
#endblock

#ifdef SKINNING
  // number of influencing bones per vertex in range [1, 4]
  #define NumBoneInfluences 4
#endif

struct VSInput
{
  #block vs_input_override
    float3 Position : POSITION0;
    #ifdef MORPH
      #if MORPH_COUNT > 0
        float3 Position_Morph_1 : POSITION1;
      #endif
      #if MORPH_COUNT > 1
        float3 Position_Morph_2 : POSITION2;
      #endif
      #if MORPH_COUNT > 2
        float3 Position_Morph_3 : POSITION3;
      #endif
      #if MORPH_COUNT > 3
        float3 Position_Morph_4 : POSITION4;
      #endif
      #if MORPH_COUNT > 4
        float3 Position_Morph_5 : POSITION5;
      #endif
      #if MORPH_COUNT > 5
        float3 Position_Morph_6 : POSITION6;
      #endif
      #if MORPH_COUNT > 6
        float3 Position_Morph_7 : POSITION7;
      #endif
      #if MORPH_COUNT > 7
        float3 Position_Morph_8 : POSITION8;
      #endif
    #endif
    #ifdef VERTEXCOLOR
      float4 Color : COLOR0;
    #endif
    #if defined(DIFFUSETEXTURE) || defined(NORMALMAPPING) || defined(MATERIAL) || defined(FORCE_TEXCOORD_INPUT)
      float2 Tex : TEXCOORD0;
    #endif
    #if defined(LIGHTING) || defined(FORCE_NORMALMAPPING_INPUT)
      float3 Normal : NORMAL0;
      #if defined(NORMALMAPPING) || defined(FORCE_NORMALMAPPING_INPUT)
        float3 Tangent : TANGENT0;
        float3 Binormal : BINORMAL0;
      #endif
    #endif

    #if defined(SKINNING) || defined(FORCE_SKINNING_INPUT)
      float4 BoneWeights : BLENDWEIGHT0;
      float4 BoneIndices : BLENDINDICES0;
    #endif
    #ifdef SMOOTHED_NORMAL
      float3 SmoothedNormal : TEXCOORD7;
    #endif
  #endblock

  #block vs_input
  #endblock
};

struct VSOutput
{
  float4 Position : POSITION0;
  float3 WorldPosition : TEXCOORD0;
  #if defined(DIFFUSETEXTURE) || defined(NORMALMAPPING) || defined(MATERIAL)
    float2 Tex : TEXCOORD1;
  #endif
  #ifdef SMOOTHED_NORMAL
    float3 SmoothedNormal : TEXCOORD7;
  #endif

  #block vs_output
  #endblock
};

struct PSInput
{
  float4 Position : POSITION0;
  float3 WorldPosition : TEXCOORD0;
  #if defined(DIFFUSETEXTURE) || defined(NORMALMAPPING) || defined(MATERIAL)
    float2 Tex : TEXCOORD1;
  #endif
  #ifdef SMOOTHED_NORMAL
    float3 SmoothedNormal : TEXCOORD7;
  #endif

  #block ps_input
  #endblock
};

struct PSOutput
{
  float4 Color : COLOR0;
};

VSOutput MegaVertexShader(VSInput vsin){
  VSOutput vsout;

  #block pre_vertexshader
  #endblock

  float4 pos = float4(vsin.Position, 1.0);
  #ifdef MORPH
    #if MORPH_COUNT > 0
      pos.xyz += vsin.Position_Morph_1 * Morphweights[0][0];
    #endif
    #if MORPH_COUNT > 1
      pos.xyz += vsin.Position_Morph_2 * Morphweights[0][1];
    #endif
    #if MORPH_COUNT > 2
      pos.xyz += vsin.Position_Morph_3 * Morphweights[0][2];
    #endif
    #if MORPH_COUNT > 3
      pos.xyz += vsin.Position_Morph_4 * Morphweights[0][3];
    #endif
    #if MORPH_COUNT > 4
      pos.xyz += vsin.Position_Morph_5 * Morphweights[1][0];
    #endif
    #if MORPH_COUNT > 5
      pos.xyz += vsin.Position_Morph_6 * Morphweights[1][1];
    #endif
    #if MORPH_COUNT > 6
      pos.xyz += vsin.Position_Morph_7 * Morphweights[1][2];
    #endif
    #if MORPH_COUNT > 7
      pos.xyz += vsin.Position_Morph_8 * Morphweights[1][3];
    #endif
  #endif

  #ifdef SKINNING
    float4x3 skinning = 0;

    [unroll]
    for (int i = 0; i < NumBoneInfluences; i++) {
      skinning += vsin.BoneWeights[i] * BoneTransforms[vsin.BoneIndices[i]];
    }

    pos.xyz = mul((float3x3)skinning, pos.xyz) + skinning._41_42_43;
  #endif

  #ifdef SMOOTHED_NORMAL
    #ifdef SKINNING
      float3 SmoothedNormal = mul((float3x3)skinning, vsin.SmoothedNormal);
    #else
      float3 SmoothedNormal = vsin.SmoothedNormal;
    #endif
    SmoothedNormal = normalize(mul((float3x3)WorldInverseTranspose, normalize(SmoothedNormal)));
  #endif

  #block vs_worldposition
  float4 Worldposition = mul(World, pos);
  #endblock

  #if defined(DIFFUSETEXTURE) || defined(NORMALMAPPING) || defined(MATERIAL)
    vsout.Tex = vsin.Tex;
  #endif

  vsout.Position = mul(Projection, mul(View, Worldposition));
  vsout.WorldPosition = Worldposition.xyz;

  #ifdef SMOOTHED_NORMAL
    vsout.SmoothedNormal = SmoothedNormal;
  #endif

  #block after_vertexshader
  #endblock

  return vsout;
}

PSOutput MegaPixelShader(PSInput psin){
  PSOutput pso;

  #if defined(ALPHATEST) && defined(DIFFUSETEXTURE)
    clip(tex2D(ColorTextureSampler, psin.Tex).a - AlphaTestRef);
  #endif

  #block shadow_clip_test
  #endblock

  float distance = dot(DirectionalLightDir, LightPosition - psin.WorldPosition);
  pso.Color = float4(0, 0, 1000.0 - distance, 0);

  return pso;
}

technique MegaTec
{
  pass p0
  {
    VertexShader=compile vs_3_0 MegaVertexShader();
    PixelShader=compile ps_3_0 MegaPixelShader();
  }
}