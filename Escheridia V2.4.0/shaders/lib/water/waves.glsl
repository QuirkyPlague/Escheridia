#ifndef WAVES_GLSL
#define WAVES_GLSL

//implemented from  Very fast procedural ocean: https://www.shadertoy.com/view/MdXyzX

#define DRAG_MULT (0.435 * WAVE_PULL) // changes how much waves pull on the water

// Calculates wave value and its derivative,
// for the wave direction, position in space, wave frequency and time
vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
  float x = dot(direction, position) * frequency + timeshift;
  float wave = exp(sin(x) - 1.0);
  float dx = wave * cos(x);
  return vec2(wave, -dx);
}

// Calculates waves by summing octaves of various waves with various parameters
float getwaves(vec2 position, int iterations) {
  float wavePhaseShift = length(position) * 0.1 * WAVE_RANDOMNESS; // this is to avoid every octave having exactly the same phase everywhere
  float iter = 15.0; // this will help generating well distributed wave directions
  float frequency = 1.15; // frequency of the wave, this will change every iteration
  float timeMultiplier = 3.0; // time multiplier for the wave, this will change every iteration
  float weight = 1.0; // weight in final sum for the wave, this will change every iteration
  float sumOfValues = 0.0; // will store final sum of values
  float sumOfWeights = 0.0; // will store final sum of weights
  for (int i = 0; i < iterations; i++) {
    // generate some wave direction that looks kind of random
    vec2 p = vec2(sin(iter), cos(iter));

    // calculate wave data
    vec2 res = wavedx(
      position,
      p,
      frequency,
      frameTimeCounter * timeMultiplier + wavePhaseShift
    );

    // shift position around according to wave drag and derivative of the wave
    position += p * res.y * weight * DRAG_MULT;

    // add the results to sums
    sumOfValues += res.x * weight;
    sumOfWeights += weight;

    // modify next octave ;
    weight = mix(weight, 0.0, 0.28);
    frequency *= 1.23 * WAVE_FREQUENCY;
    timeMultiplier *= 1.12 * WAVE_SPEED;

    // add some kind of random value to make next wave look random too
    iter += 1232.399963;
  }
  // calculate and return
  return sumOfValues / sumOfWeights;
}

// Calculate normal at point by calculating the height at the pos and 2 additional points very close to pos
vec3 waveNormal(vec2 pos, float e, float depth) {
  vec2 ex = vec2(e, 0);
  float H = getwaves(pos.xy, WAVE_OCTAVES) * depth;
  vec3 a = vec3(pos.x, H, pos.y);
  return normalize(
    cross(
      a -
        vec3(pos.x - e, getwaves(pos.xy - ex.xy, WAVE_OCTAVES) * depth, pos.y),
      a - vec3(pos.x, getwaves(pos.xy + ex.yx, WAVE_OCTAVES) * depth, pos.y + e)
    )
  );
}

#endif //WAVES_GLSL
