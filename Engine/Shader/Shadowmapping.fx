
#define TRANSLUCENT

cbuffer shadow : register(b3)
{
  float4x4 ShadowView, ShadowProj;
  float3 ShadowcameraPosition;
  float Shadowbias, Slopebias, Shadowpixelwidth, ShadowStrength;
};

float2 WorldPositionToShadowtexture(float3 position)
{
    float4 pos = mul(ShadowProj, mul(ShadowView, float4(position,1)));
    return (float2(pos.x,-pos.y)/pos.w+1)/2;
}

float ComputeShadowStrength(float2 tex,	float ReferenceDepth, float Slope, sampler ShadowmasktextureSampler
#ifdef DX11
  ,Texture2D Shadowmasktexture
#endif
)
{
  #ifdef DX11
    float4 shadow_texel = Shadowmasktexture.Load(float3(tex / Shadowpixelwidth,0));
  #else
	  float4 shadow_texel = tex2Dlod(ShadowmasktextureSampler,float4(tex,0,0));
  #endif
  ReferenceDepth -= Shadowbias + Slope * Slopebias;
  float fix_shadow_depth = 1000.0 - shadow_texel.b;
  #ifdef TRANSLUCENT
    float min_translucent_shadow_depth = 1000-shadow_texel.r;
    float max_translucent_shadow_depth = shadow_texel.g;
    float translucent_shadow_part = max(0.01, max_translucent_shadow_depth - min_translucent_shadow_depth);
    float factor_in_translucent_part = saturate(translucent_shadow_part / (ReferenceDepth - min_translucent_shadow_depth));
    float translucent_shadow_factor = lerp(0, saturate(shadow_texel.a), factor_in_translucent_part);
    return 1-((1-translucent_shadow_factor) * step(ReferenceDepth, fix_shadow_depth));
  #else
    return saturate(ReferenceDepth - fix_shadow_depth);
  #endif
}

// PCF Shadow Maps, optimized with SAT and interpolation
// self mix of techniques from:
// http://http.developer.nvidia.com/GPUGems3/gpugems3_ch08.html
float GetShadowStrength(float3 fragmentposition, float3 fragmentnormal, sampler shadowmasktexturesampler
#ifdef DX11
  ,Texture2D shadowmasktexture
#endif
){
  float2 ShadowTex = WorldPositionToShadowtexture(fragmentposition);
  float SceneDepth = (dot(DirectionalLightDir, ShadowcameraPosition - fragmentposition));
  float Slope = 1-dot(DirectionalLightDir, fragmentnormal);

  // build coords for bilinear quad
  float width = 1.0/Shadowpixelwidth;
  float2 uv = trunc(ShadowTex*width)/width;
  float2 ShadowTex2 = uv + (Shadowpixelwidth/2);
  uv = (ShadowTex-uv)/Shadowpixelwidth;

  // move a half block
  float2 offset = round(uv);
  uv = uv - offset + 0.5;

  #define RANGE SHADOW_SAMPLING_RANGE
  #define MIDDLE RANGE
  #define SIZE (RANGE*2+2)
  #define HALFSIZE (SIZE/2)
  float Shadow[SIZE][SIZE];
  for(float x = 0 ; x<SIZE ; ++x){Shadow[x][0]=0;}
  for(float y = 0 ; y<SIZE ; ++y){
    float xsum = 0;
	  for(float x = 0 ; x<SIZE ; ++x){
		  float2 tex = ShadowTex2+((float2(x,y)-float2(HALFSIZE,HALFSIZE)+offset-float2(0.5,0.5))*Shadowpixelwidth);
		  xsum += ComputeShadowStrength(tex, SceneDepth, Slope, shadowmasktexturesampler
		  #ifdef DX11
			,shadowmasktexture
		  #endif
		  );
	    Shadow[x][y]=xsum+Shadow[x][max(0,y-1)];
	  }
  }
  float lt = Shadow[MIDDLE+RANGE][MIDDLE+RANGE];
  float rt = Shadow[MIDDLE+1+RANGE][MIDDLE+RANGE] - Shadow[MIDDLE-RANGE][MIDDLE+RANGE];
  float lb = Shadow[MIDDLE+RANGE][MIDDLE+1+RANGE] - Shadow[MIDDLE+RANGE][MIDDLE-RANGE];
  float rb = Shadow[MIDDLE+1+RANGE][MIDDLE+1+RANGE] - Shadow[MIDDLE+1+RANGE][MIDDLE-RANGE] - Shadow[MIDDLE-RANGE][MIDDLE+1+RANGE] + Shadow[MIDDLE-RANGE][MIDDLE-RANGE];
  float x1 = lerp(lt,rt,uv.x);
  float x2 = lerp(lb,rb,uv.x);
  float ResultingShadow = lerp(x1,x2,uv.y);
  ResultingShadow /= sqr(HALFSIZE);

  return saturate(ResultingShadow * ShadowStrength);
}

