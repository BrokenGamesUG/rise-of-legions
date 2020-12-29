#block defines
  #define NEEDWORLD
  #define SMOOTHED_NORMAL
  #define EXPLOSION_SIZE 0.5
#endblock

#block custom_parameters
  #inherited
  float explosion_progress;
  float3 explosion_color;
#endblock

#block custom_methods
  #inherited

  float powlerp(float x){
    float t = x - 1;
    return t*t*t + 1;
  }

  float hash(float n)
  {
    return frac(sin(n)*43758.5453);
  }

  float noise(float3 x)
  {
    // The noise function returns a value in the range 0.0f -> 1.0f

    float3 p = floor(x);
    float3 f = frac(x);

    f       = f*f*(3.0-2.0*f);
    float n = p.x + p.y*57.0 + 113.0*p.z;

    return lerp(lerp(lerp( hash(n+0.0), hash(n+1.0),f.x),
                   lerp( hash(n+57.0), hash(n+58.0),f.x),f.y),
               lerp(lerp( hash(n+113.0), hash(n+114.0),f.x),
                   lerp( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
  }
#endblock

#block vs_worldposition
  pos.xz *= 1 + explosion_progress * 0.5;
  float4 Worldposition = mul(World, pos);
  float t = explosion_progress - 1;
  t = t*t*t + 1;
  Worldposition.xyz += SmoothedNormal * EXPLOSION_SIZE * t;
  Worldposition.y *= saturate(1 - explosion_progress * 1.5) + 0.1;
#endblock

#block after_pixelshader
  #inherited
  float progress = powlerp(explosion_progress);
  clip((noise(psin.WorldPosition * 12.0))  - progress - 0.001);

  float3 SmoothedNormal = normalize(psin.SmoothedNormal);
  float3 look_dir = normalize(psin.WorldPosition - CameraPosition);
  float edge_angle = abs(dot(SmoothedNormal, look_dir)) * progress;
  pso.Color.rgb = lerp(pso.Color.rgb, lerp(explosion_color, float3(1, 1, 1), edge_angle), saturate(progress * 4.0));
  #ifdef GBUFFER
    pso.MaterialBuffer.rg = 1 - progress;
    pso.MaterialBuffer.b = progress;
    pso.MaterialBuffer.a = 1;
  #endif
#endblock

#block shadow_clip_test
  #inherited
  float progress = powlerp(explosion_progress);
  clip((noise(psin.WorldPosition * 12.0))  - progress - 0.001);
#endblock
