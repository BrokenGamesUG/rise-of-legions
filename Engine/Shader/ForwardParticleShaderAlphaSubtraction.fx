#block pixelshader_diffuse
  #ifdef VERTEXCOLOR
    #ifdef DIFFUSETEXTURE
      pso.Color = tex2D(ColorTextureSampler,psin.Tex);
      pso.Color.rgb *= psin.Color.rgb;
      pso.Color.a *= 2;
      pso.Color.a -= psin.Color.a * 2;
    #else
      pso.Color = psin.Color;
    #endif
  #else
    #ifdef DIFFUSETEXTURE
      pso.Color = tex2D(ColorTextureSampler, psin.Tex);
    #else
      pso.Color = float4(0.5, 0.5, 0.5, 1.0);
    #endif
  #endif
#endblock
