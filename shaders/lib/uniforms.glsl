#ifndef UNIFORMS_GLSL
#define UNIFORMS_GLSL

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex5;
uniform sampler2D colortex7;
uniform sampler2D colortex8;
uniform sampler2D colortex10;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D shadowtex1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowcolor0;
uniform sampler2D shadowcolor1;
uniform sampler2D noisetex;
uniform sampler2D specular;
uniform sampler2D normals;
uniform int frameCounter;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;

uniform float viewWidth;
uniform float viewHeight;
const float PI = float(3.14159);
uniform int worldTime;
uniform int isEyeInWater;
const float drynessHalfLife = 3200.0;
const float wetnessHalflife = 3200.0;
uniform float wetness;
uniform float rainStrength;
uniform int moonPhase;
uniform int renderStage;

const float shadowDistance = 256.0;
const float shadowFarPlane = 512.0;
const float shadowDistanceRenderMul = -1.0;
uniform float far;
#endif