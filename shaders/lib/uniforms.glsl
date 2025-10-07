#ifndef UNIFORMS
#define UNIFORMS

#include "/lib/common.glsl"

//Projection Matrices
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


//buffers
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;

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

//noises
uniform sampler3D blueNoiseTex;

//additional uniforms
uniform vec3 cameraPosition;
uniform int frameCounter;
uniform float far;
uniform float PaleGardenSmooth;
uniform ivec2 eyeBrightnessSmooth;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float wetness;
uniform int isEyeInWater;
uniform int worldTime;

//constants
const float PI = float(3.14159);
const float wetnessHalflife = 0.3;
const float drynessHalflife = 3.0;
const float sunPathRotation = SUN_ROTATION;

//lights
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
vec3 lightVector = normalize(shadowLightPosition);
vec3 worldLightVector = mat3(gbufferModelViewInverse) * lightVector;
vec3 sunDir = normalize(sunPosition);
vec3 worldSunDir = mat3(gbufferModelViewInverse) * sunDir;
vec3 moonDir = normalize(moonPosition);
vec3 worldMoonDir = mat3(gbufferModelViewInverse) * moonDir;

//boolens
bool inWater = isEyeInWater == 1.0;
#endif //UNIFORMS
