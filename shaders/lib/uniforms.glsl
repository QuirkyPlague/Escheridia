#ifndef UNIFORMS_GLSL
#define UNIFORMS_GLSL

#include "/lib/common.glsl"

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform mat4 dhProjection;
uniform mat4 dhProjectionInverse;
uniform mat4 dhPreviousProjection;

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
uniform sampler2D shadowcolor0;
//normal/speculars
uniform sampler2D normals;
uniform sampler2D specular;

const float PI = float(3.14159);
uniform int frameCounter;
const float sunPathRotation=SUN_ROTATION;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 previousCameraPosition;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTime;
uniform float far;
uniform float near;
uniform int isEyeInWater;
uniform vec3 cameraPosition;
uniform int worldTime;
const float shadowDistance = SHADOW_DISTANCE;
const float shadowFarPlane = 684.0;
const float shadowDistanceRenderMul = 1.0;
const float wetnessHalflife = 30.0;
const float drynessHalflife = 68.0;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform float cloudHeight;
uniform bool isHotBiome;
uniform bool isHurt;
uniform bool is_sneaking;
uniform vec4 entityColor;
uniform int dhRenderDistance;
uniform float dhFarPlane;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
const float eyeBrightnessHalflife = 3.0;

bool isNight = worldTime >= 13000 && worldTime < 23000;
bool isRaining = rainStrength <= 1.0 && rainStrength > 0.0;

#endif //UNIFORMS_GLSL