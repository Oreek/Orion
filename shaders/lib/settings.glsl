#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL

// SHADOW SETTINGS
#define SHADOW_QUALITY 3 
#define SHADOW_SOFTNESS 1.5 
#define SHADOW_BIAS 0.0001
#define SHADOW_BRIGHTNESS 0.2

const int shadowMapResolution = 2048;
const float shadowDistance = 128.0;

const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;

// LIGHTING SETTINGS
#define SUNLIGHT_STRENGTH 1.0 
#define AMBIENT_STRENGTH 0.35
#define COLORED_LIGHTING
#define AO_ENABLED
#define AO_STRENGTH 1.0

// BLOOM SETTINGS
#define BLOOM_ENABLED
#define BLOOM_STRENGTH 0.3
#define BLOOM_QUALITY 3
#define BLOOM_THRESHOLD 0.8

// DEPTH OF FIELD
//#define DOF_ENABLED
#define DOF_STRENGTH 1.0
#define DOF_FOCAL_LENGTH 0.05
#define DOF_APERTURE 0.025

// POST PROCESSING
#define EXPOSURE 0.9
#define SATURATION 1.15
#define CONTRAST 1.05
#define GAMMA 1.0

#define TONEMAPPER 2

#define VIGNETTE_ENABLED
#define VIGNETTE_STRENGTH 0.3
//#define FILM_GRAIN
#define FILM_GRAIN_STRENGTH 0.03
//#define CHROMATIC_ABERRATION
#define CHROMATIC_ABERRATION_STRENGTH 0.003

// ATMOSPHERE
#define FOG_ENABLED
#define FOG_DENSITY 0.001
#define FOG_HEIGHT_FALLOFF 0.02
//#define VOLUMETRIC_FOG
#define VOLUMETRIC_FOG_QUALITY 32
//#define GOD_RAYS
#define GOD_RAYS_QUALITY 32
#define GOD_RAYS_DENSITY 1.0

#define SKY_QUALITY 2

// WATER SETTINGS
#define WATER_WAVES
#define WATER_WAVE_AMPLITUDE 0.1
#define WATER_WAVE_SPEED 0.5
#define WATER_CAUSTICS
#define WATER_FOAM

// NETHER SETTINGS
#define NETHER_FOG_DENSITY 0.004
#define NETHER_HEAT_DISTORTION
#define NETHER_LAVA_GLOW
#define NETHER_AMBIENT_STRENGTH 0.9

const vec3 netherFogColor = vec3(0.35, 0.12, 0.08);
const vec3 netherAmbientColor = vec3(0.7, 0.35, 0.2);
const vec3 netherLavaGlow = vec3(1.0, 0.4, 0.1);

// COLOR PALETTE
const vec3 sunlightColor = vec3(1.0, 0.95, 0.85);
const vec3 moonlightColor = vec3(0.6, 0.7, 0.9);
const vec3 ambientDayColor = vec3(0.45, 0.55, 0.7);
const vec3 ambientNightColor = vec3(0.12, 0.15, 0.25);
const vec3 torchColor = vec3(1.0, 0.65, 0.35);
const vec3 skyColorDay = vec3(0.4, 0.65, 1.0);
const vec3 skyColorSunset = vec3(1.0, 0.5, 0.2);
const vec3 skyColorNight = vec3(0.02, 0.025, 0.05);
const vec3 fogColorDay = vec3(0.7, 0.8, 0.95);
const vec3 fogColorNight = vec3(0.05, 0.06, 0.1);

#endif