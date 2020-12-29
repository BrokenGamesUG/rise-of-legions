#include FullscreenQuadHeader.fx

float3 CameraUp,CameraLeft;

PSOutput MegaPixelShader(VSOutput psin){
  PSOutput pso;
  pso.Color.a = 1;
  float4 NormalDepth = tex2D(ColorTextureSampler,psin.Tex);
  float3 Normal = normalize(NormalDepth.xyz);
  float Up = dot(normalize(CameraUp),Normal);
  float Left = dot(normalize(CameraLeft),Normal);
  float3 newNormal = (float3(-Left,-Up,1-sqrt(Left*Left+Up*Up)))/2+0.5;
  pso.Color.rgb = (NormalDepth.w==0)?float3(0.5,0.5,1):((newNormal));
  return pso;
}

#include FullscreenQuadFooter.fx