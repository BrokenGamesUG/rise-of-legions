#block defines
#endblock

#include Shaderglobals.fx
#include Shadertextures.fx

#ifdef SHADOWMAPPING
  #define SHADOW_SAMPLING_RANGE 1
  #include Shadowmapping.fx
#endif

cbuffer local : register(b1)
{
  float4x4 World, WorldInverseTranspose;

  #ifdef MATERIAL
    float Specularpower;
    float Specularintensity;
    float Speculartint;
    float Shadingreduction;
  #endif

  #ifdef ALPHA
    float Alpha;
  #endif
  #ifdef ALPHATEST
    float AlphaTestRef;
  #endif

  #ifdef COLOR_REPLACEMENT
    float4 ReplacementColor;
  #endif

  #ifdef COLORADJUSTMENT
    float3 HSVOffset;
    float3 AbsoluteHSV;
  #endif

  #ifdef TEXTURETRANSFORM
    float2 TextureOffset;
    float2 TextureScale;
  #endif

  #ifdef MORPH
    float4 Morphweights[2]; // 8 (4*2) is hardcoded maximum
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
    #if defined(ALPHAMAP_TEXCOORDS)
      float2 AlphaTex : TEXCOORD1;
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
      float3 SmoothedNormal : NORMAL1;
    #endif
  #endblock

  #block vs_input
  #endblock
};

struct VSOutput
{
  float4 Position : POSITION0;
  #ifdef VERTEXCOLOR
    float4 Color : COLOR0;
  #endif
  #if defined(DIFFUSETEXTURE) || defined(NORMALMAPPING) || defined(MATERIAL)
    float2 Tex : TEXCOORD0;
  #endif
  #ifdef ALPHAMAP_TEXCOORDS
    float2 AlphaTex : TEXCOORD1;
  #endif
  #ifdef LIGHTING
    float3 Normal : TEXCOORD2;

    #ifdef NORMALMAPPING
      float3 Tangent : TEXCOORD3;
      float3 Binormal : TEXCOORD4;
    #endif

    #if defined(MATERIAL) && !defined(GBUFFER)
      float3 Halfway : TEXCOORD5;
    #endif
  #endif
  #if defined(GBUFFER) || defined(SHADOWMAPPING) || defined(NEEDWORLD)
    float3 WorldPosition : TEXCOORD6;
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
  #ifdef VERTEXCOLOR
    float4 Color : COLOR0;
  #endif
  #if defined(DIFFUSETEXTURE) || defined(NORMALMAPPING) || defined(MATERIAL) || defined(MATERIALTEXTURE)
    float2 Tex : TEXCOORD0;
  #endif
  #ifdef ALPHAMAP_TEXCOORDS
    float2 AlphaTex : TEXCOORD1;
  #endif
  #ifdef LIGHTING
    float3 Normal : TEXCOORD2;

    #ifdef NORMALMAPPING
      float3 Tangent : TEXCOORD3;
      float3 Binormal : TEXCOORD4;
    #endif

    #if defined(MATERIAL) && !defined(GBUFFER)
      float3 Halfway : TEXCOORD5;
    #endif
  #endif
  #if defined(GBUFFER) || defined(SHADOWMAPPING) || defined(NEEDWORLD)
    float3 WorldPosition : TEXCOORD6;
  #endif
  #ifdef SMOOTHED_NORMAL
    float3 SmoothedNormal : TEXCOORD7;
  #endif

  #ifdef CULLNONE
    #ifdef DX9
      float winding : VFACE;
    #else
      bool winding : SV_IsFrontFace;
    #endif
  #endif

  #block ps_input
  #endblock
};

struct PSOutput
{
  #ifndef GBUFFER
    float4 Color : Color0;
  #else
    #ifdef DRAW_COLOR
      float4 Color : COLOR_0;
    #endif
    #ifdef DRAW_POSITION
      float4 PositionBuffer : COLOR_1;
    #endif
    #ifdef DRAW_NORMAL
      float4 NormalBuffer : COLOR_2;
    #endif
    #ifdef DRAW_MATERIAL
      float4 MaterialBuffer : COLOR_3;
    #endif
  #endif
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

  #ifdef LIGHTING
    float3 normal = vsin.Normal;
  #endif

  #ifdef RHW
    #ifdef DX9
      pos.xy -= 0.5;
    #endif
    // Pixelposition -> NDC
    vsout.Position = float4(pos.xy / viewport_size * 2 - 1, pos.z, 1.0);
    vsout.Position.y *= -1;
  #else
    #ifdef SKINNING
      float4x3 skinning = 0;

      [unroll]
      for (int i = 0; i < NumBoneInfluences; i++) {
        skinning += vsin.BoneWeights[i] * BoneTransforms[vsin.BoneIndices[i]];
      }

      pos.xyz = mul((float3x3)skinning, pos.xyz) + skinning._41_42_43;

      #ifdef LIGHTING
        normal = mul((float3x3)skinning, normal);
      #endif
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

