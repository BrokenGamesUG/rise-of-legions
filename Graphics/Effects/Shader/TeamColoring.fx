#block custom_parameters
  #inherited
  float new_hue;
#endblock

#block after_pixelshader
  #inherited
  #if defined(DIFFUSETEXTURE)
    float mask_color = tex2D(VariableTexture3Sampler, psin.Tex).r;
    float3 hsv = RGBToHSV(pso.Color.rgb);
    hsv.x = lerp(hsv.x, new_hue, mask_color);
    pso.Color.rgb = HSVToRGB(hsv);
  #endif
#endblock
