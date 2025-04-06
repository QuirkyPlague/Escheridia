#ifndef SPACE_CONVERSIONS_GLSL
#define SPACE_CONVERSIONS_GLSL

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"
vec3 getNDC(vec2 texcoord, float depth)
{
    depth = texture(depthtex0, texcoord).r;
    vec3 ndcPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    return ndcPos;
}

vec3 getViewPos(vec3 ndcPos)
{
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
    return viewPos;
}

vec3 getFeetPlayerPos(vec3 viewPos)
{
    vec3 feetPlayerPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    return feetPlayerPos;
}

vec3 getWorldPos(vec3 feetPlayerPos)
{
    vec3 worldPos = cameraPosition + feetPlayerPos;
    return worldPos;
}

vec3 getScreenPos(vec2 texcoord)
{
    vec3 screenPos = vec3(texcoord, texture(depthtex0, texcoord));
    return screenPos;
}

vec3 screenToView(vec2 texcoord, float depth)
{
    vec3 ndcPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
    return viewPos;
}

#endif