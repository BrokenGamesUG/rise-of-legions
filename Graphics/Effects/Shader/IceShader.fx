#block defines
  #inherited
  #define NEEDWORLD
  #define SMOOTHED_NORMAL
  #define FRACTAL_SIZE 0.1
  #define ICE_COLOR float3(0.64, 0.89, 1.0)
  #define ICE_COLOR_EDGE float3(10.0, 10.0, 10.0)
#endblock

#block custom_parameters
  #inherited
  float ice_progress;
#endblock

#block custom_methods
  #inherited

  float ice_hash(float n)
  {
    return frac(sin(n)*43758.5453);
  }

  float ice_noise(float3 x)
  {
    // The ice_noise function returns a value in the range 0.0f -> 1.0f

    float3 p = floor(x);
    float3 f = frac(x);

    f       = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;

    return lerp(lerp(lerp( ice_hash(n+0.0), ice_hash(n+1.0),f.x),
                   lerp( ice_hash(n+57.0), ice_hash(n+58.0),f.x),f.y),
               lerp(lerp( ice_hash(n+113.0), ice_hash(n+114.0),f.x),
                   lerp( ice_hash(n+170.0), ice_hash(n+171.0),f.x),f.y),f.z);
  }
#endblock

#block vs_worldposition
  #inherited
  float ice_fractal = ice_noise(Worldposition.xyz * 50);
  // apply fractal noise to vertices to look more rough
  Worldposition.xyz += SmoothedNormal * FRACTAL_SIZE * ice_fractal * ice_progress;
#endblock

#block after_pixelshader
  #inherited
  float3 ice_SmoothedNormal = normalize(psin.SmoothedNormal);
  float ice_edge_angle = abs(dot(ice_SmoothedNormal, float3(0, 1, 0)));
  ice_edge_angle = pow(ice_edge_angle, 8.0) * 0.7 + 0.3;
  float ice_camera_angle = abs(dot(ice_SmoothedNormal, CameraDirection));
  ice_camera_angle = 1 - pow(ice_camera_angle, 0.05);
  pso.Color.rgb = lerp(pso.Color.rgb, lerp(ICE_COLOR, ICE_COLOR_EDGE, ice_camera_angle), ice_progress * ice_edge_angle);
  #ifdef GBUFFER
    pso.MaterialBuffer.rg = ice_progress;
    pso.MaterialBuffer.b = 0;
    pso.MaterialBuffer.a = lerp(pso.MaterialBuffer.a, 0.7, ice_camera_angle);
  #endif
#endblock
