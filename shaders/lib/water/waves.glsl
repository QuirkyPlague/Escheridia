#ifndef WAVES_GLSL
#define WAVES_GLSL

//implemented from  Very fast procedural ocean: https://www.shadertoy.com/view/MdXyzX

#define DRAG_MULT 1.0 * WAVE_PULL // changes how much waves pull on the water
const int waveOctaves =  WAVE_OCTAVES; // waves iterations when calculating normals


// Calculates wave value and its derivative, 
// for the wave direction, position in space, wave frequency and time
vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
  float x = dot(direction, position) * frequency + timeshift;
  float wave = exp2(sin(x) - 1.0);
  float dx = wave * cos(x );
  return vec2(wave, -dx);
}

// Calculates waves by summing octaves of various waves with various parameters
float getwaves(vec2 position, int iterations) {
  float wavePhaseShift = length(position) * 1.6 * WAVE_RANDOMNESS; // this is to avoid every octave having exactly the same phase everywhere
  float iter = 0.0; // this will help generating well distributed wave directions
  float frequency = 1.0; // frequency of the wave, this will change every iteration
  float timeMultiplier = 2.0; // time multiplier for the wave, this will change every iteration
  float weight = 0.0;// weight in final sum for the wave, this will change every iteration
  float sumOfValues = 0.0; // will store final sum of values
  float sumOfWeights = 0.0; // will store final sum of weights
  for(int i=0; i < iterations; i++) {
    // generate some wave direction that looks kind of random
    vec2 p = vec2(sin(iter), cos(iter));
    
    // calculate wave data
    vec2 res = wavedx(position, p, frequency, frameTimeCounter * timeMultiplier + wavePhaseShift);

    // shift position around according to wave drag and derivative of the wave
    position += p * res.y * weight * DRAG_MULT;

    // add the results to sums
    sumOfValues += res.x * weight;
    sumOfWeights += weight;

    // modify next octave ;
    weight = mix(weight, 0.11, 0.9);
    frequency *= 1.03 * WAVE_FREQUENCY;
    timeMultiplier *= 1.17 * WAVE_SPEED;

    // add some kind of random value to make next wave look random too
    iter += 1632.399963;
  }
  // calculate and return
  return sumOfValues / sumOfWeights;
}
// Calculate normal at point by calculating the height at the pos and 2 additional points very close to pos
vec3 waveNormal(vec2 pos, float e, float depth) {
  vec2 ex = vec2(e, 0);
  float H = getwaves(pos.xy, waveOctaves) * depth;
  vec3 a = vec3(pos.x, H, pos.y);
  return normalize(
    cross(
      a - vec3(pos.x - e, getwaves(pos.xy - ex.xy, waveOctaves) * depth, pos.y), 
      a - vec3(pos.x, getwaves(pos.xy + ex.yx, waveOctaves) * depth, pos.y + e)
    )
  );
}

#endif //WAVES_GLSL