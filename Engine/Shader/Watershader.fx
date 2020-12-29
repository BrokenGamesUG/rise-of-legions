#include Shaderglobals.fx
#include Shadertextures.fx

cbuffer local : register(b1)
{
  float4x4 World;
  float TimeTickVS;
  float SizeVS;
  float2 TextureNormalizationVS;
  float WaveHeightVS;
  float WaveTexelsize;
  float WaveTexelworldsize;

  float WaveHeight;
  float3 WaterColor;
  float3 SkyColor;
  float TimeTick;
  float Size;
  float Exposure;
  float Specularpower;
  float Specularintensity;
  float Roughness;
  float FresnelOffset;
  float2 TextureNormalization;
  float Transparency;
  #ifdef DEFERRED_SHADING
    float RefractionIndex;
    float DepthTransparencyRange;
    float RefractionSteps;
    float RefractionStepLength;
  #endif
  float4 MinMax;
  float ColorExtinctionRange;
  float CausticsRange;
  float CausticsScale;
};

struct VSInput
{
  float3 Position : POSITION0;
  float2 Tex : TEXCOORD0;
};

struct VSOutput
{
  float4 Position : POSITION0;
  float3 Normal : NORMAL0;
  float2 Tex : TEXCOORD0;
  float3 WorldPosition : TEXCOORD1;
};

struct PSInput
{
  float2 vPos : VPOS;
  float4 Position : POSITION0;
  float3 Normal : NORMAL0;
  float2 Tex : TEXCOORD0;
  float3 WorldPosition : TEXCOORD1;
};

float2 vPos2Coord(float2 vPos){
  return vPos / viewport_size;
}

struct PSOutput
{
  float4 Color : COLOR0;
};

#ifdef DX9
float4 lookup(float2 Tex){
  float2 dtex = (trunc(frac(Tex)/WaveTexelsize)) * WaveTexelsize;
  float4 lt = tex2Dlod(MaterialTextureSampler,float4(dtex + float2(0,0), 0, 0));
  float4 rt = tex2Dlod(MaterialTextureSampler,float4(dtex + float2(WaveTexelsize,0), 0, 0));
  float4 lb = tex2Dlod(MaterialTextureSampler,float4(dtex + float2(0,WaveTexelsize), 0, 0));
  float4 rb = tex2Dlod(MaterialTextureSampler,float4(dtex + float2(WaveTexelsize,WaveTexelsize), 0, 0));
  float2 s = (Tex - dtex) / WaveTexelsize;
  return lerp(lerp(lt, rt, s.x), lerp(lb, rb, s.x), s.y);
}
#endif

#ifdef DX11
float4 lookup(float2 Tex){
  return tex2Dlod(MaterialTextureSampler,float4(Tex, 0, 0));
}
#endif

VSOutput MegaVertexShader(VSInput vsin){
  VSOutput vsout;

  float4 WorldPosition = mul(World, float4(vsin.Position, 1));

  vsout.Tex = vsin.Tex;
  float speed = TimeTickVS / 10.0 / 3.0 / SizeVS / max(TextureNormalizationVS.x,TextureNormalizationVS.y);
  float2 scale = 0.45 * SizeVS * TextureNormalizationVS;

  float2 Tex = ((vsout.Tex + (float2(0.4, 1.0) * speed)) * scale);

  float4 center = lookup(Tex);

  Tex = ((vsout.Tex - (float2(0.4, 1.0) * speed)) * scale);

  float4 center2 = lookup(Tex);
  WorldPosition.y += lerp(center.a, center2.a, 0.5) * WaveHeightVS - WaveHeightVS * 0.5;

  vsout.Position = mul(Projection, mul(View, WorldPosition));
  vsout.WorldPosition = WorldPosition.xyz;

  float height_norm = 1.2 / max(WaveHeightVS, 0.0001);
  vsout.Normal = normalize(lerp(center.gbr * 2 - 1, center2.gbr * 2 - 1, 0.5));
  vsout.Normal.y *= height_norm;
  vsout.Normal = normalize(vsout.Normal);
   
  return vsout;
}

