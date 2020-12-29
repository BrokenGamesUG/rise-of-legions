#block custom_parameters
  float4 outline_color;
#endblock

#block after_pixelshader
  pso.Color = float4(outline_color.rgb, pso.Color.a * outline_color.a);
#endblock
