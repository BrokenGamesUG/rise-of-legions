#block defines
  #inherited
  #define TO_GLOW_STRENGTH 0.7
  #define TO_OVERSHOOT_STRENGTH 0.7
#endblock

#block custom_parameters
  #inherited
  float2 to_offset, to_tiling;
  float to_glow_stage;
#endblock

#block after_pixelshader
  #if defined(DIFFUSETEXTURE)
    float4 to_mask_color = tex2D(VariableTexture3Sampler, (psin.Tex + to_offset) * to_tiling);
    pso.Color.rgb = lerp(pso.Color.rgb * TO_OVERSHOOT_STRENGTH, pso.Color.rgb * (1 - to_glow_stage) + to_mask_color.rgb, to_mask_color.a);
    pso.Color.a = lerp(pso.Color.a, TO_GLOW_STRENGTH, to_mask_color.a * to_glow_stage);
  #endif
#endblock
