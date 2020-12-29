#block custom_parameters
  #inherited
  float inv_start, inv_end, inv_glow, inv_smooth;
  float3 inv_color;
#endblock

#block after_pixelshader
  #inherited
  #ifdef DIFFUSETEXTURE
    float2 raw_mask_color = tex2D(VariableTexture3Sampler, psin.Tex).rg;
    float mask_color = raw_mask_color.r;
    float glow_mask = raw_mask_color.g;
  #else
    float mask_color = 1.0;
    float glow_mask = 0.1;
  #endif

  float corrected_end = inv_end;
  float corrected_mask_color = mask_color;
  if (inv_start > inv_end) {
    if (mask_color < inv_end){
      corrected_mask_color += 1.0;
    }
    corrected_end += 1.0;
  }
  float inv_mask_progress = (corrected_mask_color - inv_start) / (corrected_end - inv_start);
  inv_mask_progress = (0.5 - abs(inv_mask_progress - 0.5)) * 2;

  clip(inv_mask_progress - 0.001);

  mask_color -= 1.0;
  float inv_edge = 1 - saturate(inv_mask_progress / 0.6);
  pso.Color.a = lerp(pso.Color.a, pso.Color.a + glow_mask * inv_edge, inv_glow);
  pso.Color.rgb = lerp(pso.Color.rgb, float3(0.91, 1.00, 1.00), (1 - inv_glow) * inv_edge);
#endblock

#block shadow_clip_test
  #inherited
  #ifdef DIFFUSETEXTURE
    float mask_color = tex2D(VariableTexture3Sampler, psin.Tex).r;
  #else
    float mask_color = 1.0;
  #endif
  float corrected_end = inv_end;
  float corrected_mask_color = mask_color;
  if (inv_start > inv_end) {
    if (mask_color < inv_end){
      corrected_mask_color += 1.0;
    }
    corrected_end += 1.0;
  }
  float inv_mask_progress = (corrected_mask_color - inv_start) / (corrected_end - inv_start);
  inv_mask_progress = (0.5 - abs(inv_mask_progress - 0.5)) * 2;

  clip(inv_mask_progress - 0.001);
#endblock
