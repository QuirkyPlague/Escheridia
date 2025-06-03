#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"

const vec3 blocklightColor = vec3(1.0, 0.5, 0.08);
const vec3 skylightColor = vec3(0.05, 0.15, 0.3);
const vec3 sunlightColor = vec3(1.0, 1.0, 1.0);
const vec3 ambientColor = vec3(0.1);

vec3 doDiffuse(vec2 texcoord, vec2 lightmap, vec3 normal, vec3 sunPos, vec3 shadow)
{
    vec3 blocklight = lightmap.r * blocklightColor;
    vec3 skylight = lightmap.g * skylightColor;
    vec3 ambient = ambientColor;
    vec3 sunlight = sunlightColor * clamp(dot(sunPos, normal), 0.0, 1.0) * shadow;

    vec3 diffuse = blocklight + skylight + ambient + sunlight;
    return diffuse;
}

#endif //LIGHTING_GLSL
