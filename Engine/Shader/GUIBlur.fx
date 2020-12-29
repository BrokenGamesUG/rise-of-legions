#block pixelshader_diffuse
  #if defined(VERTEXCOLOR) && defined(DIFFUSETEXTURE)
    pso.Color = tex2D(ColorTextureSampler, psin.Tex);
  #else
    #inherited
  #endif
#endblock

#block color_adjustment
  #if defined(VERTEXCOLOR) && defined(DIFFUSETEXTURE)
    float3 origColor = RGBToHSV(pso.Color.rgb);
    float3 targetColor = RGBToHSV(psin.Color.rgb);
    pso.Color.rgb = HSVToRGB(float3(targetColor.xy, (0.5*origColor.z+0.2) * targetColor.z));
  #endif
#endblock


