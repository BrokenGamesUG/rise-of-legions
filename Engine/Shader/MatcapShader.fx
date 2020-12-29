#block defines
  #inherited
  #define NEEDWORLD
#endblock

#block custom_methods
   #inherited
  /*
    Converts a Normal to a texturecoordinate for a screen aligned half sphere with only a normal 2D-Texture.
  */
  float2 MatcapMap(float3 Normal)
  {
     float x = dot(CameraLeft, Normal);
     float y = dot(CameraUp, Normal);
     return float2(x, y) * -0.5 + 0.5;
  }
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
      float3 reflection_vector = normalize(pso.NormalBuffer.xyz);
    #else
      float3 reflection_vector = normalize(psin.Normal);
    #endif
    float4 reflected_color = tex2Dlod(VariableTexture2Sampler, float4(MatcapMap(reflection_vector), 0, 0)).rgba;

    pso.Color.rgb = lerp(pso.Color.rgb, lerp(reflected_color.rgb, pso.Color.rgb * reflected_color.rgb, tinting), metal);
    pso.Color.a *= reflected_color.a;
  #endif

  #inherited
#endblock

#block shader_version
  #define ps_shader_version ps_3_0
  #define vs_shader_version vs_3_0
#endblock
