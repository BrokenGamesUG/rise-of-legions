#include Shaderglobals.fx
#include Shadertextures.fx

cbuffer local : register(b1)
{
  float pixelwidth, pixelheight, Softparticlerange, Aliasingrange, width, weight, Solidness;
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
  vsout.Position = float4(vsin.Position, 1);
  #ifdef DX9
    vsout.Position.xy -= float2(pixelwidth, -pixelheight);
  #endif
  vsout.Tex = vsin.Tex;
  return vsout;
}

#ifdef HALFSIZEBUFFERS
	#define MAXDEPTH 300.0
#else
	#define MAXDEPTH 1000.0
#endif

struct PSOutput
{
  float4 Color : COLOR0;
};

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;

  float4 DensityCounter = tex2D(NormalTextureSampler,psin.Tex);

  float4 ColorMinDepth = tex2D(ColorTextureSampler,psin.Tex);
  ColorMinDepth.rgb = saturate(ColorMinDepth.rgb / DensityCounter.b);

  // apply computation in case of rendering to a lower resolution
  #if defined(LOWRES) && !defined(NOLOWRES) && !defined(NOLOWRESFILLING)

    float SceneDepth = tex2D(VariableTexture2Sampler,psin.Tex).a;
    SceneDepth = (SceneDepth==0)?1000.0:SceneDepth;
    float ParticleFrontDepth = MAXDEPTH-ColorMinDepth.w;

    #ifdef DRAWLOWRESEDGES
      pso.Color.a = 1;
      pso.Color.rgb = saturate((SceneDepth-(MAXDEPTH-DensityCounter.a))-Aliasingrange*SceneDepth);
      return pso;
    #endif

    // filter values at upsampling
    #ifndef NOLOWRESFILTERING
      // build coords for bilinear quad
      float2 uv = trunc(psin.Tex*float2(width,height))/float2(width,height);
      uv = (psin.Tex-uv)/float2(pixelwidth,pixelheight);

      float2 offset = round(uv)*2-1.0;

      uv=offset*(uv-0.5);
	  
	    float4x2 texCoords = float4x2(
                                psin.Tex,
                                psin.Tex+float2(offset.x*pixelwidth,0),
                                psin.Tex+float2(0,offset.y*pixelheight),
                                psin.Tex+float2(offset.x*pixelwidth,offset.y*pixelheight));

      // (a,rgb) = (density in front of scene, lightingintensity)
      float4x4 NeighbourLighting = float4x4(
                                     tex2D(VariableTexture1Sampler,texCoords[0]),
                                     tex2D(VariableTexture1Sampler,texCoords[1]),
                                     tex2D(VariableTexture1Sampler,texCoords[2]),
                                     tex2D(VariableTexture1Sampler,texCoords[3]));

      // (a,r) = (expanded edge depth, density in front of expanded edge scene)
      float4x3 NeighbourDensity = float4x3(
                                     DensityCounter.arb,
                                     tex2D(NormalTextureSampler,texCoords[1]).arb,
                                     tex2D(NormalTextureSampler,texCoords[2]).arb,
                                     tex2D(NormalTextureSampler,texCoords[3]).arb);
									 
	  float4x3 NeighbourColor = float4x3(
                                     ColorMinDepth.rgb,
                                     saturate(tex2D(ColorTextureSampler,texCoords[1]).rgb/NeighbourDensity[1].b),
                                     saturate(tex2D(ColorTextureSampler,texCoords[2]).rgb/NeighbourDensity[2].b),
                                     saturate(tex2D(ColorTextureSampler,texCoords[3]).rgb/NeighbourDensity[3].b));

      #if !(defined(NOWEIGHTEDALPHA) || defined(NOADDBUFFER))
        // (a,r) = written fragment count in front of (scene, expanded edge scene)
        float4x2 NeighbourCount = float4x2(
                                     tex2D(MaterialTextureSampler,texCoords[0]).rb,
                                     tex2D(MaterialTextureSampler,texCoords[1]).rb,
                                     tex2D(MaterialTextureSampler,texCoords[2]).rb,
                                     tex2D(MaterialTextureSampler,texCoords[3]).rb);
        // compute resulting alpha with weighted alpha - algorithm
        NeighbourDensity._12_22_32_42 = saturate((1-pow(1-NeighbourDensity._12_22_32_42/Solidness/NeighbourCount._12_22_32_42,NeighbourCount._12_22_32_42)));
        NeighbourLighting._14_24_34_44 = saturate((1-pow(1-NeighbourLighting._14_24_34_44/Solidness/NeighbourCount._11_21_31_41,NeighbourCount._11_21_31_41)));
      #endif

	  // filter lighting and scenefront-density, prevent filtering non written values
	  if (!any(NeighbourLighting[0].rgb)) NeighbourLighting[0].rgb = NeighbourLighting[1].rgb;
	  if (!any(NeighbourLighting[1].rgb)) NeighbourLighting[1].rgb = NeighbourLighting[0].rgb;
    float4 x1 = lerp(NeighbourLighting[0],NeighbourLighting[1],uv.x);
	  if (!any(NeighbourLighting[2].rgb)) NeighbourLighting[2].rgb = NeighbourLighting[3].rgb;
	  if (!any(NeighbourLighting[3].rgb)) NeighbourLighting[3].rgb = NeighbourLighting[2].rgb;
    float4 x2 = lerp(NeighbourLighting[2],NeighbourLighting[3],uv.x);
	  if (!any(NeighbourLighting[2].rgb+NeighbourLighting[3].rgb)) x2.rgb = x1.rgb;
	  if (!any(NeighbourLighting[0].rgb+NeighbourLighting[1].rgb)) x1.rgb = x2.rgb;
    float4 Lighting = lerp(x1,x2,uv.y);

    // eliminate Halos
    float4 NeighbourDensities = ((SceneDepth-(MAXDEPTH-NeighbourDensity._11_21_31_41))>Aliasingrange*SceneDepth?Lighting.aaaa:NeighbourDensity._12_22_32_42);

    float d1 = lerp(NeighbourDensities[0],NeighbourDensities[1],uv.x);
	  float d2 = lerp(NeighbourDensities[2],NeighbourDensities[3],uv.x);
    DensityCounter.r = lerp(d1,d2,uv.y);
	  
	  //fill color for outer edge
	  if (!any(ColorMinDepth.rgb)) ColorMinDepth.rgb = max(NeighbourColor[1],max(NeighbourColor[2],NeighbourColor[3]));

    #ifdef DRAWFILTERUVS
      pso.Color = float4(uv,0,DensityCounter.r);
      return pso;
    #endif

    #else
      float4 Lighting = tex2D(VariableTexture1Sampler,psin.Tex);
      float2 n = tex2D(MaterialTextureSampler,psin.Tex).rb;
      Lighting.a = saturate((1-pow(1-Lighting.a/Solidness/n.x,n.x)));
      DensityCounter.r = saturate((1-pow(1-DensityCounter.r/Solidness/n.y,n.y)));
    #endif

    //fill in inner edges
    float Aliasingweight = lerp(DensityCounter.r,Lighting.a,saturate((SceneDepth-(MAXDEPTH-DensityCounter.a))-Aliasingrange*SceneDepth));

    pso.Color.a = saturate(Aliasingweight);

  #else
    float3 Lighting = tex2D(VariableTexture1Sampler,psin.Tex).rgb;
    #if defined(NOWEIGHTEDALPHA) || defined(NOADDBUFFER)
      pso.Color.a = saturate(DensityCounter.r/Solidness);
    #else
      float n = tex2D(MaterialTextureSampler,psin.Tex).r;
      pso.Color.a = saturate((1-pow(saturate(1-DensityCounter.r/n/Solidness),n)));
    #endif
  #endif

  // for testing apply lighting only depending of the transparency
  #ifndef SOFTSCATTERING
    pso.Color.rgb = ColorMinDepth.rgb*Lighting.rgb;
  #else
    pso.Color.rgb = ColorMinDepth.rgb*(Lighting.rgb*pso.Color.a+1-pso.Color.a);
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
