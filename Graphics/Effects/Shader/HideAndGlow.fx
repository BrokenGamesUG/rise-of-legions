#block custom_parameters
  #inherited
  float hag_overshoot;
  float3 hag_color;
  float hag_is_glow_stage;
  float hag_visibility;
#endblock

#block after_pixelshader
  #inherited
  #ifdef DIFFUSETEXTURE
    float hag_mask_color = tex2Dlod(VariableTexture3Sampler, float4(psin.Tex, 0, 0)).r;

    #ifdef GBUFFER
      #ifdef DRAW_MATERIAL
        pso.MaterialBuffer.a += hag_overshoot * hag_mask_color;
      #endif
    #endif
    pso.Color.a = lerp(pso.Color.a, hag_overshoot, hag_is_glow_stage * hag_mask_color);
    pso.Color.rgb = lerp(pso.Color.rgb, hag_color, hag_overshoot * (1 - hag_is_glow_stage) * hag_mask_color);

    // hide in glow stage
    clip(1 - hag_mask_color + hag_overshoot * hag_is_glow_stage * hag_mask_color + 1 - hag_is_glow_stage - 0.001);
    // hide in world stage
    clip(1 - hag_mask_color + hag_visibility * (1 - hag_is_glow_stage) * hag_mask_color + hag_is_glow_stage - 0.8);
  #endif
#endblock
