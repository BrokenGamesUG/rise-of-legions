#block defines
  #define NEEDWORLD
#endblock

#block custom_parameters
  #inherited
  float dsb_progress;
#endblock

#block custom_methods
  #inherited

  float dsb_powlerp(float x){
    float t = x - 1;
    return t * t * t + 1;
  }

  float dsb_hash(float n)
  {
    return frac(sin(n) * 43758.5453);
  }

  float dsb_noise(float3 x)
  {
    // The dsb_noise function returns a value in the range 0.0f -> 1.0f

    float3 p = floor(x);
    float3 f = frac(x);

    f       = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 57.0 + 113.0 * p.z;

    return lerp(lerp(lerp( dsb_hash(n + 0.0), dsb_hash(n + 1.0), f.x),
                   lerp( dsb_hash(n + 57.0), dsb_hash(n + 58.0), f.x), f.y),
               lerp(lerp( dsb_hash(n + 113.0), dsb_hash(n + 114.0), f.x),
                   lerp( dsb_hash(n + 170.0), dsb_hash(n + 171.0), f.x), f.y), f.z);
  }
#endblock

#block after_pixelshader
  #inherited
  float progress = dsb_powlerp(dsb_progress);
  clip((dsb_noise(psin.WorldPosition * 12.0)) - progress - 0.001);

  progress = saturate(progress * 4.0);
  pso.Color.rgb = lerp(pso.Color.rgb, float3(0.15, 0.15, 0.19), progress);
  #ifdef GBUFFER
    pso.MaterialBuffer.rg = 1 - progress;
    pso.MaterialBuffer.b = progress;
    pso.MaterialBuffer.a = progress;
  #endif
#endblock

#block shadow_clip_test
  #inherited
  float progress = dsb_powlerp(dsb_progress);
  clip((dsb_noise(psin.WorldPosition * 12.0))  - progress - 0.001);
#endblock
