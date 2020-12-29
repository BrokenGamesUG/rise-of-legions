#block defines
  #inherited
  #define SMOOTHED_NORMAL
#endblock

#block custom_parameters
  float3 fur_move;
  float fur_shell_factor, fur_thickness, fur_gravitation_factor;
#endblock

#block vs_worldposition
  #inherited
  float fur_mask_length = tex2Dlod(VariableTexture1Sampler, float4(vsin.Tex, 0, 0)).g;
  float final_fur_thickness = fur_thickness * (1 - fur_mask_length);
  float3 outset = SmoothedNormal * final_fur_thickness * fur_shell_factor;
  float3 move_vector = fur_move * final_fur_thickness * fur_shell_factor * (dot(fur_move, SmoothedNormal) + 1) * 0.5;
  Worldposition.xyz += outset + move_vector;
  // gravitation
  Worldposition.y -= sin(fur_shell_factor * 3.14 * 0.5) * final_fur_thickness * (-(SmoothedNormal.y - 1) * 0.5 + 0.5) * fur_gravitation_factor;
#endblock

#block after_pixelshader
  float4 fur_mask = tex2D(VariableTexture1Sampler, psin.Tex);
  float fur_mask_shadow = tex2D(VariableTexture1Sampler, psin.Tex + float2(0.02, 0.02)).a;
  pso.Color.rgb = pso.Color.rgb*0.6 * fur_mask_shadow + pso.Color.rgb * (1-fur_mask_shadow);
  pso.Color.a *= fur_mask.a * (1-fur_shell_factor) * fur_mask.r;
#endblock
