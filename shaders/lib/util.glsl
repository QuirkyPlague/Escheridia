#ifndef UTIL_GLSL
#define UTIL_GLSL

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position)
{
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

float IGN(vec2 coord)
{
    return fract(52.9829189f * fract(0.06711056f * coord.x + 0.00583715f* coord.y));
}

float IGN(vec2 coord, int frame)
{
    return  IGN(coord + 5.588238 * (frame & 63));
}

vec2 vogelDisc(int stepIndex, int stepCount, float noise) {
    float rotation = noise * 2 * PI;
    const float goldenAngle = 2.4;

    float r = sqrt(stepIndex + 0.5) / sqrt(float(stepCount));
    float theta = stepIndex * goldenAngle + rotation;

    return r * vec2(cos(theta), sin(theta));
}

#endif //UTIL_GLSL