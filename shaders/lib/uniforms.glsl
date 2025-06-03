#ifndef UNIFORMS_GLSL
#define UNIFORMS_GLSL

#include "/lib/common.glsl"

/*
const int colortex0Format = RGB16;
*/



uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;

//buffers
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

const float PI = float(3.14159);
uniform int frameCounter;
const float sunPathRotation=SUN_ROTATION;

#endif //UNIFORMS_GLSL