#ifndef WAVES_GLSL
#define WAVES_GLSL

//implemented from  Very fast procedural ocean: https://www.shadertoy.com/view/MdXyzX

#define DRAG_MULT (WAVE_PULL) // changes how much waves pull on the water

// Calculates wave value and its derivative,
// for the wave direction, position in space, wave frequency and time

float remap2(float value, float originalMin, float originalMax, float newMin, float newMax)
{
    return newMin + (((value - originalMin) / (originalMax - originalMin) * (newMax - newMin)));

}
float calcWaveDensity(vec2 pos)
{
    float density = 0.0;
    vec4 shape = vec4(0.0);
    vec4 detail1 = vec4(0.0);
    vec4 detail2 = vec4(0.0);
    vec2 uv = pos * 1.45 * 0.0001 + 3.0 * 0.1;
    shape = texture(cloudBase, uv);
    detail1 = texture(detail, uv);

    shape.r = remap2(shape.r, 1.0 - detail1.r, 1.0, 0.0, 1.0);
    density += max(0.043, shape.r - 0.345) ;
    
    density *= 2.1;
    return density;
}

vec2 wavedx(vec2 position, vec2 direction, float frequency, float timeshift) {
  float noise = texture(waterTex,mod((position) / 2.0, 64.0) / 64.0).r;
  float waveDensity = calcWaveDensity(position);
  float x = dot(direction,(position + (noise * -waveDensity  ))) * frequency + timeshift;
  float y = dot(direction, (position + (noise * 4 ))) * frequency + timeshift;
  float wave = exp(sin(x) - 1.0) + exp(cos(y) - 0.46);
  float dx = wave  * cos(x) * cos(y);
  return vec2(wave, -dx);
}




// Calculates waves by summing octaves of various waves with various parameters
float getwaves(vec2 position, int iterations) {
  float noise = calcWaveDensity(position);
  float wavePhaseShift = length(position) * 0.414 * WAVE_RANDOMNESS; // this is to avoid every octave having exactly the same phase everywhere
  
  float iter = 65.0; // this will help generating well distributed wave directions
  float frequency = 1.25; // frequency of the wave, this will change every iteration
  float timeMultiplier = 3.0 ; // time multiplier for the wave, this will change every iteration
  #if SCREENSHOT_MODE == 1
  if(hideGUI == true)
  {
    timeMultiplier = 0.0;
  }
  
  #endif
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
    )  ;
    vec2 noiseRes = res * noise;

    res = min(res - noiseRes, 5) * (noise);
  
    // shift position around according to wave drag and derivative of the wave
    position += p * res.y * weight * DRAG_MULT;

    // add the results to sums
    sumOfValues += res.x * weight;
    sumOfWeights += weight;

    // modify next octave ;
    weight = mix(weight, 0.0, 0.352);
    frequency *= 1.34 * WAVE_FREQUENCY;
    timeMultiplier *= 1.17 * WAVE_SPEED;

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


#define PULL_MULT (0.3235) // changes how much waves pull on the water

// Calculates wave value and its derivative,
// for the wave direction, position in space, wave frequency and time
vec2 rainSinWave(vec2 position, vec2 direction, float frequency, float timeshift) {
  float x = dot(direction, position) * frequency + timeshift;
  float wave = exp(sin(x) - 1.0);
  float dx = wave * cos(x);
  return vec2(wave, -dx);
}

// Calculates waves by summing octaves of various waves with various parameters
float getRainWaves(vec2 position, int iterations, float rainAmount) {
  float wavePhaseShift = length(position) * 0.354; // this is to avoid every octave having exactly the same phase everywhere
  float iter = 0.0; // this will help generating well distributed wave directions
  float frequency = 2.45; // frequency of the wave, this will change every iteration
  float timeMultiplier = 7.0 * rainAmount; // time multiplier for the wave, this will change every iteration
  float weight = 0.35; // weight in final sum for the wave, this will change every iteration
  float sumOfValues = 0.0; // will store final sum of values
  float sumOfWeights = 0.0; // will store final sum of weights
  for (int i = 0; i < iterations; i++) {
    // generate some wave direction that looks kind of random
    vec2 p = vec2(sin(iter), cos(iter));

    // calculate wave data
    vec2 res = rainSinWave(
      position,
      p,
      frequency,
      frameTimeCounter * timeMultiplier + wavePhaseShift
    );

    // shift position around according to wave drag and derivative of the wave
    position += p * res.y * weight * PULL_MULT;

    // add the results to sums
    sumOfValues += res.x * weight;
    sumOfWeights += weight;

    // modify next octave ;
    weight = mix(weight, 0.0, 0.212);
    frequency *= 1.22;
    timeMultiplier *= 1.12 ;

    // add some kind of random value to make next wave look random too
    iter += 1232.399963;
  }
  // calculate and return
  return sumOfValues / sumOfWeights;
}

// Calculate normal at point by calculating the height at the pos and 2 additional points very close to pos
vec3 rainNormals(vec2 pos, float e, float depth, float rainAmount) {
  vec2 ex = vec2(e, 0);
  float H = getRainWaves(pos.xy, WAVE_OCTAVES, rainAmount) * depth;
  vec3 a = vec3(pos.x, H, pos.y);
  return normalize(
    cross(
      a -
        vec3(pos.x - e, getRainWaves(pos.xy - ex.xy, WAVE_OCTAVES,rainAmount ) * depth, pos.y),
      a - vec3(pos.x, getRainWaves(pos.xy + ex.yx, WAVE_OCTAVES, rainAmount) * depth, pos.y + e)
    )
  );
}


#endif //WAVES_GLSL
