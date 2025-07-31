#ifndef UTIL_GLSL
#define UTIL_GLSL

#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
}

vec4 getNoise(vec2 coord) {
  ivec2 screenCoord = ivec2(coord * vec2(viewWidth, viewHeight)); // exact pixel coordinate onscreen
  ivec2 noiseCoord = screenCoord % 64; // wrap to range of noiseTextureResolution
  return texelFetch(noisetex, noiseCoord, 0);
}
float IGN(vec2 coord) {
  return fract(
    52.9829189f * fract(0.06711056f * coord.x + 0.00583715f * coord.y)
  );
}

float IGN(vec2 coord, int frame) {
  return IGN(coord + 5.588238 * (frame & 63));
}

vec2 vogelDisc(int stepIndex, int stepCount, float noise) {
  float rotation = noise * 2 * PI;
  const float goldenAngle = 2.4;

  float r = sqrt(stepIndex + 0.5) / sqrt(float(stepCount));
  float theta = stepIndex * goldenAngle + rotation;

  return r * vec2(cos(theta), sin(theta));
}

vec3 screenSpaceToViewSpace(vec3 screenPosition, mat4 projectionInverse) {
  screenPosition = screenPosition * 2.0 - 1.0;

  vec3 viewPosition = vec3(
    vec2(projectionInverse[0].x, projectionInverse[1].y) * screenPosition.xy +
      projectionInverse[3].xy,
    projectionInverse[3].z
  );

  viewPosition /=
    projectionInverse[2].w * screenPosition.z + projectionInverse[3].w;

  return viewPosition;
}

float screenSpaceToViewSpace(float depth, mat4 projectionInverse) {
  depth = depth * 2.0 - 1.0;
  return projectionInverse[3].z /
  (projectionInverse[2].w * depth + projectionInverse[3].w);
}

vec3 viewSpaceToScreenSpace(vec3 viewPosition) {
  vec3 screenPosition =
    vec3(
      gbufferProjection[0].x,
      gbufferProjection[1].y,
      gbufferProjection[2].z
    ) *
      viewPosition +
    gbufferProjection[3].xyz;
  screenPosition /= -viewPosition.z;

  return screenPosition * 0.5 + 0.5;
}
float viewSpaceToScreenSpace(float depth, mat4 projection) {
  return (projection[2].z * depth + projection[3].z) / -depth * 0.5 + 0.5;
}

float HG(float g, float cosA) {
  cosA = clamp(cosA, -1, 1);

  float g2 = g * g;
  return (1.0 - g2) / pow(abs(1.0 + g2 - 2.0 * g * cosA), 1.5);
}

float CS(float g, float costh) {
  return 3.0 *
  (1.0 - g * g) *
  (1.0 + costh * costh) /
  (4.0 *
    PI *
    2.0 *
    (2.0 + g * g) *
    pow(1.0 + g * g - 2.0 * g * costh, 3.0 / 2.0));
}
vec3 screenToView(vec2 texcoord, float depth) {
  vec3 ndcPos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
  vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
  return viewPos;
}

float luminance(vec3 color) {
  return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

float DistributionGGX(vec3 N, vec3 H, float roughness) {
  float a = roughness * roughness;
  float a2 = a * a;
  float NdotH = max(dot(N, H), 1e-6);
  float NdotH2 = NdotH * NdotH;

  float num = a2;
  float denom = NdotH2 * (a2 - 1.0) + 1.0;
  denom = PI * denom * denom;

  return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness) {
  float r = roughness + 1.0;
  float k = r * r / 8.0;

  float num = NdotV;
  float denom = NdotV * (1.0 - k) + k;

  return num / denom;
}
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness) {
  float NdotV = max(dot(N, V), 1e-6);
  float NdotL = max(dot(N, L), 1e-6);
  float ggx2 = GeometrySchlickGGX(NdotV, roughness);
  float ggx1 = GeometrySchlickGGX(NdotL, roughness);

  return ggx1 * ggx2;
}

vec3 fresnelSchlick(float cosTheta, vec3 F0) {
  float f = pow(1.0 - cosTheta, 5.0);
  return f + F0 * (1.0 - f);
}

vec3 screenSpaceToViewSpace(vec3 screenPosition) {
  screenPosition = screenPosition * 2.0 - 1.0;

  vec3 viewPosition = vec3(
    vec2(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y) *
      screenPosition.xy +
      gbufferProjectionInverse[3].xy,
    gbufferProjectionInverse[3].z
  );

  viewPosition /=
    gbufferProjectionInverse[2].w * screenPosition.z +
    gbufferProjectionInverse[3].w;

  return viewPosition;
}

float Rayleigh(float cosTheta) {
  const float k = 3.0 / (16.0 * PI);
  return k * (1.0 + cosTheta * cosTheta);
}

vec3 skyboxSun(vec3 sunPos, vec3 dir, vec3 sunColor) {
  vec3 col = vec3(0.0);
  const float sunA =
    acos(dot(sunPos, dir)) * SUN_SIZE * clamp(AIR_FOG_DENSITY, 0.5, 5.0);
  vec3 sunCol = 0.03 * sunColor / sunA;

  col = max(col + 0.04 * sunCol, sunCol);
  return col;
}

#endif //UTIL_GLSL
