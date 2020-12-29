#include FullscreenQuadHeader.fx

cbuffer local : register(b1)
{
  float pixelwidth, pixelheight, intensity;
  #ifdef BILATERAL
  float range, normalbias;
  #endif
};

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  #define REAL_KERNELSIZE KERNELSIZE+2
  #ifdef ADDITIVE
    #if KERNELSIZE == 0
      float kernel[REAL_KERNELSIZE] = GAUSS_0_ADDITIVE;
    #elif KERNELSIZE == 1
      float kernel[REAL_KERNELSIZE] = GAUSS_1_ADDITIVE;
    #elif KERNELSIZE == 2
      float kernel[REAL_KERNELSIZE] = GAUSS_2_ADDITIVE;
    #elif KERNELSIZE == 3
      float kernel[REAL_KERNELSIZE] = GAUSS_3_ADDITIVE;
    #elif KERNELSIZE == 4
      float kernel[REAL_KERNELSIZE] = GAUSS_4_ADDITIVE;
    #endif
  #else
    #if KERNELSIZE == 0
      float kernel[REAL_KERNELSIZE] = GAUSS_0;
    #elif KERNELSIZE == 1
      float kernel[REAL_KERNELSIZE] = GAUSS_1;
    #elif KERNELSIZE == 2
      float kernel[REAL_KERNELSIZE] = GAUSS_2;
    #elif KERNELSIZE == 3
      float kernel[REAL_KERNELSIZE] = GAUSS_3;
    #elif KERNELSIZE == 4
      float kernel[REAL_KERNELSIZE] = GAUSS_4;
    #endif
  #endif
  pso.Color = float4(tex2D(ColorTextureSampler, psin.Tex).rgb * kernel[0], 1);
  #ifdef BILATERAL
    float4 normaldepth = tex2D(NormalTextureSampler, psin.Tex);
    float weigthsum = kernel[0];
  #endif
  [unroll]
  for (float i = 1.0; i < REAL_KERNELSIZE; i++) {
    float2 tex_offset = i * float2(pixelwidth, pixelheight);
    #ifdef BILATERAL
      float2 sample_coord = psin.Tex + tex_offset;
      float4 sample_normaldepth = tex2D(NormalTextureSampler, sample_coord);
      float rangecheck = abs(normaldepth.w - sample_normaldepth.w) < range ? 1.0 : 0.0;
      rangecheck *= dot(normaldepth.xyz, sample_normaldepth.xyz) > normalbias ? 1.0 : 0.0;
      weigthsum += rangecheck * kernel[i];
      pso.Color.rgb += tex2D(ColorTextureSampler, sample_coord).rgb * kernel[i] * rangecheck;

      sample_coord = psin.Tex - tex_offset;
      sample_normaldepth = tex2D(NormalTextureSampler, sample_coord);
      rangecheck = abs(normaldepth.w - sample_normaldepth.w) < range ? 1.0 : 0.0;
      rangecheck *= dot(normaldepth.xyz, sample_normaldepth.xyz) > normalbias ? 1.0 : 0.0;
      weigthsum += rangecheck * kernel[i];
      pso.Color.rgb += tex2D(ColorTextureSampler, sample_coord).rgb * kernel[i] * rangecheck;
    #else
      pso.Color.rgb += tex2D(ColorTextureSampler, psin.Tex + tex_offset).rgb * kernel[i];
      pso.Color.rgb += tex2D(ColorTextureSampler, psin.Tex - tex_offset).rgb * kernel[i];
    #endif
  }
  #ifdef BILATERAL
    pso.Color.rgb /= weigthsum;
  #endif
  pso.Color.rgb *= intensity;
  return pso;
}

#include FullscreenQuadFooter.fx