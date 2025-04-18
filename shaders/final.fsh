#version 330 compatibility

#include "/lib/util.glsl"



uniform float exposure;

float LinearToSrgbBranchingChannel(float lin) {
    if (lin < 0.00313067)
        return lin * 12.92;
    return pow(lin, (1.0 / 2.4)) * 1.055 - 0.055;
}
vec3 LinearToSrgb(vec3 lin) {
    return vec3(LinearToSrgbBranchingChannel(lin.r),
                  LinearToSrgbBranchingChannel(lin.g),
                  LinearToSrgbBranchingChannel(lin.b));
}

vec3 uncharted2Tonemap(vec3 x) {
   float A = U2_SHOULDER_STRENGTH;
   float B = U2_LINEAR_STRENGTH;
   float C = U2_LINEAR_ANGLE;
   float D = U2_TOE_STRENGTH;
   float E = U2_TOE_NUMERATOR;
   float F = U2_TOE_DENOMINATOR;
  return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

vec3 uncharted2(vec3 y) {
  const float W = 11.2;
  float exposureBias = 2.0;
  vec3 curr = uncharted2Tonemap(exposureBias * y);
  vec3 whiteScale = 1.0 / uncharted2Tonemap(vec3(W));
  return pow(curr * whiteScale, vec3(1.0/2.2));
}


vec3 aces(vec3 v)
{
      float a = 1.28;
    float b = 0.33;
    float c = 1.33;
    float d = 0.99;
    float e = 0.64;
    return pow(clamp((v*(a*v+b))/(v*(c*v+d)+e), 0.0f, 1.0f), vec3(1.0/2.2));
}


vec3 reinhard_jodie(vec3 v)
{
    float l = luminance(v);
    vec3 tv = v / (2.1 + v);
    return pow(mix(v / (0.7 + l), tv, tv), vec3(1.0/2.2));
}


//adapted from https://github.com/dmnsgn/glsl-tone-map/blob/main/agx.glsl
const mat3 LINEAR_REC2020_TO_LINEAR_SRGB = mat3(
  1.6605, -0.1246, -0.0182,
  -0.5876, 1.1329, -0.1006,
  -0.0728, -0.0083, 1.1187
);

const mat3 LINEAR_SRGB_TO_LINEAR_REC2020 = mat3(
  0.6274, 0.0691, 0.0164,
  0.3293, 0.9195, 0.0880,
  0.0433, 0.0113, 0.8956
);

// Converted to column major from blender: https://github.com/blender/blender/blob/fc08f7491e7eba994d86b610e5ec757f9c62ac81/release/datafiles/colormanagement/config.ocio#L358
const mat3 AgXInsetMatrix = mat3(
  0.856627153315983, 0.137318972929847, 0.11189821299995,
  0.0951212405381588, 0.761241990602591, 0.0767994186031903,
  0.0482516061458583, 0.101439036467562, 0.811302368396859
);

// Converted to column major and inverted from https://github.com/EaryChow/AgX_LUT_Gen/blob/ab7415eca3cbeb14fd55deb1de6d7b2d699a1bb9/AgXBaseRec2020.py#L25
// https://github.com/google/filament/blob/bac8e58ee7009db4d348875d274daf4dd78a3bd1/filament/src/ToneMapper.cpp#L273-L278
const mat3 AgXOutsetMatrix = mat3(
  1.1271005818144368, -0.1413297634984383, -0.14132976349843826,
  -0.11060664309660323, 1.157823702216272, -0.11060664309660294,
  -0.016493938717834573, -0.016493938717834257, 1.2519364065950405
);

const float AgxMinEv = AGX_MIN_EV;
const float AgxMaxEv = AGX_MAX_EV;

// 0: Default, 1: Golden, 2: Punchy
#ifndef AGX_LOOK
  #define AGX_LOOK 2
#endif

vec3 agxAscCdl(vec3 color, vec3 slope, vec3 offset, vec3 power, float sat) {
  const vec3 lw = vec3(0.2126, 0.7152, 0.0722);
  float luma = dot(color, lw);
  vec3 c = pow(color * slope + offset, power);
  return luma + sat * (c - luma);
}

// Sample usage
vec3 agx(vec3 color) {
  color = LINEAR_SRGB_TO_LINEAR_REC2020 * color; // From three.js

  // 1. agx()
  // Input transform (inset)
  color = AgXInsetMatrix * color;

  color = max(color, 1e-10); // From Filament: avoid 0 or negative numbers for log2

  // Log2 space encoding
  color = clamp(log2(color), AgxMinEv, AgxMaxEv);
  color = (color - AgxMinEv) / (AgxMaxEv - AgxMinEv);

  color = clamp(color, 0.0, 1.0); // From Filament

  // Apply sigmoid function approximation
  // Mean error^2: 3.6705141e-06
  vec3 x2 = color * color;
  vec3 x4 = x2 * x2;
  color = + 15.5     * x4 * x2
          - 40.04    * x4 * color
          + 31.96    * x4
          - 6.868    * x2 * color
          + 0.4298   * x2
          + 0.1191   * color
          - 0.00232;

  // 2. agxLook()
  #if AGX_LOOK == 1
    // Golden
    color = agxAscCdl(color, vec3(1.0, 0.9, 0.5), vec3(0.0), vec3(0.8), 1.3);
  #elif AGX_LOOK == 2
    // Punchy
    color = agxAscCdl(color, vec3(1.0), AGX_OFFSET_COLOR, AGX_POWER, AGX_SATURATION);
  #endif

  // 3. agxEotf()
  // Inverse input transform (outset)
  color = AgXOutsetMatrix * color;

  // sRGB IEC 61966-2-1 2.2 Exponent Reference EOTF Display
  // NOTE: We're linearizing the output here. Comment/adjust when
  // *not* using a sRGB render target
  color = pow(max(vec3(0.1922, 0.1922, 0.1922), color), vec3(2.2)); // From filament: max()

  color = LINEAR_REC2020_TO_LINEAR_SRGB * color; // From three.js
  // Gamut mapping. Simple clamp for now.
	color = clamp(color, 0.0, 1.0);

  return color;
}






in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
    
    vec3 exposureCompensation = vec3 (1.0/2.2);
    vec4 bloom = texture(colortex5, texcoord);
   
   
    

    
    #if TONEMAPPING_TYPE == 1
    
        color.rgb = uncharted2(color.rgb);
    
    #elif TONEMAPPING_TYPE == 0
    
         color.rgb = aces(color.rgb);
    #elif TONEMAPPING_TYPE == 2
            color.rgb = reinhard_jodie(color.rgb);  
    #elif TONEMAPPING_TYPE == 3
     color.rgb = agx(color.rgb); 
    #else
        color.rgb = (pow(color.rgb, exposureCompensation));
    #endif

    
  
  


    color.rgb = CSB(color.rgb, brightness, saturation, contrast);
    
}