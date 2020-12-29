#block defines
  #inherited
  #define NEEDWORLD
  #define SMOOTHED_NORMAL
  #define FADE_PERCENTAGE 3
#endblock

#block custom_parameters
  float progress, model_height;
  float3 fading_color;
#endblock

#block color_adjustment
  #ifdef GBUFFER
    float3 look_dir = normalize(psin.WorldPosition - CameraPosition);
    float edge_angle = abs(dot(normalize(psin.SmoothedNormal), look_dir));
    edge_angle = sqrt(edge_angle);
    pso.Color.rgb = lerp(float3(0.25, 0.99, 1.0), float3(0.361, 0.376, 0.376), edge_angle);
    pso.MaterialBuffer.rg = 0;
    pso.MaterialBuffer.b = 1;
  #else
    pso.Color.rgb *= 0.5;
  #endif

  #inherited
#endblock

#block after_pixelshader
  float mask_color = tex2D(VariableTexture2Sampler, psin.Tex).r;
  float value = saturate(-((progress - mask_color * 0.2) - (psin.WorldPosition.y / model_height)) * FADE_PERCENTAGE);
  clip((1.0 - value) - 0.001);

  pso.Color.rgb = lerp(pso.Color.rgb, lerp(fading_color, float3(1.0,1.0,1.0), pow(value, 4.0)), value);
  #ifdef GBUFFER
    #ifdef DRAW_MATERIAL
      pso.MaterialBuffer.a = lerp(pso.MaterialBuffer.a, 1.0, value);
    #endif
  #else
    pso.Color.a = lerp(pso.Color.a, 0.0, value);
  #endif
#endblock