    #if defined(GBUFFER) || defined(SHADOWMAPPING) || defined(NEEDWORLD)
      vsout.WorldPosition = Worldposition.xyz;
    #endif
    vsout.Position = mul(Projection, mul(View, Worldposition));
  #endif

  #if defined(DIFFUSETEXTURE) || defined(NORMALMAPPING) || defined(MATERIAL)
    #ifdef TEXTURETRANSFORM
      vsout.Tex = vsin.Tex * TextureScale + TextureOffset;
    #else
      vsout.Tex = vsin.Tex;
    #endif
  #endif
  #ifdef ALPHAMAP_TEXCOORDS
     vsout.AlphaTex = vsin.AlphaTex;
  #endif
  #ifdef VERTEXCOLOR
    vsout.Color = vsin.Color;
  #endif

  #ifdef LIGHTING
    #ifdef NORMALMAPPING
      float3 Normal = normalize(mul((float3x3)WorldInverseTranspose, normalize(normal)));
      float3 Tangent = normalize(mul((float3x3)World, normalize(vsin.Tangent)));
      float3 Binormal = normalize(mul((float3x3)World, normalize(vsin.Binormal)));
      vsout.Normal = Normal;
      vsout.Tangent = Tangent;
      vsout.Binormal = Binormal;
    #else
      vsout.Normal = normalize(mul((float3x3)WorldInverseTranspose, normalize(normal)));
    #endif

    #ifndef GBUFFER
      #ifdef MATERIAL
        vsout.Halfway = normalize(normalize(CameraPosition - Worldposition.xyz) + DirectionalLightDir);
      #endif
    #endif
  #endif

  #ifdef SMOOTHED_NORMAL
    vsout.SmoothedNormal = SmoothedNormal;
  #endif
  
  #block after_vertexshader

  #endblock

  return vsout;
}

