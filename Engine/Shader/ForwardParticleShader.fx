#block vs_input_override
  float3 Position : POSITION0;
  float3 Normal : NORMAL0;
  float4 Color : COLOR0;
  float2 Tex : TEXCOORD0;
  float3 Size : TEXCOORD1;
#endblock

#block pixelshader_diffuse
  #inherited
  clip(pso.Color.a-0.001);
#endblock
