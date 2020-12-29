#block defines
  #inherited
  #define FALL_HEIGHT 4.0
  #define SPHERE_RADIUS 0.15
  #define GLOW_STRENGTH 0.8
  #define FALL_FINISH 0.1
  #define SEED_FINISH 0.4
  #define GROW_FINISH 0.7

  float powlerp(float x){
    float t = x - 1;
    return t*t*t*t*t + 1;
  }
#endblock

#block custom_parameters
  #inherited
  float progress, glow;
  float3 object_position;
  float3 fading_color;
#endblock

#block vs_worldposition
  #inherited
  float3 center = object_position;
  center.y += SPHERE_RADIUS * 2;
  float3 between = Worldposition.xyz - center;
  float fall_factor = saturate(progress / FALL_FINISH);
  float seed_factor = saturate((progress - FALL_FINISH) / (SEED_FINISH - FALL_FINISH));
  float grow_factor = saturate((progress - SEED_FINISH) / (GROW_FINISH - SEED_FINISH));

  float3 between_factor = 1 / lerp(length(between) / (SPHERE_RADIUS * lerp(2, 3, seed_factor)), 1.0, powlerp(grow_factor));
  float spawn_factor = powlerp(fall_factor) * 0.5 + 0.5;
  float squash_factor = (1 - sin(PI * saturate(seed_factor * 3))) * 0.3 + 0.7;
  Worldposition.xyz = center + between * between_factor * spawn_factor * float3(1 / squash_factor, squash_factor, 1 / squash_factor);

  Worldposition.y += lerp(FALL_HEIGHT, 0, fall_factor);
#endblock

#block after_pixelshader
  #inherited
  float glow_factor = 1 - saturate((progress - GROW_FINISH) / (1.0 - GROW_FINISH));
  float seed_factor = saturate((progress - FALL_FINISH) / (SEED_FINISH - FALL_FINISH));
  pso.Color.rgb = lerp(float3(0.49, 0.38, 0.27), pso.Color.rgb, seed_factor);
  #ifdef GBUFFER
    #ifdef DRAW_MATERIAL
      pso.MaterialBuffer.a = lerp(pso.MaterialBuffer.a, 1.0, glow_factor);
    #endif
  #else
    pso.Color.a = lerp(pso.Color.a, pso.Color.a + glow_factor * GLOW_STRENGTH, glow * seed_factor);
  #endif
#endblock