float3 hdr(float3 color, float exposure){
  return 1.0 - exp(-color * exposure);
}

PSOutput MegaPixelShader(PSInput psin){
  PSOutput pso;

  float speed = TimeTick / 10 / 3 / Size / max(TextureNormalization.x,TextureNormalization.y);
  float2 scale = 0.45 * Size * TextureNormalization;

  float3 Normal = normalize(psin.Normal);
  float3 Tangent = normalize(cross(float3(1,-0.1,0), Normal));
  float3 Binormal = normalize(cross(Normal, Tangent));

  float2 Tex = (psin.Tex + (normalize(float2(1.0, 0.6)) * speed * 1.35)) * scale * 4;
  float3 normal = normalize(tex2D(ColorTextureSampler, Tex).gbr*2-1);

  Tex = (psin.Tex - (normalize(float2(1.0, 0.6)) * speed * 1.35)) * scale * 3.5;
  float3 normal2 = normalize(tex2D(ColorTextureSampler, Tex).gbr*2-1);

  normal = normalize(lerp(float3(0,1,0), normalize(normal + normal2), Roughness));

  normal = normalize(mul(float3x3(Tangent, Normal, Binormal), normal));

  float3 view = normalize(psin.WorldPosition - CameraPosition);
  float fresnel = saturate(lerp(pow(1.0 - dot(normal,-view), 5), 1, FresnelOffset));
  // other methods for fresnel term: https://habibs.wordpress.com/lake/
  float transparency = 1;

  #ifdef DEFERRED_SHADING
    float2 screen_tex;
    float3 initial_scenepos = tex2Dlod(VariableTexture1Sampler, float4(vPos2Coord(psin.vPos.xy), 0, 0)).rgb;
    float3 scenepos = initial_scenepos;
    float3 scene_color = tex2Dlod(NormalTextureSampler, float4(vPos2Coord(psin.vPos.xy), 0, 0)).rgb;
    float3 raydirection;
    float4 raypos;

    #ifdef REFRACTION
      raydirection = normalize(refract(view, normal, RefractionIndex)) * RefractionStepLength;
      raypos = float4(psin.WorldPosition+raydirection,1);
      for(float i = 0; i < RefractionSteps; ++i){
        float4 projpoint = mul(mul(Projection, View), raypos);
        screen_tex = saturate((projpoint.xy/projpoint.w)*float2(0.5,-0.5)+0.5) - float2(0,1/viewport_size.y);
        scenepos = tex2Dlod(VariableTexture1Sampler, float4(screen_tex, 0, 0)).rgb;
        if (distance(scenepos, CameraPosition) <= distance(raypos.xyz, CameraPosition)) {
          // hit the surface, refine ray cast
          raypos.xyz -= raydirection;
          raydirection *= 0.5;
        }
        raypos.xyz += raydirection;
      }
      // due precision errors take 4 times upper target screen pixel to sample always behind obstacles
      float4 projpoint = mul(mul(Projection, View), raypos);
      screen_tex = saturate(saturate((projpoint.xy/projpoint.w)*float2(0.5,-0.5)+0.5) - float2(0,4/viewport_size.y));
      scenepos = tex2Dlod(VariableTexture1Sampler, float4(screen_tex, 0, 0)).rgb;

      scene_color = tex2Dlod(NormalTextureSampler, float4(screen_tex, 0, 0)).rgb;
    #endif

    float depth = distance(psin.WorldPosition, scenepos);
    transparency = lerp(0.0, 1 - Transparency, saturate((depth-0.1) / DepthTransparencyRange));

    // color extinction
    // from http://www.gamedev.net/page/resources/_/technical/graphics-programming-and-theory/rendering-water-as-a-post-process-effect-r2642

    float3 water_color = WaterColor;
    float3 extinction = saturate(water_color);
    float3 resulting_color = lerp(scene_color, water_color, depth / ColorExtinctionRange / extinction);

    float3 reflection = reflect(view, normal);
    #ifdef REFLECTIONS
      // reflection
      raydirection = reflection * depth;
      raypos = float4(psin.WorldPosition+raydirection,1);
      float hit = 0;
      float3 current_scenepos;
      for(float j = 0; j < RefractionSteps; ++j){
        float4 projpoint = mul(mul(Projection, View), raypos);
        screen_tex = (projpoint.xy / projpoint.w) * float2(0.5, -0.5) + 0.5;
        if (any(screen_tex < 0) || any(screen_tex > 1)){
          break;
        }
        current_scenepos = tex2Dlod(VariableTexture1Sampler, float4(screen_tex,0,0)).rgb;

        #ifdef SCENE_MAY_CONTAIN_BACKBUFFER
          //float out_of_scene = tex2Dlod(VariableTexture4Sampler, float4(screen_tex,0,0)).a;
          //if (out_of_scene <= 0.5) break;
        #endif

        if (distance(current_scenepos, CameraPosition) <= distance(raypos.xyz, CameraPosition)) {
          // hit the surface, refine ray cast
          hit = 1;
          if (distance(current_scenepos,raypos.xyz)<0.1) break;
          raypos.xyz -= raydirection;
          raydirection *= 0.5;
        }
        raypos.xyz += raydirection;
      }
    #endif

    #ifdef SKY_REFLECTION
      float2 sky_tex = float2(atan2(reflection.x,reflection.z)/(2*3.141592654) + 0.5,(asin(-reflection.y)/3.141592654 + 0.5));
      float3 sky = tex2Dlod(VariableTexture2Sampler, float4(sky_tex, 0.0, 0.0));
    #else
      float3 sky = SkyColor;
    #endif

    #ifdef REFLECTIONS
      sky = lerp(sky, tex2Dlod(NormalTextureSampler, float4(screen_tex, 0, 0)).rgb, hit);
    #endif

    resulting_color = lerp(resulting_color, sky, fresnel);

    #ifdef CAUSTICS
      // caustics
      float3 scene_normal = tex2Dlod(VariableTexture4Sampler, float4(vPos2Coord(psin.vPos.xy), 0, 0)).rgb;
      float2 caustic_tex = (initial_scenepos.xz-MinMax.xy)/(MinMax.zw-MinMax.xy);
      float2 temoTex = (caustic_tex + (float2(0.4,1.0) * speed)) * scale * CausticsScale;
      float caustic1 = tex2Dlod(VariableTexture3Sampler, float4(temoTex,0,0)).a;
      temoTex = (caustic_tex + (float2(-0.4,-1.0) * speed)) * scale * CausticsScale;
      float caustic2 = tex2Dlod(VariableTexture3Sampler, float4(temoTex,0,0)).a;
      float resulting_caustic = saturate(transparency * caustic1 * caustic2 * (1-((psin.WorldPosition.y - scenepos.y)/CausticsRange)) * scene_normal.y);
      resulting_color = resulting_color + resulting_caustic;
    #endif

    // borders
    resulting_color = lerp(scene_color, resulting_color, transparency);

    pso.Color = float4(resulting_color, 1.0);
  #else
    #ifdef SKY_REFLECTION
      float3 reflection = reflect(view, normal);
      float2 sky_tex = float2(atan2(reflection.x,reflection.z)/(2*3.141592654) + 0.5,(asin(-reflection.y)/3.141592654 + 0.5));
      float3 sky = tex2Dlod(VariableTexture2Sampler, float4(sky_tex, 0.0, 0.0));
    #else
      float3 sky = SkyColor;
    #endif
    float3 scolor = sky;
    float3 wcolor = saturate(WaterColor);

    float3 resulting_color = lerp(wcolor, scolor, fresnel);

    pso.Color = float4(resulting_color, Transparency);
  #endif

  // specular
  float3 halfway = normalize(-view+DirectionalLightDir);
  float3 Specular =  saturate(pow(saturate(dot(normal,halfway)),Specularpower)-0.8)/0.2;

  pso.Color.rgb = lerp(pso.Color.rgb, DirectionalLightColor.rgb, Specular * Specularintensity * transparency);

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
