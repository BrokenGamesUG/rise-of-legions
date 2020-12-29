#block custom_parameters
  #inherited
  float4 co_color;
  bool co_additive;
#endblock

#block after_pixelshader
  if (co_additive)
    pso.Color.rgb += co_color.rgb * co_color.a;
  else
    pso.Color.rgb = lerp(pso.Color.rgb, co_color.rgb, co_color.a);
  #inherited
#endblock
