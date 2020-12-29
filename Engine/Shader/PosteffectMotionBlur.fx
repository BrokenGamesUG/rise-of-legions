#include FullscreenQuadHeader.fx

cbuffer local : register(b1) {
  float4x4 oldViewProj;
  float scale, pixelwidth, pixelheight;
};

// Blur along the moved direction to blur the last motion
PSOutput MegaPixelShader(VSOutput psin) {
  PSOutput pso;
  float background = tex2D(VariableTexture1Sampler, psin.Tex).a;
  clip(background - 0.5);
  // get from the current world position the screen position of the last frame
  float4 old_screen_pos = float4(tex2D(ColorTextureSampler, psin.Tex).rgb, 1);
  old_screen_pos = mul(oldViewProj, old_screen_pos);
  old_screen_pos.xyz /= old_screen_pos.w;
  old_screen_pos.y *= -1;

  float2 blur_vector = (old_screen_pos.xy * 0.5 + 0.5) - psin.Tex;

  float3 result = 0;
  //#define KERNELSIZE 11
  //float kernel[KERNELSIZE] = {0.035822, 0.05879, 0.086425, 0.113806, 0.13424, 0.141836, 0.13424, 0.113806, 0.086425, 0.05879, 0.035822};
  #define KERNELSIZE 25
  float kernel[KERNELSIZE] = {0.000048, 0.000169, 0.000538, 0.001532, 0.003907, 0.008921, 0.018247, 0.033432, 0.054867, 0.080658, 0.106212, 0.125283, 0.132372, 0.125283, 0.106212, 0.080658, 0.054867, 0.033432, 0.018247, 0.008921, 0.003907, 0.001532, 0.000538, 0.000169, 0.000048};
  for (int i = 0; i < KERNELSIZE; ++i) {
    float factor = (i / (float(KERNELSIZE) - 1) - 0.5) * scale;
    float2 offset = factor * blur_vector;
    result += tex2D(NormalTextureSampler, psin.Tex + offset).rgb * kernel[i];
  }

  pso.Color = float4(result.rgb, 1);
  return pso;
}

#include FullscreenQuadFooter.fx