PSOutput MegaPixelShader(PSInput psin){
  PSOutput pso;

  // ////////////////////////////////////////////////////////////////////////////////////////////////////
  // Shared render code independently of rendering to GBuffer or directly
  // ////////////////////////////////////////////////////////////////////////////////////////////////////
  #if !defined(GBUFFER) || defined(DRAW_COLOR)
    #block pixelshader_diffuse
      #ifdef VERTEXCOLOR
        #ifdef DIFFUSETEXTURE
          pso.Color = tex2D(ColorTextureSampler,psin.Tex) * psin.Color;
        #else
          pso.Color = psin.Color;
        #endif
      #else
        #ifdef DIFFUSETEXTURE
          pso.Color = tex2D(ColorTextureSampler, psin.Tex);
        #else
          pso.Color = float4(0.5, 0.5, 0.5, 1.0);
        #endif
      #endif
    #endblock

    #ifdef COLOR_REPLACEMENT
      pso.Color.rgb = lerp(pso.Color.rgb, ReplacementColor.rgb, ReplacementColor.a);
    #endif

    #ifdef ALPHA
      pso.Color.a *= Alpha;
    #endif

    #ifdef ALPHAMAP
      #ifdef ALPHAMAP_TEXCOORDS
        pso.Color.a *= tex2D(VariableTexture2Sampler, psin.AlphaTex).a;
      #else
        pso.Color.a *= tex2D(VariableTexture2Sampler, psin.Tex).a;
      #endif
    #endif

    #ifdef ALPHATEST
      clip(pso.Color.a - AlphaTestRef);
    #endif
  #endif

  #if defined(MATERIALTEXTURE)
    // Material texture assumed argb = (Shading Reduction, Specularintensity, Specularpower, Specular Tinting)
    float4 Material = tex2D(MaterialTextureSampler, psin.Tex);
  #endif

  #ifdef LIGHTING
    float3 Normal = normalize(psin.Normal);
    #ifdef CULLNONE
      #ifdef DX9
        Normal = Normal * psin.winding;
      #else
        if (!psin.winding) Normal *= -1;
      #endif
    #endif
    #if defined(LIGHTING) && defined(NORMALMAPPING)
      float3x3 tangent_to_world = float3x3(normalize(psin.Tangent), Normal, normalize(psin.Binormal));
      float3 texture_normal = tex2D(NormalTextureSampler,psin.Tex).rbg * 2 - 1;
      Normal = normalize(mul(texture_normal, tangent_to_world));
    #endif
  #else
    #ifdef DRAW_NORMAL
      float3 Normal = 0;
    #endif
  #endif

  #ifdef GBUFFER
  // ////////////////////////////////////////////////////////////////////////////////////////////////////
  // Rendering to GBuffer, split up all information we have
  // ////////////////////////////////////////////////////////////////////////////////////////////////////

    #ifdef DRAW_MATERIAL
      #ifdef MATERIAL
        #ifndef MATERIALTEXTURE
          pso.MaterialBuffer = float4(Specularintensity, Specularpower / 255.0 , Speculartint, Shadingreduction);
        #else
          pso.MaterialBuffer = float4(Specularintensity * Material.r, max(Material.g, Specularpower / 255.0), Speculartint * Material.b, max(Material.a, Shadingreduction));
        #endif
      #else
        #ifndef MATERIALTEXTURE
          pso.MaterialBuffer = 0;
        #else
          pso.MaterialBuffer = float4(0, 0, 0, Material.a);
        #endif
      #endif

      #ifdef ALPHA
        #ifdef DRAW_COLOR
          pso.MaterialBuffer.a = pso.Color.a;
        #else
          pso.MaterialBuffer.a = Alpha;
        #endif
      #endif
    #endif

    #ifdef DRAW_POSITION
      #ifdef ALPHA
        #ifdef DRAW_COLOR
          pso.PositionBuffer = float4(psin.WorldPosition.xyz, pso.Color.a);
        #else
          pso.PositionBuffer = float4(psin.WorldPosition.xyz, Alpha);
        #endif
      #else
         pso.PositionBuffer = float4(psin.WorldPosition.xyz, 0);
      #endif
    #endif

    #ifdef DRAW_NORMAL
      #ifdef ALPHA
        #ifdef DRAW_COLOR
          pso.NormalBuffer = float4(Normal, pso.Color.a);
        #else
          #ifdef VERTEXCOLOR
            pso.NormalBuffer = float4(Normal, psin.Color.a);
          #else
            pso.NormalBuffer = float4(Normal, 1);
          #endif
        #endif
      #else
        pso.NormalBuffer = float4(Normal, length(CameraPosition - psin.WorldPosition.xyz));
      #endif
    #endif
  #endif

  // ////////////////////////////////////////////////////////////////////////////////////////////////////
  // Rendering without GBuffer, directly drawing the resulting color
  // ////////////////////////////////////////////////////////////////////////////////////////////////////
  #ifndef GBUFFER
    #ifdef LIGHTING
      #ifdef SHADOWMAPPING
        float Shadowstrength = GetShadowStrength(psin.WorldPosition, Normal, VariableTexture3Sampler
         #ifdef DX11
           ,VariableTexture3
         #endif
         );
        float3 LightIntensity = saturate(dot(Normal,DirectionalLightDir.xyz)) * (1-Shadowstrength) * DirectionalLightColor.rgb * DirectionalLightColor.a;
      #else
        float3 LightIntensity = saturate(dot(Normal,DirectionalLightDir.xyz)) * DirectionalLightColor.rgb * DirectionalLightColor.a;
      #endif

      #ifdef MATERIAL
        float3 Halfway = normalize(psin.Halfway);
        // build material
        #ifdef MATERIALTEXTURE
          float specular_tint = Material.b;
          float specular_power = max(Material.g * 255.0, Specularpower) + 1;
          float specular_intensity = Material.r * Specularintensity;
          float shading_reduction = max(Material.a, Shadingreduction);
        #else
          float specular_tint = Speculartint;
          float specular_power = Specularpower;
          float specular_intensity = Specularintensity;
          float shading_reduction = Shadingreduction;
        #endif
        // apply lighting
        float3 Specular = lerp(DirectionalLightColor.rgb, pso.Color.rgb, specular_tint);
        Specular *= pow(saturate(dot(Normal, Halfway)), specular_power);
        Specular *= specular_intensity;
        pso.Color.rgb = pso.Color.rgb * lerp(LightIntensity + Ambient, 1.0, shading_reduction) + Specular * LightIntensity;
      #else
        #ifdef MATERIALTEXTURE
          pso.Color.rgb = pso.Color.rgb * lerp(LightIntensity + Ambient, 1.0, Material.a);
        #else
          pso.Color.rgb = pso.Color.rgb * (LightIntensity + Ambient);
        #endif
      #endif
    #endif
  #endif

  // ////////////////////////////////////////////////////////////////////////////////////////////////////
  // Postprocessing
  // ////////////////////////////////////////////////////////////////////////////////////////////////////

  #block color_adjustment
    #if !defined(GBUFFER) || defined(DRAW_COLOR)
      #ifdef COLORADJUSTMENT
        pso.Color.rgb = RGBToHSV(pso.Color.rgb);
        #ifdef ABSOLUTECOLORADJUSTMENT
          pso.Color.rgb = lerp(pso.Color.rgb,HSVOffset,AbsoluteHSV);
          pso.Color.rgb = lerp(pso.Color.rgb, float3(abs(frac(pso.Color.r + HSVOffset.r)), saturate(pso.Color.gb + HSVOffset.gb)), 1 - AbsoluteHSV);
        #else
          pso.Color.rgb = float3(abs(frac(pso.Color.r + HSVOffset.r)), saturate(pso.Color.gb + HSVOffset.gb));
        #endif
        pso.Color.rgb = HSVToRGB(pso.Color.rgb);
      #endif
    #endif
  #endblock

  #block after_pixelshader

  #endblock

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
