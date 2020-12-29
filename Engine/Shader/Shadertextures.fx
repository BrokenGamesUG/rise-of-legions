//Texturslots
texture ColorTexture : register(t0);      //Slot0
texture NormalTexture : register(t1);     //Slot1
texture MaterialTexture : register(t2);   //Slot2
texture VariableTexture1 : register(t3);  //Slot3
texture VariableTexture2 : register(t4);  //Slot4
texture VariableTexture3 : register(t5);  //Slot5
texture VariableTexture4 : register(t6);  //Slot6

//Sampler for texture access
sampler ColorTextureSampler : register(s0) = sampler_state
{
  texture = <ColorTexture>;
};
sampler NormalTextureSampler : register(s1) = sampler_state
{
  texture = <NormalTexture>;
};
sampler MaterialTextureSampler : register(s2) = sampler_state
{
  texture = <MaterialTexture>;
};
sampler VariableTexture1Sampler : register(s3) = sampler_state
{
  texture = <VariableTexture1>;
};
sampler VariableTexture2Sampler : register(s4) = sampler_state
{
  texture = <VariableTexture2>;
};
sampler VariableTexture3Sampler : register(s5) = sampler_state
{
  texture = <VariableTexture3>;
};
sampler VariableTexture4Sampler : register(s6) = sampler_state
{
  texture = <VariableTexture4>;
};
