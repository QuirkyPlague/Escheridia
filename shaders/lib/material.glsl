#ifndef MATERIAL_GLSL
#define MATERIAL_GLSL

#define  NON_METAL       0  
#define  IRON_METAL      1
#define  GOLD_METAL      2
#define  ALUMINUM_METAL  3
#define  CHROME_METAL    4
#define  COPPER_METAL    5
#define  LEAD_METAL      6
#define  PLATINUM_METAL  7
#define  SILVER_METAL    8

// F0 and F82 values thanks to Jessie
void getMetalF0F82(int metalID, out vec3 F0, out vec3 F82) {
    switch(metalID) {
            case IRON_METAL:     F0 = vec3(0.578906, 0.562703, 0.515596); F82 = vec3(0.531049, 0.546751, 0.515596); return;
            case GOLD_METAL:     F0 = vec3(1.000000, 0.793110, 0.337074); F82 = vec3(1.000000, 0.832402, 0.500392); return;
            case LEAD_METAL:     F0 = vec3(0.595360, 0.736109, 0.699394); F82 = vec3(0.612066, 0.629024, 0.663700); return;
            case CHROME_METAL:   F0 = vec3(0.562703, 0.612066, 0.595360); F82 = vec3(0.546751, 0.562703, 0.562703); return;
            case COPPER_METAL:   F0 = vec3(1.000000, 0.773852, 0.500392); F82 = vec3(0.978132, 0.793110, 0.578906); return;
            case SILVER_METAL:   F0 = vec3(1.000000, 1.000000, 0.812627); F82 = vec3(0.978132, 0.978132, 0.852437); return;
            case ALUMINUM_METAL: F0 = vec3(1.000000, 0.956527, 1.000000); F82 = vec3(0.914106, 0.935186, 0.914106); return;
            case PLATINUM_METAL: F0 = vec3(0.832402, 0.793110, 0.663700); F82 = vec3(0.736109, 0.736109, 0.663700); return;
        }
}


vec3 fresnelLazanyi2019(float cos_theta, vec3 f0, vec3 f82) {
	vec3 a = 17.6513846 * (f0 - f82) + 8.16666667 * (1.0 - f0);
	float m = pow(1.0 - cos_theta, 5.0);
	return clamp(f0 + (1.0 - f0) * m - a * cos_theta * (m - m * cos_theta), 0,1);
}

#endif //MATERIAL_GLSL