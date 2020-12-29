#block custom_parameters
  float time;
  float3 WindDirection;
#endblock

#block vs_input
  float4 Wind : TEXCOORD1;
#endblock

#block pre_vertexshader
  float x = time / 15 + vsin.Wind.y + dot(WindDirection, vsin.Position.xyz) / 10 * vsin.Wind.x;
  float supersin = cos(x * PI) * cos(x * 3 * PI) * cos(x * 5 * PI) * cos(x * 7 * PI) + sin(x * 25 * PI) * 0.1;
  vsin.Position.xyz += supersin * vsin.Wind.z * WindDirection;
#endblock
