cbuffer global : register(b0)
{
  float4x4 View, Projection;
  float3 DirectionalLightDir;
  float4 DirectionalLightColor;
  float3 Ambient;
  float3 CameraPosition, CameraUp, CameraLeft, CameraDirection;
  float2 viewport_size;
};

#define MAX_BONES 66

static const float PI = 3.14159265f;

#define GAUSS_0 {0.44198, 0.27901}
#define GAUSS_1 {0.250301, 0.221461, 0.153388}
#define GAUSS_2 {0.214607, 0.189879, 0.131514, 0.071303}
#define GAUSS_3 {0.20236, 0.179044, 0.124009, 0.067234, 0.028532}
#define GAUSS_4 {0.198596, 0.175713, 0.121703, 0.065984, 0.028002, 0.0093}

#define GAUSS_0_ADDITIVE {1.0, 0.63127}
#define GAUSS_1_ADDITIVE {1.0, 0.88478, 0.61281}
#define GAUSS_2_ADDITIVE {1.0, 0.88478, 0.61281, 0.33224}
#define GAUSS_3_ADDITIVE {1.0, 0.88478, 0.61281, 0.33224, 0.14099}
#define GAUSS_4_ADDITIVE {1.0, 0.88478, 0.61281, 0.33224, 0.14099, 0.04683}

float sqr(float value){
  return value*value;
}

float3 BeleuchtungsBerechnung(float3 Normale,float3 Licht){
  //normale Beleuchtung + Ambient
  //Berechnung ist physikalisch falsch sieht aber besser aus
  float Diffus = saturate(dot(Normale,Licht))*1.5;
  float InverseDiffus = saturate(dot(Normale,-Licht))*1.5;
  return (Diffus+Ambient*(InverseDiffus-Diffus+1)+Ambient);
}

float3 BeleuchtungsBerechnungMitSchatten(float3 Normale,float3 Licht, float Shadowstrength){
  //normale Beleuchtung + Ambient
  //Berechnung ist physikalisch falsch sieht aber besser aus
  float Diffus = saturate(dot(Normale,Licht))*1.5 * (1-Shadowstrength);
  float InverseDiffus = saturate(dot(Normale,-Licht))*1.5;
  return (Diffus+Ambient*(InverseDiffus-Diffus+1)+Ambient);
}

/////////////////////////////////////////////
// HSV //////////////////////////////////////
/////////////////////////////////////////////

float MinComponent(float3 v)
{
    float t = (v.x<v.y) ? v.x : v.y;
    t = (t<v.z) ? t : v.z;
    return t;
}

float MaxComponent(float3 v)
{
    float t = (v.x>v.y) ? v.x : v.y;
    t = (t>v.z) ? t : v.z;
    return t;
}

float3 RGBToHSV(float3 RGB)
{
    float3 HSV = 0;
    float minVal = MinComponent(RGB);
    float maxVal = MaxComponent(RGB);
    float delta = maxVal - minVal;             
    HSV.z = maxVal;
    if (delta != 0) {            // If gray, leave H & S at zero
       HSV.y = delta / maxVal;
       float3 delRGB;
       delRGB = ( ( ( maxVal.xxx - RGB ) / 6.0 ) + ( delta / 2.0 ) ) / delta;
       if      ( RGB.x == maxVal ) HSV.x = delRGB.z - delRGB.y;
       else if ( RGB.y == maxVal ) HSV.x = ( 1.0/3.0) + delRGB.x - delRGB.z;
       else if ( RGB.z == maxVal ) HSV.x = ( 2.0/3.0) + delRGB.y - delRGB.x;
       if ( HSV.x < 0.0 ) { HSV.x += 1.0; }
       if ( HSV.x > 1.0 ) { HSV.x -= 1.0; }
    }
    return (HSV);
}

float3 HSVToRGB(float3 HSV)
{
    float3 RGB = HSV.z;
    if ( HSV.y != 0 ) {
       float var_h = HSV.x * 6;
       float f = frac(var_h);
       float p = HSV.z * (1.0 - HSV.y);
       float q = HSV.z * (1.0 - HSV.y * f);
       float t = HSV.z * (1.0 - HSV.y * (1.0 - f));
       if      (var_h < 1) { RGB = float3(HSV.z, t, p); }
       else if (var_h < 2) { RGB = float3(q, HSV.z, p); }
       else if (var_h < 3) { RGB = float3(p, HSV.z, t); }
       else if (var_h < 4) { RGB = float3(p, q, HSV.z); }
       else if (var_h < 5) { RGB = float3(t, p, HSV.z); }
       else if (var_h < 6) { RGB = float3(HSV.z, p, q); }
       else                { RGB = float3(HSV.z, t, p); }
   }
   return (RGB);
}

