#include Shaderglobals.fx

//Texturslots
texture ColorTexture;//Slot0
texture NormalTexture;   //Slot1
texture MaterialTexture;  //Slot2
texture VariableTexture1;  //Slot3
texture VariableTexture2;  //Slot4
texture VariableTexture3;  //Slot5
texture VariableTexture4;  //Slot6

//Sampler für Texturzugriff
sampler ColorTextureSampler = sampler_state
{
  texture = <ColorTexture>;
  MipFilter = FILTERART;
  MagFilter = FILTERART;
  MinFilter = FILTERART;
  AddressU = Border;
  AddressV = Border;
  BorderColor = {0,0,0,0};
};

sampler NormalTextureSampler = sampler_state
{
  texture = <NormalTexture>;
  MipFilter = FILTERART;
  MagFilter = FILTERART;
  MinFilter = FILTERART;
  AddressU = Border;
  AddressV = Border;
  BorderColor = {0,0,0,0};
};

sampler VariableTexture1Sampler = sampler_state
{
  texture = <VariableTexture1>;
  MipFilter = FILTERART;
  MagFilter = FILTERART;
  MinFilter = FILTERART;
  AddressU = Border;
  AddressV = Border;
  BorderColor = {0,0,0,0};
};

sampler VariableTexture2Sampler = sampler_state
{
  texture = <VariableTexture2>;
  MipFilter = FILTERART;
  MagFilter = FILTERART;
  MinFilter = FILTERART;
};

sampler SpecularSampler = sampler_state
{
  texture = <MaterialTexture>;
  MipFilter = POINT;
  MagFilter = POINT;
  MinFilter = POINT;
};

sampler VariableTexture3Sampler = sampler_state
{
  texture = <VariableTexture3>;
  MipFilter = POINT;
  MagFilter = POINT;
  MinFilter = POINT;
};
sampler VariableTexture4Sampler = sampler_state
{
  texture = <VariableTexture4>;
  MipFilter = POINT;
  MagFilter = POINT;
  MinFilter = POINT;
};

struct VSInput
{
  float4 Position : POSITION0;
  float2 Tex : TEXCOORD0;
};

struct VSOutput
{
  float4 Position : POSITION0;
  float2 Tex : TEXCOORD0;
};

struct PSOutput
{
  float4 Color : COLOR0;
};

VSOutput MegaVertexShader(VSInput vsin){
  VSOutput vsout;
  vsout.Position = mul(Projection, vsin.Position);
  vsout.Tex = vsin.Tex;
  return vsout;
}

cbuffer local : register(b1)
{
  float4x4 ViewProjection, Proj;
  float range, width, height, JumpMax, ParticleInfluence;
  float4 Kernel[KERNELSIZE];
};

#define BIAS 0.1
#define EPSILON 0.000001

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  float occlusion = 0.0;
  float4 normalDepth = tex2D(NormalTextureSampler,psin.Tex);
  normalDepth.xyz=normalize(normalDepth.xyz);
  clip(normalDepth.w-0.01);
  float4 position = float4(tex2D(ColorTextureSampler,psin.Tex).rgb,1);
  position.xyz += normalDepth.xyz*(range/2.0);
  normalDepth.w = length(position-CameraPosition);
  position = mul(ViewProjection, position);
  position.xy /= position.w;
  position.xy = position.xy*float2(0.5,-0.5)+0.5;
  float3 noise = tex2D(VariableTexture2Sampler,psin.Tex*float2(width,height)).rgb;
  float normalization = EPSILON;
  for(int i=0;i<KERNELSIZE;++i){
     float4 sampleCoord = mul(Proj, float4(Kernel[i].xy,normalDepth.w,1));
     sampleCoord.xy /= sampleCoord.w;
     sampleCoord.xy = float2(sampleCoord.x*noise.x-sampleCoord.y*noise.y,sampleCoord.x*noise.y+sampleCoord.y*noise.x)+position.xy;
     float sampleZ = tex2D(NormalTextureSampler,sampleCoord.xy).a;
     //background is 0.0 but must be infinite far away
     sampleZ = (sampleZ==0.0)?1000.0:sampleZ;
     float zEntry = normalDepth.w - Kernel[i].z;
     //x - Back; y - Front
     float2 ParticleDepth = float2(tex2D(VariableTexture3Sampler,sampleCoord.xy).a,1000.0-tex2D(VariableTexture4Sampler,sampleCoord.xy).a);
     // compute intersection of ssao-sphere with particlecloud
     if (ParticleDepth.y<999.0) {
       float4 DensityCounter = tex2D(SpecularSampler,sampleCoord.xy);
       float EnlightedSegFront = max(zEntry,ParticleDepth.y);
       float EnlightedSegBack = min(sampleZ,ParticleDepth.x);
       float2 MiddleDepth = tex2D(VariableTexture1Sampler,psin.Tex).rg;
       MiddleDepth.g /= MiddleDepth.r;
       float DistanceFrontMiddle = abs(MiddleDepth.g - ParticleDepth.y);
       float DistanceBackMiddle = abs(ParticleDepth.x - MiddleDepth.g);
       float MiddleDensity = DensityCounter.g * 2;
       //front Segment
       float DistanceLightMiddle = MiddleDepth.g - EnlightedSegFront;
       float LightDensity = MiddleDensity * (1-DistanceLightMiddle/(DistanceFrontMiddle>=0?DistanceFrontMiddle:DistanceBackMiddle));
       float LightSeg = abs(DistanceLightMiddle);
       float EnlightedDensity = sign(DistanceLightMiddle)*(LightSeg*(LightDensity+MiddleDensity))/2;
       //back Segment
       DistanceLightMiddle = EnlightedSegBack - MiddleDepth.g;
       LightDensity = MiddleDensity * (1-DistanceLightMiddle/(DistanceBackMiddle>=0?DistanceBackMiddle:DistanceFrontMiddle));
       LightSeg = abs(DistanceLightMiddle);
       EnlightedDensity += sign(DistanceLightMiddle)*(LightSeg*(LightDensity+MiddleDensity))/2;

       sampleZ = sampleZ-abs(EnlightedDensity)*(ParticleInfluence/100);
     }
     float deltaZ = sampleZ-zEntry;
     float range_check = ((deltaZ<=0)?saturate(1+deltaZ/range):1.0);
     deltaZ = clamp(deltaZ,0,2.0*Kernel[i].z);
     occlusion+=deltaZ;
     normalization+=Kernel[i].z*2.0*range_check;
  }
  pso.Color.rgb = ((occlusion/normalization*(1+BIAS)))+(normalization<=EPSILON?1.0:0.0);
  pso.Color.a = 1.0;
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