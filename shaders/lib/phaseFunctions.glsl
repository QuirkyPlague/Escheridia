#ifndef PHASE_FUNCTIONS_GLSL
#define PHASE_FUNCTIONS_GLSL

#include "/lib/math.glsl"

float evalDraine(float u, float g, float a) {
  return (1 - g * g) *
  (1 + a * u * u) /
  (4.0 *
    (1 + a * (1 + 2 * g * g) / 3.0) *
    PI *
    pow(1 + g * g - 2 * g * u, 1.5));
}

// sample: (sample an exact deflection cosine)
//   xi = a uniform random real in [0,1]
float sampleDraineCos(float xi, float g, float a) {
  float g2 = g * g;
  float g3 = g * g2;
  float g4 = g2 * g2;
  float g6 = g2 * g4;
  float pgp1_2 = (1 + g2) * (1 + g2);
  float T1 = (-1 + g2) * (4 * g2 + a * pgp1_2);
  float T1a = -a + a * g4;
  float T1a3 = T1a * T1a * T1a;
  float T2 = -1296 * (-1 + g2) * (a - a * g2) * T1a * (4 * g2 + a * pgp1_2);
  float T3 =
    3 * g2 * (1 + g * (-1 + 2 * xi)) +
    a * (2 + g2 + g3 * (1 + 2 * g2) * (-1 + 2 * xi));
  float T4a = 432 * T1a3 + T2 + 432 * (a - a * g2) * T3 * T3;
  float T4b = -144 * a * g2 + 288 * a * g4 - 144 * a * g6;
  float T4b3 = T4b * T4b * T4b;
  float T4 = T4a + sqrt(-4 * T4b3 + T4a * T4a);
  float T4p3 = pow(T4, 1.0 / 3.0);
  float T6 =
    (2 * T1a +
      48 * pow(2, 1.0 / 3.0) * (-(a * g2) + 2 * a * g4 - a * g6) / T4p3 +
      T4p3 / (3.0 * pow(2, 1.0 / 3.0))) /
    (a - a * g2);
  float T5 = 6 * (1 + g2) + T6;
  return (1 +
    g2 -
    pow(
      -0.5 * sqrt(T5) +
        sqrt(6 * (1 + g2) - 8 * T3 / (a * (-1 + g2) * sqrt(T5)) - T6) / 2.0,
      2
    )) /
  (2.0 * g);
}

float henyeyGreensteinPhase(float mu, float g) {
  return (1.0 - g * g) / ((4.0 + PI) * pow(1.0 + g * g - 2.0 * g * mu, 1.5));
}

float miePhase(float cosTheta, float g) {
  // g = anisotropy factor (-1..1), for atmosphere typically ~0.8 to 0.99
  float g2 = g * g;
  float denom = pow(1.0 + g2 - 2.0 * g * cosTheta, 1.5);
  return (1.0 - g2) / (4.0 * 3.14159265 * denom);
}

float phasefunc_CornetteShanks(float cosTheta, float g) {
    float k = 3.0 / (8.0 * PI) * (1.0 - g * g) / (2.0 + g * g);
    return k * (1.0 + pow2(cosTheta)) / pow(1.0 + g * g - 2.0 * g * cosTheta, 1.5);
}

float phasefunc_KleinNishinaE(float cosTheta, float e) {
    return e / (2.0 * PI * (e * (1.0 - cosTheta) + 1.0) * log(2.0 * e + 1.0));
}

float waterPhase(float cosTheta) {
    const float wKn = 0.99;
    const float gE = 20000.0;
    const float gCS = -0.6;
    return mix(
        phasefunc_CornetteShanks(cosTheta, gCS),
        phasefunc_KleinNishinaE(cosTheta, gE),
        wKn
    );
}
#endif //PHASE_FUNCTIONS_GLSL
