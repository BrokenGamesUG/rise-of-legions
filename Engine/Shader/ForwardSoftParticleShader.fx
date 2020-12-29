#block custom_parameters
  float Softparticlerange;
#endblock

#block vs_output
  float3 Worldposition : TEXCOORD5;
#endblock

#block after_vertexshader
  vsout.Worldposition = Worldposition.xyz;
#endblock

#block ps_input
  float3 Worldposition : TEXCOORD5;
  float2 vPos : VPOS;
#endblock

#block after_pixelshader
  float2 pixel_tex = (psin.vPos.xy + float2(0.5, 0.5)) / viewport_size;
  float particle_depth = distance(psin.Worldposition, CameraPosition);
  float Depth = tex2Dlod(VariableTexture1Sampler, float4(pixel_tex, 0, 0)).a;
  pso.Color.a = pso.Color.a * saturate((Depth - particle_depth) / Softparticlerange);
#endblock

#block shader_version
  #define ps_shader_version ps_3_0
  #define vs_shader_version vs_3_0
#endblock
