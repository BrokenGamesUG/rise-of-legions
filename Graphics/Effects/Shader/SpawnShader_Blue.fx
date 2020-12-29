#block defines
  #inherited
  #define NEEDWORLD
  #define GLOW_STRENGTH 0.1
  #define GLOW_FINISH 1.0
  #define SCALE_OFFSET 0.5
  #define SCALE_FINISH 0.083
  #define ROT_OFFSET 0.166
  #define ROT_FINISH 0.666
#endblock

#block custom_methods
  float cos_lerp(float x){
    float t = (1 + cos(x * 3.141)) / 2;
    return t<0.5 ? 4*t*t*t : (t-1)*(2*t-2)*(2*t-2)+1;
  }
#endblock

#block custom_parameters
  #inherited
  float model_height, progress, glow, pass_progress;
  float3 fading_color;
#endblock

#block vs_worldposition
  float rot_factor = saturate(progress / ROT_FINISH - ROT_OFFSET);
  float rotation = cos_lerp(1 - saturate((rot_factor * 1.0 - 0.4 * pass_progress) * 1.3)) * 2 * 3.141592;
  float3x3 rot_mat = float3x3(cos(rotation),0,sin(rotation),0,1,0,-sin(rotation),0,cos(rotation));
  //float3x3 rot_mat = float3x3(cos(rotation),-sin(rotation),0,sin(rotation),cos(rotation),0,0,0,1);
  float3 temp = pos.xyz;
  temp = mul(rot_mat, temp);
  float scale_progress = saturate(progress / SCALE_FINISH - SCALE_OFFSET);
  pos.xyz = temp * (scale_progress + sin(scale_progress * 3.14159));
  pos.y += 50.0 * model_height * pow((1 - saturate(progress / 0.5 - ROT_OFFSET)), 5);
  float4 Worldposition = mul(World, pos);
#endblock

#block after_pixelshader
  #inherited
  float glow_factor = (1 - saturate(progress / GLOW_FINISH - ROT_OFFSET));
  pso.Color.rgb = lerp(pso.Color.rgb, fading_color, (1 - glow) * glow_factor * 0.7);
  glow_factor *= (pass_progress < 0.01 ? 1.0 : 0.0);
  #ifdef GBUFFER
    #ifdef DRAW_MATERIAL
      pso.MaterialBuffer.a = lerp(pso.MaterialBuffer.a, 1.0, glow_factor);
    #endif
  #else
    pso.Color.a = lerp(pso.Color.a, pso.Color.a / 20.0 + glow_factor * GLOW_STRENGTH, glow);
  #endif
#endblock
