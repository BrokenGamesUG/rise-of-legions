#block defines
  #inherited
  #define NEEDWORLD
#endblock

#block custom_parameters
  #inherited
  float melt_progress, melt_model_height, melt_step;
  float3 melt_ref;
#endblock

#block vs_worldposition
  #inherited
  float melt_threshold = (1 - melt_progress) * melt_model_height;
  float3 melt_direction = Worldposition.xyz - melt_ref;
  float melt_length = length(melt_direction);
  float melt_factor = saturate((melt_threshold - melt_length) / melt_step);
  // add a little height to prevent z-fighting)
  //Worldposition.y = lerp(melt_threshold, Worldposition.y, melt_factor) + (Worldposition.y / melt_model_height) * 0.1;

  Worldposition.xyz = lerp(melt_ref + melt_direction / melt_length * melt_threshold, Worldposition.xyz, melt_factor) + melt_direction * (melt_length / melt_model_height) * 0.1 * melt_factor;
#endblock

#block after_vertexshader
  #inherited
  #ifdef LIGHTING
    // surface is sphere so adjust normals
    vsout.Normal = lerp(melt_direction, vsout.Normal, melt_factor);
  #endif
#endblock
