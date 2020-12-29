#block defines
  #inherited
  #define NEEDWORLD
  #define SMOOTHED_NORMAL
  #define MELT_FINISH 0.6
  #define MELT_LENGTH 3
  #define COLOR_START 0.3
  #define COLOR_LENGTH 0.2
  #define WOBBLE_FINISH 0.9
  #define WOBBLE_COUNT 4*2*3.141
#endblock

#block custom_parameters
  #inherited
  float progress, model_height;
#endblock

#block vs_worldposition
  #inherited
  float melt_factor = saturate(progress / MELT_FINISH);
  melt_factor = saturate(melt_factor / (1 - saturate(Worldposition.y / model_height)));

  Worldposition.y = lerp(-MELT_LENGTH * model_height, Worldposition.y, melt_factor);
  
  float wobble_factor = 1 - saturate(progress / WOBBLE_FINISH);
  float3 wobble_lead_vector = float3(sin(wobble_factor * WOBBLE_COUNT), 0, cos(wobble_factor * WOBBLE_COUNT));
  float wobble_strength = saturate(dot(wobble_lead_vector, SmoothedNormal) * 0.1 + 0.01);
  Worldposition.xyz += wobble_lead_vector * wobble_strength * wobble_factor;
#endblock

#block after_pixelshader
  #inherited
  float color_factor = saturate((progress - COLOR_START) / COLOR_LENGTH);
  pso.Color.rgb = lerp(float3(0.15, 0.15, 0.19), pso.Color.rgb, color_factor);
#endblock