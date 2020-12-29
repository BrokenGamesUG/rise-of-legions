#block defines
  #inherited
  #define SPHERIFY_RADIUS 0.15
#endblock

#block custom_parameters
  #inherited
  float spherify, spherify_pow_factor;
  float3 spherify_center;
#endblock

#block vs_worldposition
  #inherited
  float3 between = Worldposition.xyz - spherify_center;
  float3 between_factor = 1 / lerp(1.0, length(between) / (SPHERIFY_RADIUS * 2), -pow(abs(1 - spherify), spherify_pow_factor) + 1);
  Worldposition.xyz = spherify_center + between * between_factor;
#endblock
