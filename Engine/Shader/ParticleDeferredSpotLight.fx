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
  psin.ScreenTex.xy = ((psin.ScreenTex.xy/psin.ScreenTex.z)+1)/2;
  #ifdef DX9
    psin.ScreenTex.xy -= 0.5/viewport_size;
  #endif

  // discard fragment if no particles has drawn to this pixel
  float4 DensityCounter = tex2D(VariableTexture1Sampler,psin.ScreenTex.xy);
  clip(DensityCounter.g-0.0001);
  float4 NormalMaxDepth = tex2D(ColorTextureSampler,psin.ScreenTex.xy);
  float4 ColorMinDepth = tex2D(NormalTextureSampler,psin.ScreenTex.xy);
  ColorMinDepth.a = MAXDEPTH - ColorMinDepth.a;
  float3 Normal = normalize(NormalMaxDepth.rgb/DensityCounter.b);

  float3 ViewDir = normalize(lerp(lerp(CornerLT,CornerRT,psin.ScreenTex.x),lerp(CornerLB,CornerRB,psin.ScreenTex.x),psin.ScreenTex.y));
  float3 Position = ViewDir * ColorMinDepth.a + CameraPosition;

  float Scattering = 0;
  // calculate the intersectionpoints of viewdir and cone
  float3 CamCone = (psin.SourcePosition-CameraPosition);
  float3 n = normalize(cross(ViewDir,CamCone));
  n = n*(dot(n,psin.Direction)>0?-1:1);

  float cosphi = sqrt(1-dot(n,psin.Direction)*dot(n,psin.Direction));
  
  if (cosphi<psin.RangeThetaPhi.z) discard;
  
  float tanphi = tan(acos(cosphi));
  float tanalpha = tan(acos(psin.RangeThetaPhi.z));

  float3 u = normalize(cross(psin.Direction,n));
  float3 w = normalize(cross(u,psin.Direction));

  float3 temp = sqrt(tanalpha*tanalpha-tanphi*tanphi)*u;
  float3 delta1 = (psin.Direction + (tanphi*w) + temp);
  float3 delta2 = (psin.Direction + (tanphi*w) - temp);

  float3 crossvec = cross(ViewDir,delta1);
  float r1 = (dot(cross(CamCone,delta1),crossvec)/dot(crossvec,crossvec));
  crossvec = cross(ViewDir,delta2);
  float r2 = (dot(cross(CamCone,delta2),crossvec)/dot(crossvec,crossvec));
  
  float3 intersect1 = r1 * ViewDir + CameraPosition;
  float3 intersect2 = r2 * ViewDir + CameraPosition;

  float3 ConeBottom = (psin.RangeThetaPhi.x*psin.Direction)+psin.SourcePosition;
  float conebottomintersectdepth =(dot((ConeBottom-CameraPosition),psin.Direction)/dot(psin.Direction,ViewDir));
  float3 conebottomintersection=conebottomintersectdepth*ViewDir+CameraPosition;

  r1 = dot((intersect1-psin.SourcePosition),psin.Direction)<0?conebottomintersectdepth:r1;
  r2 = dot((intersect2-psin.SourcePosition),psin.Direction)<0?conebottomintersectdepth:r2;
  
  r1 = dot((intersect1-conebottomintersection),psin.Direction)>0?conebottomintersectdepth:r1;
  r2 = dot((intersect2-conebottomintersection),psin.Direction)>0?conebottomintersectdepth:r2;
  
  float rtemp=r1;
  r1=min(r1,r2);
  r2=max(rtemp,r2);
  
  intersect1 = r1 * ViewDir + CameraPosition;
  intersect2 = r2 * ViewDir + CameraPosition;

  // compute attenuation of the scattered light
  float3 middlepos = (0.5*(r1+r2))*ViewDir+CameraPosition;
  float middlerange = distance(middlepos,psin.SourcePosition);
  float3 linecross = cross(psin.Direction,normalize(ViewDir));
  float middleangle = (abs(dot((CameraPosition - psin.SourcePosition),linecross)) / length(linecross)) /middlerange;
  middleangle = sqrt(1-middleangle*middleangle);// derived of the formula: cos(asin(x))=sqrt(1-x²)

  float3 tempPlane = cross(psin.Direction,ViewDir);
  float distanceFromMiddle = abs(dot(tempPlane,CameraPosition-psin.SourcePosition));

  float Spotlightfactor = saturate((middleangle-psin.RangeThetaPhi.z)/(psin.RangeThetaPhi.y-psin.RangeThetaPhi.z));
  float Rangefactor = saturate(1-(min(distance(intersect1,psin.SourcePosition),distance(intersect2,psin.SourcePosition))/psin.RangeThetaPhi.x));

  // calculate the intersection of particlecloud and spotlight on the viewray
  float EnlightedSegFront = clamp(r1,ColorMinDepth.a,NormalMaxDepth.a);
  float EnlightedSegBack = clamp(r2,ColorMinDepth.a,NormalMaxDepth.a);
  float VolumeThickness = NormalMaxDepth.a-ColorMinDepth.a;
  float LightAttenuation = saturate(Spotlightfactor * Rangefactor * saturate(EnlightedSegBack-EnlightedSegFront));

  // branch the use of linear density
  #if !defined(NOADDBUFFER) && !defined(NOLINEARDENSITY)
    float2 MiddleDepth = tex2D(VariableTexture2Sampler,psin.ScreenTex.xy).rg;
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
    float AttenuatingDensity = clamp((DistanceFrontMiddle/VolumeThickness)-EnlightedDensity,0,MAXDEPTH);
    //  back Segment
    DistanceLightMiddle = EnlightedSegBack - MiddleDepth.g;
    LightDensity = MiddleDensity * (1-DistanceLightMiddle/(DistanceBackMiddle>=0?DistanceBackMiddle:DistanceFrontMiddle));
    LightSeg = abs(DistanceLightMiddle);
    EnlightedDensity += sign(DistanceLightMiddle)*(LightSeg*(LightDensity+MiddleDensity))/2;

    Scattering = saturate((EnlightedDensity/(EnlightedDensity+AttenuatingDensity)) * LightAttenuation);
  #else
    float EnlightedSegThickness = EnlightedSegBack - EnlightedSegFront;
    float AttenuatingFrontThickness = EnlightedSegFront - ColorMinDepth.a;
    Scattering = saturate((EnlightedSegThickness/(EnlightedSegThickness+AttenuatingFrontThickness)) * LightAttenuation);
  #endif

  // branch if no direct illumination should be used
  #ifndef ONLYSCATTERING
    float3 Lightdirection = normalize(psin.SourcePosition-Position);
    float3 Light = mul((float3x3)OnlyView, Lightdirection);
    float3 Beleuchtung = BeleuchtungsBerechnung(Normal,Light)*saturate(1-(distance(psin.SourcePosition,Position)/psin.RangeThetaPhi.x));
    float Spotlightfactor2 = saturate((dot(-Lightdirection,psin.Direction)-psin.RangeThetaPhi.z)/(psin.RangeThetaPhi.y-psin.RangeThetaPhi.z));
    pso.Color.rgb = (0.85*Beleuchtung*Spotlightfactor2+ScatteringStrength*Scattering)*psin.Color.rgb*psin.Color.a;
  #else
    pso.Color.rgb = ScatteringStrength*Scattering*psin.Color.rgb*psin.Color.a;
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
