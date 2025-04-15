#ifndef MATERIALS_GLSL
#define MATERIALS_GLSL

vec3 getAlbedo(vec2 texcoord)
{
   vec3  albedo = texture(colortex0, texcoord).rgb;
    return albedo;
}
#endif