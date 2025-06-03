#ifndef UNIFORMS_GLSL
#define UNIFORMS_GLSL

#include "/lib/common.glsl"

/*
const int colortex0Format = RGB16;
const int colortex3Format = RGB16;
const int colortex4Format = RGB16;
*/


uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;

//buffers
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
//depth buffer
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
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
uniform float viewWidth;
uniform float viewHeight;
uniform float far;
uniform int isEyeInWater;
uniform vec3 cameraPosition;
uniform int worldTime;

#endif //UNIFORMS_GLSL