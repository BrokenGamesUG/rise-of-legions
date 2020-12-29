#include Shaderglobals.fx
#include Shadertextures.fx

cbuffer local : register(b1)
{
  float3 CornerLT;
  float width;
  float3 CornerRT;
  float height;
  float3 CornerLB;
  float testvalue;
  float3 CornerRB;
  float ScatteringStrength;
  float4x4 OnlyView;
};

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
  float2 Tex : TEXCOORD1;
  float3 WorldPositionCenter : TEXCOORD2;
  float3 Range : TEXCOORD3;
};

VSOutput MegaVertexShader(VSInput vsin){
  VSOutput vsout;
  vsout.Position = mul(Projection, mul(View, float4(vsin.Position, 1)));
  vsout.Tex = ((float2(vsout.Position.x,-vsout.Position.y)/vsout.Position.w)+1)/2;
  #ifdef DX9
    vsout.Tex -= 0.5/viewport_size;
  #endif
  vsout.WorldPositionCenter = vsin.WorldPositionCenter;
  vsout.Color = vsin.Color;
  vsout.Range = vsin.Range;
  return vsout;
}

struct PSOutput
{
  float4 Color : COLOR0;
};

/*
  Calculates the minimal distance between a line and a point. LineDir expected to be normalized.
*/
float DistanceLinePoint(float3 Linestart, float3 LineDir, float3 Point){
  return length(cross(LineDir,Point-Linestart));
}

#ifdef HALFSIZEBUFFERS
	#define MAXDEPTH 300.0
#else
	#define MAXDEPTH 1000.0
#endif

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  // discard fragment if no particles has drawn to this pixel
  float4 DensityCounter = tex2D(VariableTexture1Sampler,psin.Tex);
  clip(DensityCounter.g - 0.0001);
  float4 NormalMaxDepth = tex2D(ColorTextureSampler,psin.Tex);
  float4 ColorMinDepth = tex2D(NormalTextureSampler,psin.Tex);
  ColorMinDepth.a = MAXDEPTH - ColorMinDepth.a;
  float3 Normal = normalize(NormalMaxDepth.rgb/DensityCounter.b);

  // calculate the intersection of particlecloud and pointlight on the viewray
  float3 ViewDir = normalize(lerp(lerp(CornerLT,CornerRT,psin.Tex.x),lerp(CornerLB,CornerRB,psin.Tex.x),psin.Tex.y));
  float3 Position = ViewDir * ColorMinDepth.a + CameraPosition;

  float ViewSegDepth = dot(ViewDir,psin.WorldPositionCenter-CameraPosition);
  float DistanceViewSegSphere = clamp(DistanceLinePoint(CameraPosition,ViewDir,psin.WorldPositionCenter),0 , psin.Range.x);
  float ViewSegThickness = sqrt((psin.Range.x*psin.Range.x)-(DistanceViewSegSphere*DistanceViewSegSphere));

  float EnlightedSegFront = clamp(ViewSegDepth-ViewSegThickness,ColorMinDepth.a,NormalMaxDepth.a);
  float EnlightedSegBack = clamp(ViewSegDepth+ViewSegThickness,ColorMinDepth.a,NormalMaxDepth.a);
  float VolumeThickness = NormalMaxDepth.a-ColorMinDepth.a;
  float Scattering = 0;
  // approximate light intensity scattered on the segment, horizontal and longitudinal
  float horizontal = (1 - pow(saturate(DistanceViewSegSphere / psin.Range.x), psin.Range.y + 1)) * (psin.Range.z + 1);
  float longitudinal = saturate((EnlightedSegBack - EnlightedSegFront)/(2 * ViewSegThickness));
  float LightIntensity = horizontal * longitudinal;

  // branch the use of linear density
  /*
  #if !defined(NOADDBUFFER) && !defined(NOLINEARDENSITY)
    float2 MiddleDepth = tex2D(VariableTexture2Sampler,psin.Tex).rg;
    MiddleDepth.g /= MiddleDepth.r;
    float DistanceFrontMiddle = abs(MiddleDepth.g - ColorMinDepth.a);
    float DistanceBackMiddle = abs(NormalMaxDepth.a - MiddleDepth.g);
    float MiddleDensity = 2;
    //  front Segment
    float DistanceLightMiddle = MiddleDepth.g - EnlightedSegFront;
    float LightDensity = MiddleDensity * (1-DistanceLightMiddle/(DistanceFrontMiddle>=0?DistanceFrontMiddle:DistanceBackMiddle));
    float LightSeg = abs(DistanceLightMiddle);
    float EnlightedDensity = sign(DistanceLightMiddle)*(LightSeg*(LightDensity+MiddleDensity))/2;
    //  attenuating Front
    float AttenuatingDensity = clamp((DistanceFrontMiddle/VolumeThickness)-EnlightedDensity + 1,1,MAXDEPTH);
    //  back Segment
    DistanceLightMiddle = EnlightedSegBack - MiddleDepth.g;
    LightDensity = MiddleDensity * (1-DistanceLightMiddle/(DistanceBackMiddle>=0?DistanceBackMiddle:DistanceFrontMiddle));
    LightSeg = abs(DistanceLightMiddle);
    EnlightedDensity += sign(DistanceLightMiddle)*(LightSeg*(LightDensity+MiddleDensity))/2;

    Scattering = (1-saturate(AttenuatingDensity/EnlightedDensity)) * LightIntensity;
  #else
  */
    float EnlightedSegThickness = EnlightedSegBack - EnlightedSegFront;
    float AttenuatingFrontThickness = EnlightedSegFront - ColorMinDepth.a;
    Scattering = (EnlightedSegThickness/(EnlightedSegThickness+AttenuatingFrontThickness)) * LightIntensity;
  //#endif

  // branch if no direct illumination should be used
  #ifndef ONLYSCATTERING
    float3 Light = mul((float3x3)OnlyView, normalize(psin.WorldPositionCenter - Position));
	// compute pointlight intensity
    float dist = distance(psin.WorldPositionCenter,Position);
    float intensity = (1 - pow(saturate(dist / psin.Range.x), psin.Range.y + 1)) * (psin.Range.z + 1);
    float3 Beleuchtung = BeleuchtungsBerechnung(Normal,Light) * intensity;

    pso.Color.rgb = (0.85 * Beleuchtung + saturate(ScatteringStrength * Scattering)) * psin.Color.rgb * psin.Color.a;
  #else
    pso.Color.rgb = ScatteringStrength * Scattering * psin.Color.rgb * psin.Color.a;
  #endif
  pso.Color.a = 0;
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
