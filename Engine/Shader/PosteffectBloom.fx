#include FullscreenQuadHeader.fx

cbuffer local : register(b1)
{
  float3 threshold, threshold_width;
};

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color.a = 1;
  pso.Color.rgb = tex2D(ColorTextureSampler, psin.Tex).rgb;
  #ifdef THRESHOLD_RGB
    float3 rgb_factor = ((threshold - pso.Color.rgb) / threshold_width);
    float bloom_factor = max(rgb_factor.x, max(rgb_factor.y, rgb_factor.z));
  #endif
  #ifdef THRESHOLD_LUMA
    float luma = dot(pso.Color.rgb, float3(0.299, 0.587, 0.114));
    float bloom_factor = (threshold.x - luma) / threshold_width.x;
  #endif
  #ifdef THRESHOLD_HSV
    float3 hsv = RGBToHSV(pso.Color.rgb);
    float bloom_factor = ((threshold.x - hsv.z) / threshold_width.x);
  #endif
  pso.Color.rgb = lerp(pso.Color.rgb, float3(0, 0, 0), saturate(bloom_factor));
  return pso;
}

#include FullscreenQuadFooter.fx
