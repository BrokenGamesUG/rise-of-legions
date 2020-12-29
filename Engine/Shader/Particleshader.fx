#include Shaderglobals.fx
#include Shadertextures.fx

cbuffer local : register(b1)
{
  float4x4 InvView;
  float viewportheight, viewportwidth, Softparticlerange, Depthweightrange;
};

struct VSInput
{
  float3 Position : POSITION0;
  float3 Normal : NORMAL0;
  float4 Color : COLOR0;
  float2 Tex : TEXCOORD0;
  float3 Size : TEXCOORD1;
};

struct VSOutput
{
  float4 Position : POSITION0;
  float4 Color : COLOR0;
  float2 Tex : TEXCOORD0;
  float2 DepthSize : COLOR1;
  #ifndef NONORMALCORRECTION
    float3 FragmentNormal : COLOR2;
  #endif
};

struct PSInput
{
  float2 vPos : VPOS;
  float4 Color : COLOR0;
  float2 Tex : TEXCOORD0;
  float2 DepthSize : COLOR1;
  #ifndef NONORMALCORRECTION
    float3 FragmentNormal : COLOR2;
  #endif
};

struct PSOutput
{
  float4 NormalBuffer : COLOR0;
  float4 ColorBuffer : COLOR1;
  float4 CounterBuffer : COLOR2;
  #ifndef NOADDBUFFER
    float4 AdditionalBuffer : COLOR3;
  #endif
};

VSOutput MegaVertexShader(VSInput vsin) {
  VSOutput vsout;

  float4 Worldposition = float4(vsin.Position, 1);
  vsout.DepthSize = float2(distance(Worldposition.xyz, CameraPosition), min(vsin.Size.x, vsin.Size.y));
  float4 ViewPos = mul(View, Worldposition);
  vsout.Position = mul(Projection, ViewPos);
  #ifndef NONORMALCORRECTION
    vsout.FragmentNormal = normalize(ViewPos.xyz) * float3(1, -1, 1);
  #endif
  vsout.Tex = vsin.Tex;
  vsout.Color = vsin.Color;

  return vsout;
}

#ifdef HALFSIZEBUFFERS
	#define MAXDEPTH 300.0
#else
	#define MAXDEPTH 1000.0
#endif

