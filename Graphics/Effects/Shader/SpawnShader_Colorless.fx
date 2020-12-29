#block defines
  #inherited
  #define NEEDWORLD
  #define SMOOTHED_NORMAL
  #define BREAK_START 0.4
  #define BREAK_LENGTH 0.15
  #define SQUEEZE_START 0.4
  #define SQUEEZE_LENGTH 0.30
  #define COLOR_START 0.4
  #define COLOR_LENGTH 0.6
#endblock

#block custom_parameters
  #inherited
  float3 object_position;
  float progress, model_height;
#endblock

#block vs_worldposition
  #inherited
  float melt_factor = saturate((progress - BREAK_START) / BREAK_LENGTH);
  Worldposition.y -= (model_height * 1.1) * (1 - melt_factor);

  float squeeze_factor = saturate((progress - SQUEEZE_START) / SQUEEZE_LENGTH);
  float3 relative_position = Worldposition.xyz - object_position;
  relative_position *= 0.35 * float3(1, -1, 1) * -sin(squeeze_factor * PI * 2) + 1;
  Worldposition.xyz = object_position + relative_position;
#endblock

#block after_pixelshader
  #inherited
  float color_factor = saturate((progress - COLOR_START) / COLOR_LENGTH);
  pso.Color.rgb = lerp(float3(0.24, 1.0, 1.0), pso.Color.rgb, color_factor);
  #ifdef GBUFFER
    #ifdef DRAW_MATERIAL
      pso.MaterialBuffer.a = lerp(pso.MaterialBuffer.a, 1.0, 1 - color_factor);
    #endif
  #endif
#endblock