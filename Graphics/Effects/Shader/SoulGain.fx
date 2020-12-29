#block defines
  #inherited
  #define NEEDWORLD
  #define SMOOTHED_NORMAL
#endblock

#block custom_parameters
  #inherited
  float soul_gain_progress, soul_gain_radius;
  float4 soul_color;
#endblock

#block vs_worldposition
  #inherited
  // push boundaries outside so the unit has a exploding ghostly hull
  Worldposition.xyz += SmoothedNormal * soul_gain_radius * soul_gain_progress;
#endblock

#block after_pixelshader
  #inherited
  float soul_gain_camera_angle = abs(dot(normalize(psin.SmoothedNormal), CameraDirection));
  soul_gain_camera_angle = 1 - soul_gain_camera_angle;
  pso.Color.rgb = soul_color.rgb;
  pso.Color.a *= saturate(soul_gain_camera_angle) * (1 - soul_gain_progress) * soul_color.a;
#endblock
