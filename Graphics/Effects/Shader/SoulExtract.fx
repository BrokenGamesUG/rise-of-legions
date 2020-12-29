#block defines
  #inherited
  #define NEEDWORLD
  #define SMOOTHED_NORMAL
  #define HULL_SIZE 0.1
  #define SOUL_COLOR float3(0.749, 0.992, 0.929)
#endblock

#block custom_parameters
  #inherited
  float soul_progress, soul_height;
  float3 soul_target;
#endblock

#block vs_worldposition
  #inherited
  // push boundaries a bit outside so the unit has a ghostly hull
  Worldposition.xyz += SmoothedNormal * HULL_SIZE;
  // and suck them up to the top
  float3 soul_half = soul_target - Worldposition.xyz;
  Worldposition.y += soul_height * (soul_progress * 2);
  Worldposition.xyz += soul_half * (soul_progress * float3(0.1, 3, 0.1));
  Worldposition.xz = lerp(Worldposition.xz, soul_target.xz, pow(abs(soul_progress), 0.5) - 0.3);
  Worldposition.y += soul_height * soul_progress;
#endblock

#block after_pixelshader
  #inherited
  float soul_camera_angle = abs(dot(normalize(psin.SmoothedNormal), CameraDirection));
  soul_camera_angle = 1 - soul_camera_angle;
  pso.Color.rgb = SOUL_COLOR;
  pso.Color.a *= saturate(soul_camera_angle) * (1 - pow(abs(soul_progress), 0.5));
#endblock
