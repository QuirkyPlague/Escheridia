#version 400 compatibility

#include "/lib/util.glsl"
#include "/lib/lighting/lighting.glsl"

in vec3 normal;
in mat3 tbnMatrix;
vec3 horizon;
vec3 zenith;
in vec3 modelPos;
in vec3 viewPos;
in vec4 glcolor;
in vec2 texcoord;
in vec3 feetPlayerPos;
in vec3 eyePlayerPos;
uniform int renderStage;



/* RENDERTARGETS: 0,11 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 stars;
void main() {
  if (renderStage == MC_RENDER_STAGE_STARS) {
    stars = glcolor;
    float t = fract(worldTime / 24000.0);

    const int keys = 7;
    const float keyFrames[keys] = float[keys](
      0.0,
      0.0417,
      0.25,
      0.5192,
      0.5417,
      0.8717,
      1.0
    );
    const float starIntensity[keys] = float[keys](
      0.0,
      0.0,
      0.0,
      0.0,
      0.9,
      0.8,
      0.0
    );

    int i = 0;
    // step(edge, x) returns 0.0 if x<edge, else 1.0
    // Accumulate how many key boundaries t has passed.
    for (int k = 0; k < keys - 1; ++k) {
      i += int(step(keyFrames[k + 1], t));
    }
    i = clamp(i, 0, keys - 2);

    // Local segment interpolation in [0..1]
    float interpFactor =
      (t - keyFrames[i]) / max(1e-6, keyFrames[i + 1] - keyFrames[i]);
    interpFactor = smoothstep(0.0, 1.0, interpFactor);

    float starI = mix(starIntensity[i], starIntensity[i + 1], interpFactor);
    float starBrightnessShift = length(feetPlayerPos) * 0.9;
    vec2 posShift;
    posShift = vec2(0.0, 1.0);
    float baseX =
      dot(feetPlayerPos.xz, posShift) * 0.5 +
      (frameTimeCounter * 1.39 + starBrightnessShift);

    float starTwinkleFactor = exp(sin(baseX - 1.6));
    float starFluctuation = starTwinkleFactor - exp(cos(baseX - 1.0));
    vec2 starTwinkle =
      vec2(starTwinkleFactor, -starFluctuation) +
      starBrightnessShift * posShift;
    stars += float(starTwinkle);
    stars *= starI;
    vec3 dir=normalize(eyePlayerPos);
    float upPos = clamp(dir.y, 0, 1);
  float downPos = clamp(dir.y, -1, 0);
  float negatedDownPos = -1.0 * downPos;
  float groundBlend = clamp(pow(negatedDownPos, 0.55), 0, 1);

    float sunHeightFactor = smoothstep(groundBlend, groundBlend + 0.071, dir.y);
    stars *= sunHeightFactor;
  }
}
