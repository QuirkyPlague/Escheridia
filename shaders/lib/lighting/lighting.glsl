#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL 1 //[0 1]

#include "/lib/uniforms.glsl"
#include "/lib/util.glsl"

const vec3 blocklightColor = vec3(1.0, 0.6353, 0.4235) * 1.2;
const vec3 skylightColor = vec3(0.2353, 0.3412, 0.4667);
vec3 sunlightColor= vec3(1.0, 0.749, 0.4627);
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
