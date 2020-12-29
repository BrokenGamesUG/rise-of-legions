#block custom_parameters
  #inherited
  float go_overshoot;
  float3 go_color;
  float go_is_glow_stage;
#endblock

#block color_adjustment
  #ifdef GBUFFER
    #ifdef DRAW_MATERIAL
      pso.MaterialBuffer.a += go_overshoot;
    #endif
  #endif
  pso.Color.a += go_overshoot * go_is_glow_stage;
  pso.Color.rgb = lerp(pso.Color.rgb, go_color, go_overshoot * (1 - go_is_glow_stage));

  #inherited
#endblock