PSOutput MegaPixelShader(PSInput psin){
  PSOutput pso;

  // draw billboards as unfilled black quads
  #ifdef SHOWBILLBOARDS
    pso.NormalBuffer = float4(0,1,0,psin.DepthSize.x);
    pso.ColorBuffer = float4(0,0,0,psin.DepthSize.x);
    pso.CounterBuffer = (abs(psin.Tex.x-0.5)>0.49)||(abs(psin.Tex.y-0.5)>0.49)?float4(1,1,1,1):float4(0,0,0,0);
    #ifndef NOADDBUFFER
      pso.AdditionalBuffer = pso.CounterBuffer;
    #endif
    return pso;
  #endif

  // read color and alpha of fragment, discard if too transparent (Alpha-Test)
  float4 Color = tex2D(ColorTextureSampler,psin.Tex)*psin.Color;
  clip(Color.a-0.001);

  // read scenedepth for fragmentposition from GBuffer
  float2 pixel_tex = (psin.vPos.xy + float2(0.5,0.5))/float2(viewportwidth,viewportheight);
  float Depth = tex2Dlod(VariableTexture1Sampler,float4(pixel_tex, 0.0, 0.0)).a;
  Depth = (Depth==0)?1000.0:Depth;

  // apply virtual texturmapping
  #if defined(SPHERICALMAPPING) || defined(CUBEMAPPING)
    float2 newTex = psin.Tex*2-1;

    float3 OriginSurfaceNormal = normalize(float3(newTex.x,newTex.y,sqrt(max(0,1-(newTex.x*newTex.x+newTex.y*newTex.y)))));
    float3 SurfaceNormal = OriginSurfaceNormal;

    // apply normalcorrection
    #ifndef NONORMALCORRECTION
      float3 NCNormal = normalize(psin.FragmentNormal);
      float3 NCTangent = cross(float3(0,1,0),NCNormal);
      float3 NCBinormal = cross(NCNormal,NCTangent);
      float3x3 orthogonalToPerspective = float3x3(NCTangent,NCBinormal,NCNormal);
      SurfaceNormal = normalize(mul((float3x3)orthogonalToPerspective, SurfaceNormal));
    #endif

    SurfaceNormal = normalize(mul((float3x3)InvView, SurfaceNormal*float3(1,-1,-1))*float3(-1,1,-1));

    float3 SurfaceTangent = cross(SurfaceNormal,float3(0,1,0));
    float3 SurfaceBinormal = cross(SurfaceTangent,SurfaceNormal);

    // apply either spheremapping or cubemapping
    #if !defined(CUBEMAPPING)
      newTex = SphereMap(SurfaceNormal);
    #else
      newTex = CubeMap(SurfaceNormal);
    #endif

    float4 NormalDepth = tex2Dlod(NormalTextureSampler,float4(newTex,0,0));
    float3 Normal = normalize(NormalDepth.rbg*2-1);

    float3x3 sphereToWorld = float3x3(SurfaceTangent,SurfaceNormal,SurfaceBinormal);
    Normal = mul((float3x3)View, mul(Normal,(float3x3)sphereToWorld)*float3(1,-1,1))*float3(-1,1,1);
    NormalDepth.a *= dot(OriginSurfaceNormal,float3(0,0,1));
  #else
    float4 NormalDepth = tex2D(NormalTextureSampler,psin.Tex);
    float3 Normal = normalize(NormalDepth.rgb*2-1);
    // apply normalcorrection
    #ifndef NONORMALCORRECTION
      float3 NCNormal = normalize(psin.FragmentNormal);
      float3 NCTangent = cross(float3(0,1,0),NCNormal);
      float3 NCBinormal = cross(NCNormal,NCTangent);
      float3x3 orthogonalToPerspective = float3x3(NCTangent,NCBinormal,NCNormal);
      Normal = mul((float3x3)orthogonalToPerspective,Normal);
    #endif
  #endif

  // apply depthadjustment
  #ifdef NODEPTHOFFSET
    float DepthOffset = 0;
  #else
    float DepthOffset = NormalDepth.a*psin.DepthSize.y/2;
  #endif

  psin.DepthSize.x -= DepthOffset;

  // apply depthweight
  #ifdef NODEPTHWEIGHT
	  float Weight = Color.a;
  #else
	  float Weight = Color.a*(exp((100.0-psin.DepthSize.x)/Depthweightrange));
  #endif
  // maxmimal particledepth
  pso.NormalBuffer.a = psin.DepthSize.x+2*DepthOffset;
  // weighted normal
  pso.NormalBuffer.rgb = normalize(Normal)*Weight;

  // slight visual improvement with tranlation of particles to the back while fading out, remove some plopping of the lighting
  #ifndef NOANTIDEPTHPLOPPING
    pso.NormalBuffer.a += (1-Color.a)*psin.DepthSize.y/2;
    psin.DepthSize.x += (1-Color.a)*psin.DepthSize.y/2;
  #endif

  // generate special data for rendering at lower resolutions
  #if defined(LOWRES) && !defined(NOLOWRES)
    // calculate minimal and maximal depth of the edges
    float4 NeighbourDepth = float4(tex2D(VariableTexture1Sampler,((psin.vPos+float2(1.5,0.5))/float2(viewportwidth,viewportheight))).a,
                                   tex2D(VariableTexture1Sampler,((psin.vPos+float2(0.5,-0.5))/float2(viewportwidth,viewportheight))).a,
                                   tex2D(VariableTexture1Sampler,((psin.vPos+float2(-0.5,0.5))/float2(viewportwidth,viewportheight))).a,
                                   tex2D(VariableTexture1Sampler,((psin.vPos+float2(0.5,1.5))/float2(viewportwidth,viewportheight))).a);

    NeighbourDepth = (NeighbourDepth.xyzw==float4(0.0f,0.0f,0.0f,0.0f))?float4(1000.0f,1000.0f,1000.0f,1000.0f):NeighbourDepth.xyzw;

    float NewDepth = min(Depth,min(NeighbourDepth.x,min(NeighbourDepth.y,min(NeighbourDepth.z,NeighbourDepth.w))));
    Depth = max(Depth,max(NeighbourDepth.x,max(NeighbourDepth.y,max(NeighbourDepth.z,NeighbourDepth.w))));

    pso.CounterBuffer.a = MAXDEPTH-NewDepth;
    // alpha with softparticles depended of the appropiate edge (mined or maxed)
    pso.CounterBuffer.r = Color.a * saturate((NewDepth-psin.DepthSize.x)/Softparticlerange);
    pso.CounterBuffer.g = Color.a * saturate((Depth-psin.DepthSize.x)/Softparticlerange);
  #else
    pso.CounterBuffer.a = 0;
    pso.CounterBuffer.rg = Color.a * saturate((Depth-psin.DepthSize.x)/Softparticlerange);
  #endif
  // write depthweight for the weightsum
  pso.CounterBuffer.b = Weight;

  // minimal particledepth
  pso.ColorBuffer.a = MAXDEPTH-psin.DepthSize.x;
  // weighted color
  pso.ColorBuffer.rgb = Weight * Color.rgb;

  // for linear density: write middle depth
  // for weighted alpha: write the count of written fragments with adjustment
  #ifndef NOADDBUFFER
    pso.AdditionalBuffer.a = pso.ColorBuffer.a;
	  #ifdef NOWEIGHTEDALPHASMOOTHING
      #if defined(LOWRES) && !defined(NOLOWRES)
  	    pso.AdditionalBuffer.rb = float2(1.0,((NewDepth-psin.DepthSize.x>0)?1.0:0.0));
      #else
  	    pso.AdditionalBuffer.rb = 1.0;
      #endif
      pso.AdditionalBuffer.g = (psin.DepthSize.x+DepthOffset);
	  #else
      #if defined(LOWRES) && !defined(NOLOWRES)
  	    pso.AdditionalBuffer.r = 1.0+pso.CounterBuffer.g;
        pso.AdditionalBuffer.b = ((NewDepth-psin.DepthSize.x>0)?1.0:0.0)+pso.CounterBuffer.r;
      #else
  	    pso.AdditionalBuffer.rb = 1.0+pso.CounterBuffer.g;
      #endif
      pso.AdditionalBuffer.g = (psin.DepthSize.x+DepthOffset)*pso.AdditionalBuffer.r;
	  #endif
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
