#block after_pixelshader
  float2 pixel_tex = (psin.vPos.xy + float2(0.5, 0.5)) / viewport_size;
  float particle_depth = distance(psin.Worldposition, CameraPosition);
  float Depth = tex2Dlod(VariableTexture1Sampler, float4(pixel_tex, 0, 0)).a;
  Depth = (Depth == 0) ? 1000.0 : Depth;
  pso.Color.a = pso.Color.a * saturate((Depth - particle_depth) / Softparticlerange);
#endblock

