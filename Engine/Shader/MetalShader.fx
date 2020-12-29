#block defines
  #inherited
  #define NEEDWORLD
#endblock

#block color_adjustment
  #ifdef LIGHTING
    #ifdef MATERIAL
      #ifdef GBUFFER
        #ifdef DRAW_MATERIAL
          float metal = pso.MaterialBuffer.r;
          float tinting = pso.MaterialBuffer.b;
          pso.MaterialBuffer.rgb = 0;
        #else
          float metal = 1;
          float tinting = 0;
        #endif
      #else
        float metal = Specularintensity;
        float tinting = Speculartint;
        #ifdef MATERIALTEXTURE
          metal *= Material.r;
          tinting *= Material.b;
        #endif
      #endif

    #else
      float metal = 0;
      float tinting = 0;
    #endif

    float3 look_dir = normalize(psin.WorldPosition - CameraPosition);
    #ifdef GBUFFER
      float3 reflection_vector = normalize(reflect(look_dir, normalize(pso.NormalBuffer.xyz)));
    #else
      float3 reflection_vector = normalize(reflect(look_dir, normalize(psin.Normal)));
    #endif
    float3 reflected_color = tex2Dlod(VariableTexture2Sampler, float4(SphereMap(reflection_vector), 0, 0)).rgb;

    pso.Color.rgb = lerp(pso.Color.rgb, lerp(reflected_color, pso.Color.rgb * (reflected_color * 1.5 + 0.25), tinting), metal);
  #endif

  #inherited
#endblock

#block shader_version
  #define ps_shader_version ps_3_0
  #define vs_shader_version vs_3_0
#endblock
