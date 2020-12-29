technique MegaTec
{
   pass p0
   {
      VertexShader = compile vs_3_0 MegaVertexShader();
      PixelShader = compile ps_3_0 MegaPixelShader();
   }
}