#include FullscreenQuadHeader.fx

cbuffer local : register(b1) {
  float border_gradient, specular_threshold, light_offset, light_threshold;
  float3 border_color;
};

PSOutput MegaPixelShader(VSOutput psin) {
  PSOutput pso;
  float4 Color = tex2D(ColorTextureSampler, psin.Tex);
  float factor = 1;
  // if no lighting is specified, lighting is in color
  float3 Light = 1;
  float3 Specular = 0;

  #ifndef NO_LIGHTING
    // discretize lighting
    float3 OriginalLight = tex2D(VariableTexture1Sampler, psin.Tex).rgb;
    Specular = (OriginalLight - 1) > float3(specular_threshold, specular_threshold, specular_threshold) ? 1 : 0;
    Light = saturate(trunc(saturate(OriginalLight) / light_threshold) + light_offset);
  #endif

  #ifndef NO_BORDER
    // apply black border
    float BlackBorder = saturate(tex2D(NormalTextureSampler, psin.Tex).r);
    factor = pow(BlackBorder, border_gradient);
  #endif

  clip(Color.a - 0.1 + (1 - factor));

  pso.Color.rgb = lerp(border_color, (Color.rgb * Light + Specular), factor);
  pso.Color.a = 1;
  return pso;
}

#include FullscreenQuadFooter.fx
