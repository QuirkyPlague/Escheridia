#ifndef COMMON_GLSL
#define COMMON_GLSL

/*
const int colortex0Format = RGB16F;
const int colortex5Format = RGB16F;
const int colortex1Format = RGB16F;
const int colortex6Format = RGB16F;
const int colortex7Format = RGB16F;
const int specularFormat = RGB16F;
const int colortex2Format = RGB16F;
const bool normalsMipmapEnabled = true;
const bool shadowHardwareFiltering = true;
*/

//lighting
#define SUN_ILLUMINANCE 1.0 //[1.0 2.0 3.0 4.0 5.0 10.0 26.0 48.0 126.0]
#define MOON_ILLUMINANCE 0.5 //[0.5 1.0 1.5 2.0 2.5 3.0]
#define FOG_DENSITY 5.0 //[3.0 4.0 5.0 6.0 7.0 8.0 9.0]
#define WATER_FOG_DENSITY 1.0 //[0.0 0.2 0.4 0.6 0.8 1.0]
#define LIGHT_INTENSITY 1.0 //[1.0 2.0 3.0 4.0 5.0]
#define SKY_INTENSITY 1.0 //[1.0 2.0 3.0 4.0 5.0 10.0 25.0]
#define NIGHT_SKY_INTENSITY 1.0 //[1.0 2.0 3.0 4.0 5.0 10.0 25.0]
#define SUN_ROTATION -30 //[-45 -30 -15 0 15 30 45]

//sun/moon
#define SUN_R 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define SUN_G 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define SUN_B 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define MOON_R 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define MOON_G 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define MOON_B 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]

#define U2_SHOULDER_STRENGTH 0.6
#define U2_LINEAR_STRENGTH   0.22
#define U2_LINEAR_ANGLE      0.7
#define U2_TOE_STRENGTH      0.9
#define U2_TOE_NUMERATOR     0.01
#define U2_TOE_DENOMINATOR  0.7

#define AGX_SATURATION 1.0
#define AGX_MIN_EV (-13.17393)
#define AGX_MAX_EV (3.026069)
#define AGX_POWER vec3(1.0)
#define AGX_OFFSET_COLOR vec3(0.0)
#define TONEMAPPING_TYPE 3 //[0 1 2 3 4]

//shadows
#define SHADOW_SOFTNESS  2 //[2 3 4 5 6 7 8 9 10]
#define SHADOW_QUALITY 4 //[2 4 6 8 10 12 14 16]
#define SHADOW_MAP_RESOLUTION 2048 //[512 1024 2048 4096 8192 16384]
#define DO_SOFT_SHADOW 1 //[0 1]

#define DO_WATER_FOG 1 //[0 1]
#define DO_DISTANCE_FOG 1 //[0 1]


//Godrays Config
#define GODRAYS_ENABLE 1 //[0 1]
#define GODRAYS_SAMPLES 24 //[6 12 18 24 36 128 256 512 1024 2048 4096]
#define GODRAYS_EXPOSURE 0.4 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define GODRAY_ASYMMETRY 0.75 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95]
#define GODRAY_DENSITY 1.0 //[0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0 2.2 2.4 2.6 2.8 3.0 3.2 3.4 3.6 3.8 4.0 4.2 4.4 4.6 4.8 5.0]
#define GODRAY_R 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define GODRAY_G 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]
#define GODRAY_B 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]

//Bloom Config
#define DO_BLOOM 1 //[0 1]
#define BLOOM_STRENGTH 0.7  //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
#define BLOOM_THRESHOLD 1.0
#define BLOOM_INTENSITY 1.0//[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define BLOOM_QUALITY 1.0
#define BLOOM_RADIUS 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7 3.8 3.9 4.0]
#define DO_AMD_SKY_FIX 0 //[0 1]

//PBR Config
#define HARDCODED_METAL 1.0 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]
#define HARDCODED_ROUGHNESS 0.2 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.999 1.0]
#define PBR_ATTENUATION 1.0
#define DO_RESOURCEPACK_PBR 1 //[0 1]
#define DO_RESOURCEPACK_EMISSION 0 //[0 1]
#define EMISSIVE_MULTIPLIER 1.0 //[1.0 1.5 2.0 2.5 3.0]
#define SPEC_SAMPLES 1
#define DO_WATER_REFLECTION 0

//Color Grading
#define BRIGHTNESS 1.0  //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SATURATION 1.0  //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define CONTRAST 1.0    //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#endif