#block defines
  #inherited
  #define NEEDWORLD
  #define SMOOTHED_NORMAL
  #define STONE_FRACTAL_SIZE 0.05
  #define STONE_COLOR float3(0.31, 0.35, 0.35)
#endblock

#block custom_parameters
  #inherited
  float stone_progress;
#endblock

#block custom_methods
  #inherited

  float stone_hash(float n)
  {
    return frac(sin(n)*43758.5453);
  }

  float stone_noise(float3 x)
  {
    // The stone_noise function returns a value in the range 0.0f -> 1.0f

    float3 p = floor(x);
    float3 f = frac(x);

    f       = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;

    return lerp(lerp(lerp( stone_hash(n+0.0), stone_hash(n+1.0),f.x),
                   lerp( stone_hash(n+57.0), stone_hash(n+58.0),f.x),f.y),
               lerp(lerp( stone_hash(n+113.0), stone_hash(n+114.0),f.x),
                   lerp( stone_hash(n+170.0), stone_hash(n+171.0),f.x),f.y),f.z);
  }
#endblock

#block vs_worldposition
  #inherited
  float stone_fractal = stone_noise(Worldposition.xyz * 50);
  // apply fractal noise to vertstones to look more rough
  Worldposition.xyz += SmoothedNormal * STONE_FRACTAL_SIZE * stone_fractal * stone_progress;
#endblock

#block after_pixelshader
  #inherited
  float3 stone_SmoothedNormal = normalize(psin.SmoothedNormal);
  float stone_edge_angle = abs(dot(stone_SmoothedNormal, float3(0, 1, 0)));
  stone_edge_angle = pow(stone_edge_angle, 8.0) * 0.7 + 0.3;
  float stone_camera_angle = abs(dot(stone_SmoothedNormal, CameraDirection));
  stone_camera_angle = 1 - pow(stone_camera_angle, 0.05);
  float3 stone_color = HSVToRGB(saturate(RGBToHSV(saturate(pso.Color.rgb)) * float3(0.0, 0.3, 0.75) + float3(0.5, 0.0, 0.0)));
  pso.Color.rgb = lerp(pso.Color.rgb, stone_color, stone_progress);
  pso.Color.rgb = lerp(pso.Color.rgb, STONE_COLOR, stone_progress * stone_edge_angle);
  #ifdef GBUFFER
    pso.MaterialBuffer.rg = stone_progress;
    pso.MaterialBuffer.b = 0;
    pso.MaterialBuffer.a = lerp(pso.MaterialBuffer.a, 0.7, stone_camera_angle);
  #endif
#endblock
