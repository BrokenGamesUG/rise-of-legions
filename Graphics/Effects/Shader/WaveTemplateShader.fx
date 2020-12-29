#block defines
  #inherited
  #define SMOOTHED_NORMAL
#endblock

#block color_adjustment
  #ifdef GBUFFER
    float3 SmoothedNormal = normalize(psin.SmoothedNormal);
    float3 look_dir = normalize(psin.WorldPosition - CameraPosition);
    float edge_angle = abs(dot(SmoothedNormal, look_dir));
    edge_angle = sqrt(edge_angle);
    pso.Color.rgb = lerp(float3(0.25, 0.99, 1.0), float3(0.361, 0.376, 0.376), edge_angle);
    pso.MaterialBuffer.rg = 0;
    pso.MaterialBuffer.b = 1;
  #else
    pso.Color.rgb *= 0.5;
  #endif

  #inherited
#endblock
