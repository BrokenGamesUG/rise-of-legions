#block defines
  #inherited
  #define NEEDWORLD
  #define FADE_LENGTH 0.4
  #define CLIP_SPEED 3.14
  #define GLOW_STRENGTH 0.4
#endblock

#block custom_parameters
  #inherited
  float progress, model_height, glow;
  float3 fading_color;
#endblock

#block after_pixelshader
  #inherited
  #ifdef DIFFUSETEXTURE
    float mask_color = tex2D(VariableTexture3Sampler, psin.Tex).r;
  #else
    float mask_color = 1.0;
  #endif
  float relative_height = psin.WorldPosition.y / model_height;
  float progress_threshold = (1 - (progress * (1 + FADE_LENGTH)));

  clip(-((1 - progress * CLIP_SPEED) - relative_height));

  float value = 1-saturate(-(progress_threshold - relative_height) / FADE_LENGTH + mask_color);

  pso.Color.rgb = lerp(pso.Color.rgb, fading_color, value);
  #ifdef GBUFFER
    #ifdef DRAW_MATERIAL
      pso.MaterialBuffer.a = lerp(pso.MaterialBuffer.a, 1.0, value);
    #endif
  #else
    pso.Color.a = lerp(pso.Color.a, pso.Color.a + value * GLOW_STRENGTH, glow);
  #endif
#endblock
