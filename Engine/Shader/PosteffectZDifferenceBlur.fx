#include FullscreenQuadHeader.fx

cbuffer local : register(b1)
{
  float pixelwidth, pixelheight, range;
};

#define KERNELSIZE 3
#define weight float3(0.29411764706,0.23529411764706,0.1176470588235)

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  float depth = tex2D(ColorTextureSampler, psin.Tex).a;
  depth = depth == 0 ? 1000.0 : depth;
  pso.Color.rgb = 0;
  pso.Color.a = depth * weight[0];
  float weigthsum = weight[0];
  for (int i=1; i<KERNELSIZE; i++) {
    float2 sampleCoord = psin.Tex + (i * float2(pixelwidth, pixelheight) / depth * 100);
    float sampledepth = tex2D(ColorTextureSampler, sampleCoord).a;
    sampledepth = sampledepth == 0? 1000.0 : sampledepth;
    //float rangecheck = abs(depth-sampledepth)<range? 1.0 : 0.0;
    weigthsum += weight[i];
    pso.Color.a += (abs(depth - sampledepth) < range ? sampledepth : depth + range) * weight[i];

    sampleCoord = psin.Tex -(i * float2(pixelwidth, pixelheight) / depth * 100);
    sampledepth = tex2D(ColorTextureSampler, sampleCoord).a;
    sampledepth = sampledepth == 0 ? 1000.0 : sampledepth;
    //rangecheck = abs(depth-sampledepth)<range? 1.0 : 0.0;
    weigthsum += weight[i];
    pso.Color.a += (abs(depth - sampledepth) < range ? sampledepth : depth + range) * weight[i];
  }
  pso.Color.a /= weigthsum;
  pso.Color.a = min(pso.Color.a,depth);
  return pso;
}

#include FullscreenQuadFooter.fx