#block defines
  #inherited
  #define NEEDWORLD
#endblock

#block custom_parameters
  #inherited
  float time;
#endblock

#block vs_worldposition
  #inherited
  float wobble = 1 - tex2Dlod(VariableTexture3Sampler, float4(vsin.Tex, 0, 0)).r;
  float3 x = time * float3(0.1, 0.2, 0.1) * 6.0 + Worldposition.xyz * 0.3;
  float3 supersin = cos(x * PI) * cos(x * 3 * PI) * cos(x * 5 * PI) * cos(x * 7 * PI) + sin(x * 25 * PI) * 0.1;
  Worldposition.xyz += wobble * supersin * 0.3;

  #ifdef LIGHTING
    normal += wobble * supersin * 0.6;
  #endif
#endblock