// from : http://www.chilliant.com/rgb2hsv.html

float3 HUEtoRGB(in float H)
{
  float R = abs(H * 6 - 3) - 1;
  float G = 2 - abs(H * 6 - 2);
  float B = 2 - abs(H * 6 - 4);
  return saturate(float3(R,G,B));
}

float Epsilon = 1e-10;

float3 RGBtoHCV(in float3 RGB)
{
  // Based on work by Sam Hocevar and Emil Persson
  float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0/3.0) : float4(RGB.gb, 0.0, -1.0/3.0);
  float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
  float C = Q.x - min(Q.w, Q.y);
  float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
  return float3(H, C, Q.x);
}

// The weights of RGB contributions to luminance.
// Should sum to unity.
float3 HCYwts = float3(0.299, 0.587, 0.114);

float3 HCYtoRGB(in float3 HCY)
{
  float3 RGB = HUEtoRGB(HCY.x);
  float Z = dot(RGB, HCYwts);
  if (HCY.z < Z)
  {
      HCY.y *= HCY.z / Z;
  }
  else if (Z < 1)
  {
      HCY.y *= (1 - HCY.z) / (1 - Z);
  }
  return (RGB - Z) * HCY.y + HCY.z;
}

float3 RGBtoHCY(in float3 RGB)
{
  float3 HCV = RGBtoHCV(RGB);
  float Y = dot(RGB, HCYwts);
  if (HCV.y != 0)
  {
    float Z = dot(HUEtoRGB(HCV.x), HCYwts);
    if (Y > Z)
    {
      Y = 1 - Y;
      Z = 1 - Z;
    }
    HCV.y *= Z / Y;
  }
  return float3(HCV.x, HCV.y, Y);
}

float3 RGBtoHSL(in float3 RGB)
{
  float3 HCV = RGBtoHCV(RGB);
  float L = HCV.z - HCV.y * 0.5;
  float S = HCV.y / (1 - abs(L * 2 - 1) + Epsilon);
  return float3(HCV.x, S, L);
}

float3 HSLtoRGB(in float3 HSL)
{
  float3 RGB = HUEtoRGB(HSL.x);
  float C = (1 - abs(2 * HSL.z - 1)) * HSL.y;
  return (RGB - 0.5) * C + HSL.z;
}

/////////////////////////////////////////////
// Generate texturecoordinates //////////////
/////////////////////////////////////////////

/*
  Converts a Normal to a texturecoordinate for a sphere with only a normal 2D-Texture.
*/
float2 SphereMap(float3 Normal)
{
   return float2(atan2(Normal.x,Normal.z)/(2*PI) + 0.5,(asin(-Normal.y)/PI + 0.5));
}

/*
  Converts a Normal to a texturecoordinate for a cubemap with only a normal 2D-Texture. Should be optimized.
*/
float2 CubeMap(float3 Normal){
  float2 newTex;
  float3 absNormal = float3(abs(Normal.x),abs(Normal.y),abs(Normal.z));
  float3 tempNormal = (Normal / max(absNormal.x,max(absNormal.y,absNormal.z)));
  if (absNormal.z>=absNormal.x) {
    if (absNormal.y>=absNormal.x) {
      if (absNormal.z>=absNormal.y) {
        newTex.x = -tempNormal.x*sign(tempNormal.z);
        newTex.y = -tempNormal.y;
      } else {
        newTex.x = tempNormal.x*sign(tempNormal.y);
        newTex.y = tempNormal.z;
      }
    } else {
      newTex.x = -tempNormal.x*sign(tempNormal.z);
      newTex.y = -tempNormal.y;
    }
    } else {
    if (absNormal.x>=absNormal.y) {
      if (absNormal.z>=absNormal.y) {
        newTex.x = tempNormal.z*sign(tempNormal.x);
        newTex.y = -tempNormal.y;
      } else {
        newTex.x = tempNormal.z*sign(tempNormal.x);
        newTex.y = -tempNormal.y;
      }
    } else {
      newTex.x = tempNormal.x*sign(tempNormal.y);
      newTex.y = tempNormal.z;
    }
  }
	return (newTex*0.5+0.5);
}