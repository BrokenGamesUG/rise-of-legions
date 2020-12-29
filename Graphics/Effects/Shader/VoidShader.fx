#block defines
  #inherited
  #define NEEDWORLD
#endblock

#block custom_parameters
  #inherited
  float void_time, void_aspect_ratio, void_screen_aspect_ratio;
#endblock

#block custom_methods
  #inherited

  float2 WorldPositionToTexture(float3 position)
  {
      float4 pos = mul(Projection, mul(View, float4(position, 1)));
      return (float2(pos.x, -pos.y) / pos.w + 1) / 2;
  }
#endblock

#block after_pixelshader
  #inherited
  #if defined(DIFFUSETEXTURE)
    float2 void_uv = WorldPositionToTexture(psin.WorldPosition);// float2(dot(CameraLeft, psin.WorldPosition), dot(CameraUp, psin.WorldPosition)) / 5.0 + float2(void_time, void_time);
    void_uv.y = void_uv.y * void_aspect_ratio / void_screen_aspect_ratio;
    float4 void_color = tex2D(VariableTexture3Sampler, void_uv * 20 + void_time);
    pso.Color.rgb = lerp(pso.Color.rgb, void_color.rgb, void_color.a);
  #endif
#endblock
