#include FullscreenQuadHeader.fx

#define KERNELSIZE 3

cbuffer local : register(b1) {
  float pixelwidth, pixelheight, range, normalbias, border_threshold;
};

PSOutput MegaPixelShader(VSOutput psin) {
  PSOutput pso;
  float weight[KERNELSIZE] = {0.312, 0.2269, 0.1176};
  float3 original_color = tex2D(ColorTextureSampler, psin.Tex).rgb;
  pso.Color = float4(original_color * weight[0], 0);
  float4 normaldepth = tex2D(NormalTextureSampler, psin.Tex);
  float shading_reduction = tex2D(VariableTexture2Sampler, psin.Tex).w;
  float threshold_check = step(border_threshold, shading_reduction);
  for (int i = 1; i < KERNELSIZE; i++) {
    float2 offset = (i * float2(pixelwidth, pixelheight));
    float2 sampleCoord = psin.Tex + offset;
    float4 sampleNormaldepth = tex2D(NormalTextureSampler, sampleCoord);
    shading_reduction = tex2D(VariableTexture2Sampler, sampleCoord).w;
    float rangecheck = abs(normaldepth.w - sampleNormaldepth.w) < range ? 1.0 : 0.0;
    rangecheck *= dot(normaldepth.xyz, sampleNormaldepth.xyz) >= normalbias * length(normaldepth.xyz) ? 1.0 : 0.0;
    threshold_check += step(border_threshold, shading_reduction);
    pso.Color.rgb += tex2D(ColorTextureSampler, sampleCoord).rgb * weight[i] * rangecheck;

    sampleCoord -= 2 * offset;
    sampleNormaldepth = tex2D(NormalTextureSampler, sampleCoord);
    shading_reduction = tex2D(VariableTexture2Sampler, sampleCoord).w;
    rangecheck = abs(normaldepth.w - sampleNormaldepth.w) < range ? 1.0 : 0.0;
    rangecheck *= dot(normaldepth.xyz, sampleNormaldepth.xyz) >= normalbias * length(normaldepth.xyz) ? 1.0 : 0.0;
    threshold_check += step(border_threshold, shading_reduction);
    pso.Color.rgb += tex2D(ColorTextureSampler, sampleCoord).rgb * weight[i] * rangecheck;
  }
  pso.Color.rgb = lerp(pso.Color.rgb, original_color, threshold_check);
  return pso;
}

#include FullscreenQuadFooter.fx
