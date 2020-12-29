#block custom_parameters
  float timekey;
  float viewportwidth, viewportheight;
#endblock

#block ps_input
  float2 vPos : VPOS;
#endblock

#block vs_worldposition
  // wafting
  float4 Worldposition = float4(pos.xyz + float3(sin(pos.x+timekey), cos(pos.y+timekey), sin(pos.z + timekey)) * 0.1, 1.0);
#endblock

#block pixelshader_diffuse


  // distortion
  float2 screen_tex = (psin.vPos.xy + float2(0.5, 0.5)) / viewport_size;

  float2 ntex = (psin.Tex + float2(0.4, -0.5) * timekey * 0.1) * 3;
  float2 normal = tex2D(NormalTextureSampler, ntex).rg;
  float2 normal_offset = (2*normal-1.0) * (1-psin.Tex.y);

  float2 tex1 = (psin.Tex + float2(0.23, 0.14) + float2(0.4, -0.5) * timekey * 0.1) * 1;
  float2 tex2 = (psin.Tex + float2(0.68, 0.54) + float2(-0.6, -0.5) * timekey * 0.05) * 1.5;
  float2 tex3 = (psin.Tex + float2(0.33, 0.94) + float2(-0.2, -0.5) * timekey * 0.025) * 1.8;
  float4 color1 = tex2D(ColorTextureSampler,tex1);
  float4 color2 = tex2D(ColorTextureSampler,tex2);
  float4 color3 = tex2D(ColorTextureSampler,tex3);
  pso.Color.rgb = saturate((color1.rgb + color2.rgb + color3.rgb) / 3 * psin.Color.rgb);
  pso.Color.a = saturate(psin.Color.a);

  screen_tex = screen_tex + normal_offset * 0.005 * psin.Color.a;

  float3 screen_color = tex2D(VariableTexture2Sampler, screen_tex).rgb;

  float3 shield_color = saturate((pso.Color.rgb * (sqr(sqr(1-psin.Tex.y)))) + float3(0.4921875,0.71875,0.9375) * 0.4 * (sqr(1-psin.Tex.y)) * pso.Color.a) ;

  pso.Color.rgb = 1 - (1 - screen_color) * (1 - shield_color * saturate(psin.Tex.y/0.02));
  pso.Color.a = 1;
#endblock

#block shader_version
	#define ps_shader_version ps_3_0
  #define vs_shader_version vs_3_0
#endblock
