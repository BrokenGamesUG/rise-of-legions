#include FullscreenQuadHeader.fx
#define KERNEL_START -3
#define KERNEL_SIZE 7
#define TRANSPARENCY 0.7
#define BORDER_TRANSPARENCY 0.2
#define FADE_LENGTH 5.0
#define FADE_OFFSET 0.3

cbuffer local : register(b1)
{
  float4x4 view_projection_inverse;
  float3 camera_position, mouse_pos;
  float pixelwidth, pixelheight;
};

float hash(float n)
{
  return frac(sin(n)*43758.5453);
}

float pattern(float3 x){
  // The noise function returns a value in the range 0.0f -> 1.0f

  float3 p = floor(x);
  float3 f = frac(x);

  f       = f*f*(3.0-2.0*f);
  float n = p.x + p.y*57.0 + 113.0*p.z;

  return lerp(lerp(lerp( hash(n+0.0), hash(n+1.0),f.x),
                 lerp( hash(n+57.0), hash(n+58.0),f.x),f.y),
             lerp(lerp( hash(n+113.0), hash(n+114.0),f.x),
                 lerp( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
}

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color = tex2D(ColorTextureSampler,psin.Tex);
  pso.Color.a *= TRANSPARENCY;

  // --- highlight border by changing transparency
  float difference = 0;
  for (int i = KERNEL_START; i < KERNEL_SIZE; ++i) {
    for (int j = KERNEL_START; j < KERNEL_SIZE; ++j) {
      float2 offset = float2(pixelwidth * j, pixelheight * i);
      float3 sample = tex2D(ColorTextureSampler, psin.Tex + offset).rgb;
      difference += abs(sample.r - pso.Color.r) + abs(sample.g - pso.Color.g) + abs(sample.b - pso.Color.b);
    }
  }
  difference = saturate(difference) * ((pso.Color.r + pso.Color.g + pso.Color.b <= 0) ? 0 : BORDER_TRANSPARENCY);
  pso.Color.a += difference;

  // --- prepare world position
  // unproject screen coordinate to camera ray
  float4 ndc = float4(psin.Tex * 2 - 1, 0, 1);
  ndc.y *= -1;
  ndc = mul(view_projection_inverse, ndc);
  float3 world_ray_direction = ndc.xyz / ndc.w - camera_position;
  // find world position at XZ plane
  float d = camera_position.y / world_ray_direction.y;
  float3 world_position = camera_position - (d * world_ray_direction);

  // --- add procedural pattern
  pso.Color.rgb = saturate(pso.Color.rgb + float3(1, 1, 0) * pattern(world_position * 80) * 0.2);

  // --- highlight cursor position
  #ifdef HIGHLIGHT_CURSOR
    #ifdef HIGHLIGHT_AREA
      pso.Color.a *= lerp(saturate(1 - distance(mouse_pos, world_position) / FADE_LENGTH), 1, FADE_OFFSET);
    #else
      pso.Color.a *= saturate(1 - distance(mouse_pos, world_position) / FADE_LENGTH);
    #endif
  #else
    pso.Color.a *= FADE_OFFSET;
  #endif

  return pso;
}

#include FullscreenQuadFooter.fx