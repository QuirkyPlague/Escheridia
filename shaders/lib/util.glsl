#ifndef UTIL_GLSL
#define UTIL_GLSL

#include "/lib/common.glsl"
#include "/lib/uniforms.glsl"

vec3 projectAndDivide(mat4 projectionMatrix, vec3 position) {
  vec4 homPos = projectionMatrix * vec4(position, 1.0);
  return homPos.xyz / homPos.w;
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

float luminance(vec3 color) {
  return dot(color, vec3(0.2126, 0.7152, 0.0722));
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

float Rayleigh(float mu) {
  return 3.0 * (1.0 + mu * mu) / (16.0 * PI);
}


vec3 blue_noise(vec2 coord, int frame) {
  return texelFetch(
    blueNoiseTex,
    ivec3(ivec2(coord) % 128, frame % 64),
    0
  ).rgb;
}

// R2 sequence from
// https://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/
vec3 blue_noise(vec2 coord, int frame, int i) {
  const float g = 1.32471795724474602596;
  float a1 = 1.0/(g);
  float a2 = 1.0/(pow(g,2));

  vec2 offset = vec2(fract(0.5 + a1 * i), fract(0.5 + a2 * i));
  return blue_noise(coord + offset, frame);
}

//from Zombye
vec3 SampleVNDFGGX(
    vec3 viewerDirection, // Direction pointing towards the viewer, oriented such that +Z corresponds to the surface normal
    vec2 alpha, // Roughness parameter along X and Y of the distribution
    vec2 xy // Pair of uniformly distributed numbers in [0, 1)
) {
    // Transform viewer direction to the hemisphere configuration
    viewerDirection = normalize(vec3(alpha * viewerDirection.xy, viewerDirection.z));

    // Sample a reflection direction off the hemisphere
    const float tau = 6.2831853; // 2 * pi
    float phi = tau * xy.x;
    float cosTheta = fma(1.0 - xy.y,1.0 + viewerDirection.z, -viewerDirection.z);
    float sinTheta = sqrt(clamp(1.0 - cosTheta * cosTheta, 0.0, 1.0));
    vec3 reflected = vec3(vec2(cos(phi), sin(phi)) * sinTheta, cosTheta);

    // Evaluate halfway direction
    // This gives the normal on the hemisphere
    vec3 halfway = (reflected + viewerDirection);
    // Transform the halfway direction back to hemiellispoid configuation
    // This gives the final sampled normal
    return normalize(vec3(alpha * halfway.xy, halfway.z));
}


#endif //UTIL_GLSL
