#ifndef TONEMAP
#define TONEMAP


// https://github.com/dmnsgn/glsl-tone-map/blob/main/lottes.glsl
vec3 lottesTonemap(vec3 x) {
  x *= 0.3;

  const vec3 a = vec3(1.6);
  const vec3 d = vec3(0.977);
  const vec3 hdrMax = vec3(8.0);
  const vec3 midIn = vec3(0.18);
  const vec3 midOut = vec3(0.267);

  const vec3 b =
    (-pow(midIn, a) + pow(hdrMax, a) * midOut) /
    ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);
  const vec3 c =
    (pow(hdrMax, a * d) * pow(midIn, a) -
      pow(hdrMax, a) * pow(midIn, a * d) * midOut) /
    ((pow(hdrMax, a * d) - pow(midIn, a * d)) * midOut);

  return pow(pow(x, a) / (pow(x, a * d) * b + c), vec3(1.0/(2.2)));
}


#endif //TONEMAPPING_GLSL
