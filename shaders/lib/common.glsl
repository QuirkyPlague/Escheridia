#ifndef COMMON_GLSL
#define COMMON_GLSL

/*
const int colortex0Format = RGB16F;
const int colortex3Format = RGB16F;
const int colortex4Format = RGB16F;
const int colortex12Format = RGB16F;
*/

#define SHADOW_SAMPLES 16 //[4 8 12 16 20 24 28 32]
#define SHADOW_SOFTNESS 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SHADOW_RESOLUTION 2048 //[512 1024 2048 4096 8192]
//4 8 12 16 24 32
#define SHADOW_DISTANCE 384.0 //[64.0 128.0 192.0 256.0 384.0 584.0]
#define SUN_ROTATION -30 //[-45 -30 -15 0 15 30 45]

#define GODRAYS_SAMPLES 18 //[6 12 18 24 30 36 42 48 54 60 64 68 74]
#define GODRAY_DENSITY 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define VOLUMETRIC_LIGHTING 1 //[0 1]

#define AGX_SATURATION 1.67
#define AGX_MIN_EV (-17.17393)
#define AGX_MAX_EV (2.126069)
#define AGX_POWER vec3(1.2)
#define AGX_OFFSET_COLOR vec3(0.0)
#define TONEMAPPING_TYPE 3 //[0 1 2 3]

#define WATER_EXTINCTION vec3(0.9961, 0.8118, 0.3333);
#define WATER_SCATTERING vec3(0.0314, 0.051, 0.1098) ;
#define WATER_FOG_DENSITY 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#define EMISSIVE_MULTIPLIER 1.0 //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define BLOOM_QUALITY 1.0
#define BLOOM_RADIUS 1.0
#define DO_SSR 1 //[0 1]
#define SSR_STEPS 8 //[2 4 6 8 10 12 14 16 18 20 22 24 28 32 36 40]

#define MIE_SCALE 1.0
#define HARDCODED_SSS 1 //[0 1]
#define SSS_INTENSITY 0.6 //[0.1 0.25 0.5 0.75 1.0]
#define SSS_HG 0.4
#endif //COMMON_GLSL
