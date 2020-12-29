#block defines
  #inherited
  #define SMOOTHED_NORMAL
#endblock

#block custom_parameters
  #inherited
  float4 ghost_color;
  float ghost_factor, ghost_offset;
  bool ghost_additive;
#endblock

#block after_pixelshader
  #inherited
  float ghost_camera_angle = abs(dot(normalize(psin.SmoothedNormal), CameraDirection));
  ghost_camera_angle = (1 - ghost_camera_angle) * ghost_factor + ghost_offset;
  float ghost_factor = saturate(ghost_camera_angle) * ghost_color.a;
  if (ghost_additive)
    pso.Color.rgb += ghost_color.rgb * ghost_factor;
  else
    pso.Color.rgb = lerp(pso.Color.rgb, ghost_color.rgb, ghost_factor);
#endblock
