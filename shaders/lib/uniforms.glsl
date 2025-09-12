#ifndef UNIFORMS_GLSL
#define UNIFORMS_GLSL

#include "/lib/common.glsl"

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;
uniform vec3 shadowLightPosition;

//buffers
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D colortex10;
uniform sampler2D colortex11;
uniform sampler2D colortex12;
uniform sampler2D colortex13;

//depth buffer
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D dhDepthTex0;
uniform sampler2D dhDepthTex1;
//shadow buffer
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2DShadow shadowtex1HW;
uniform sampler2DShadow shadowtex0HW;
uniform sampler2D shadowcolor0;
//normal/speculars
uniform sampler2D normals;
uniform sampler2D specular;
uniform sampler2D noisetex;
uniform sampler2D blueNoiseTex;
const float PI = float(3.14159);
uniform int frameCounter;
const int noiseTextureResolution = 1024;
uniform float eyeAltitude;
const float sunPathRotation = SUN_ROTATION;
uniform float viewWidth;
uniform float viewHeight;
uniform float far;
uniform float near;
uniform int isEyeInWater;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform int worldTime;
const float shadowDistance = SHADOW_DISTANCE;
const float shadowFarPlane = 684.0;
const float shadowDistanceRenderMul = 1.0;
const float wetnessHalflife = 0.3;
const float drynessHalflife = 68.0;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform vec4 entityColor;
uniform ivec2 eyeBrightnessSmooth;
const float eyeBrightnessHalflife = 30.0;
uniform float constantMood;
uniform float sunAngle;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform float sineSunAngle;
uniform float sunValue;
uniform float playerMood;
uniform float moodSmooth;
uniform int biome;
uniform bool isHotBiome;
uniform bool isColdBiome;
const float eps = 1e-6;
const float entityShadowDistanceMul = 0.15;
bool isNight = worldTime >= 13000 && worldTime < 23000;
bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;
bool inWater = isEyeInWater == 1.0;

vec3 lightVector = normalize(shadowLightPosition);
vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;

vec2 resolution = vec2(viewWidth, viewHeight);
#endif //UNIFORMS_GLSL
