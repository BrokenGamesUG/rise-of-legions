#include FullscreenQuadHeader.fx

cbuffer local : register(b1) {
  float pixelwidth, pixelheight, positionbias, normalbias;
};

PSOutput MegaPixelShader(VSOutput psin) {
  PSOutput pso;
  // determine edge ------------------------------------------------------------
  pso.Color.a = 0;
  float4 center = tex2D(NormalTextureSampler, psin.Tex);
  float4 up = tex2D(NormalTextureSampler, psin.Tex + float2(0, -pixelheight));
  float4 left = tex2D(NormalTextureSampler, psin.Tex + float2(-pixelwidth, 0));
  float4 right = tex2D(NormalTextureSampler, psin.Tex + float2(pixelwidth, 0));
  float4 down = tex2D(NormalTextureSampler, psin.Tex + float2(0, pixelheight));
  // position
  float distance = sqr(center.a - up.a);
  distance += sqr(center.a - left.a);
  distance += sqr(center.a - right.a);
  distance += sqr(center.a - down.a);
  pso.Color.a += saturate(distance - positionbias);
  // normal
  float normal = dot(center.rgb, up.rgb);
  normal += dot(center.rgb, left.rgb);
  normal += dot(center.rgb, right.rgb);
  normal += dot(center.rgb, down.rgb);
  // uses hard normaldifferences, if background (normal = zero vector) don't detect
  pso.Color.a += saturate(normalbias - normal) * length(center.rgb);

  // blur edge -----------------------------------------------------------------
  #ifdef DRAW_EDGES
    pso.Color.rbg = float3(1.0,0.0,0.0);
  #else
    // average color => blur
    float3 CCenter = tex2D(VariableTexture1Sampler, psin.Tex).rgb;
    float3 CUp = tex2D(VariableTexture1Sampler, psin.Tex + float2(0, -pixelheight)).rgb;
    float3 CLeft = tex2D(VariableTexture1Sampler, psin.Tex + float2(-pixelwidth, 0)).rgb;
    float3 CRight = tex2D(VariableTexture1Sampler, psin.Tex + float2(pixelwidth, 0)).rgb;
    float3 CDown = tex2D(VariableTexture1Sampler, psin.Tex + float2(0, pixelheight)).rgb;
    pso.Color.rgb = (CCenter + CUp + CLeft + CRight + CDown) / 5.0;
  #endif

  return pso;
}

#include FullscreenQuadFooter.fx
