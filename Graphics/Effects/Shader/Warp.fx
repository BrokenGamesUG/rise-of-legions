#block custom_parameters
  #inherited
  float warp_progress, warp_glow, warp_smooth;
  float3 warp_color;
#endblock

#block after_pixelshader
  #inherited
  #ifdef DIFFUSETEXTURE
    float2 raw_mask_color = tex2D(VariableTexture3Sampler, psin.Tex).rg;
    float mask_color = raw_mask_color.r - 1;
    float glow_mask = raw_mask_color.g;
  #else
    float mask_color = 1.0;
    float glow_mask = 1.0;
  #endif
  float warp_mask_progress = warp_progress;

  clip(mask_color + warp_mask_progress - 0.001);

  float warp_edge = 1 - smoothstep(mask_color + warp_mask_progress, 0.00, 0.005);
  pso.Color.a *= smoothstep(0.0, warp_smooth, mask_color + warp_mask_progress);
  pso.Color.a = lerp(pso.Color.a, pso.Color.a + glow_mask * warp_edge * (1 - smoothstep(0.99, 1.0, warp_progress)), warp_glow);
  pso.Color.rgb = lerp(pso.Color.rgb, warp_color, (1 - warp_glow) * warp_edge);
#endblock

#block shadow_clip_test
  #inherited
  #ifdef DIFFUSETEXTURE
    float mask_color = tex2D(VariableTexture3Sampler, psin.Tex).r - 1;
  #else
    float mask_color = 1.0;
  #endif
  float warp_mask_progress = warp_progress;

  clip(mask_color + warp_mask_progress - 0.001);
#endblock
