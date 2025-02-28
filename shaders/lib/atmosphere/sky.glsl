
#ifndef SKY_GLSL
#define SKY_GLSL

vec3 skyColor(vec3 mainCol)
{
    mainCol = vec3(0.6784, 0.9255, 1.0);
    return exp2(mainCol, vec3(0.2314, 0.3804, 0.9098));
}

vec3 calcSky()

#endif