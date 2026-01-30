
#ifndef ATMOSPHERE_GLSL
#define ATMOSPHERE_GLSL

#include "/lib/settings.glsl"
#include "/lib/common.glsl"


// CONSTANTS

const float earthRadius = 6371000.0;
const float atmosphereRadius = 6471000.0;
const vec3 rayleighCoeff = vec3(5.8e-6, 13.5e-6, 33.1e-6);
const float mieCoeff = 21e-6;
const float rayleighScale = 8500.0;
const float mieScale = 1200.0;
const float mieG = 0.76;


// SKY COLOR CALCULATOR

vec3 getSimpleSky(vec3 viewDir, vec3 sunDir, float sunAngle) {
    float horizonBlend = pow(1.0 - max(viewDir.y, 0.0), 3.0);
    float sunBlend = dot(viewDir, sunDir) * 0.5 + 0.5;
    
    float dayFactor = smoothstep(-0.1, 0.3, sunAngle);
    float sunsetFactor = smoothstep(0.0, 0.3, sunAngle) * smoothstep(0.5, 0.2, sunAngle);
    
    vec3 zenithDay = vec3(0.25, 0.45, 0.85);
    vec3 zenithNight = vec3(0.01, 0.015, 0.03);
    vec3 zenithSunset = vec3(0.3, 0.35, 0.5);
    
    vec3 horizonDay = vec3(0.7, 0.8, 0.95);
    vec3 horizonNight = vec3(0.02, 0.025, 0.04);
    vec3 horizonSunset = vec3(1.0, 0.5, 0.2);
    
    vec3 zenith = mix(zenithNight, zenithDay, dayFactor);
    zenith = mix(zenith, zenithSunset, sunsetFactor);
    
    vec3 horizon = mix(horizonNight, horizonDay, dayFactor);
    horizon = mix(horizon, horizonSunset, sunsetFactor);
    
    vec3 sky = mix(zenith, horizon, horizonBlend);
    
    float sunGlow = pow(max(dot(viewDir, sunDir), 0.0), 64.0);
    vec3 sunColor = mix(vec3(1.0, 0.5, 0.2), vec3(1.0, 0.98, 0.9), dayFactor);
    sky += sunColor * sunGlow * 2.0 * dayFactor;
    
    return sky;
}

float miePhase(float cosTheta, float g) {
    float g2 = g * g;
    float num = 3.0 * (1.0 - g2) * (1.0 + cosTheta * cosTheta);
    float denom = 8.0 * PI * (2.0 + g2) * pow(1.0 + g2 - 2.0 * g * cosTheta, 1.5);
    return num / denom;
}

float rayleighPhase(float cosTheta) {
    return 3.0 / (16.0 * PI) * (1.0 + cosTheta * cosTheta);
}

vec2 raySphereIntersect(vec3 rayOrigin, vec3 rayDir, float radius) {
    float b = dot(rayOrigin, rayDir);
    float c = dot(rayOrigin, rayOrigin) - radius * radius;
    float d = b * b - c;
    
    if (d < 0.0) return vec2(-1.0);
    
    d = sqrt(d);
    return vec2(-b - d, -b + d);
}

vec3 getAtmosphericSky(vec3 viewDir, vec3 sunDir, vec3 camPos) {
    vec3 origin = vec3(0.0, earthRadius + 100.0, 0.0);
    
    vec2 atmoIntersect = raySphereIntersect(origin, viewDir, atmosphereRadius);
    
    if (atmoIntersect.y < 0.0) return vec3(0.0);
    
    float rayLength = atmoIntersect.y;
    
    vec2 groundIntersect = raySphereIntersect(origin, viewDir, earthRadius);
    if (groundIntersect.x > 0.0) {
        rayLength = groundIntersect.x;
    }
    
    const int steps = 16;
    float stepSize = rayLength / float(steps);
    
    vec3 rayleighSum = vec3(0.0);
    vec3 mieSum = vec3(0.0);
    float opticalDepthR = 0.0;
    float opticalDepthM = 0.0;
    
    for (int i = 0; i < steps; i++) {
        vec3 samplePos = origin + viewDir * (float(i) + 0.5) * stepSize;
        float height = length(samplePos) - earthRadius;
        
        float hr = exp(-height / rayleighScale) * stepSize;
        float hm = exp(-height / mieScale) * stepSize;
        
        opticalDepthR += hr;
        opticalDepthM += hm;
        
        vec2 sunIntersect = raySphereIntersect(samplePos, sunDir, atmosphereRadius);
        float sunRayLength = sunIntersect.y;
        
        const int sunSteps = 4;
        float sunStepSize = sunRayLength / float(sunSteps);
        
        float sunOpticalDepthR = 0.0;
        float sunOpticalDepthM = 0.0;
        
        for (int j = 0; j < sunSteps; j++) {
            vec3 sunSamplePos = samplePos + sunDir * (float(j) + 0.5) * sunStepSize;
            float sunHeight = length(sunSamplePos) - earthRadius;
            
            sunOpticalDepthR += exp(-sunHeight / rayleighScale) * sunStepSize;
            sunOpticalDepthM += exp(-sunHeight / mieScale) * sunStepSize;
        }
        
        vec3 tau = rayleighCoeff * (opticalDepthR + sunOpticalDepthR) + vec3(mieCoeff) * 1.1 * (opticalDepthM + sunOpticalDepthM);
        vec3 attenuation = exp(-tau);
        
        rayleighSum += attenuation * hr;
        mieSum += attenuation * hm;
    }
    
    float cosTheta = dot(viewDir, sunDir);
    float phaseR = rayleighPhase(cosTheta);
    float phaseM = miePhase(cosTheta, mieG);
    
    vec3 sunIntensity = vec3(20.0);
    
    return sunIntensity * (rayleighSum * rayleighCoeff * phaseR + mieSum * mieCoeff * phaseM);
}

float getStars(vec3 viewDir, float time) {
    vec3 starDir = normalize(viewDir);
    vec2 starUV = vec2(atan(starDir.z, starDir.x), asin(starDir.y));
    starUV *= vec2(150.0, 100.0);
    
    float starNoise = hash12(floor(starUV));
    float star = smoothstep(0.985, 1.0, starNoise);
    
    float twinkle = sin(time * 3.0 + starNoise * 100.0) * 0.5 + 0.5;
    star *= 0.5 + twinkle * 0.5;
    
    return star;
}

float getClouds(vec3 viewDir, float time) {
    if (viewDir.y < 0.0) return 0.0;
    
    vec2 cloudUV = viewDir.xz / (viewDir.y + 0.1);
    cloudUV *= 2.0;
    cloudUV += time * 0.01;
    
    float clouds = fbm(cloudUV, 5);
    clouds = smoothstep(0.4, 0.6, clouds);
    
    float horizonFade = smoothstep(0.0, 0.15, viewDir.y);
    
    return clouds * horizonFade;
}

vec3 getSky(vec3 viewDir, vec3 sunDir, float sunAngle, float time, vec3 camPos) {
    vec3 sky;
    
    #if SKY_QUALITY == 1
        sky = getSimpleSky(viewDir, sunDir, sunAngle);
    #elif SKY_QUALITY == 2
        sky = getAtmosphericSky(viewDir, sunDir, camPos);
    #else
        sky = getAtmosphericSky(viewDir, sunDir, camPos);
    #endif
    
    float nightFactor = smoothstep(0.1, -0.1, sunAngle);
    if (nightFactor > 0.0) {
        float stars = getStars(viewDir, time);
        sky += stars * nightFactor * 2.0;
    }
    
    float dayFactor = smoothstep(-0.1, 0.2, sunAngle);
    float clouds = getClouds(viewDir, time);
    vec3 cloudColor = mix(vec3(0.03), vec3(1.0), dayFactor);
    sky = mix(sky, cloudColor, clouds * 0.5 * dayFactor);
    
    return max(sky, vec3(0.0));
}


// FOGG

vec3 applyFog(vec3 color, vec3 fogColor, float distance, float height, float startHeight) {
    #ifdef FOG_ENABLED
        float heightFactor = exp(-max(height - startHeight, 0.0) * FOG_HEIGHT_FALLOFF);
        float fogAmount = 1.0 - exp(-distance * FOG_DENSITY * heightFactor);
        
        return mix(color, fogColor, saturate(fogAmount));
    #else
        return color;
    #endif
}

vec3 applyDistanceFog(vec3 color, vec3 fogColor, float distance) {
    #ifdef FOG_ENABLED
        float fogAmount = 1.0 - exp(-distance * FOG_DENSITY);
        return mix(color, fogColor, saturate(fogAmount));
    #else
        return color;
    #endif
}

vec3 getFogColor(vec3 viewDir, vec3 sunDir, float sunAngle) {
    float sunInfluence = max(dot(viewDir, sunDir), 0.0);
    sunInfluence = pow(sunInfluence, 4.0);
    
    float dayFactor = smoothstep(-0.1, 0.3, sunAngle);
    float sunsetFactor = smoothstep(0.0, 0.3, sunAngle) * smoothstep(0.5, 0.2, sunAngle);
    
    vec3 fogDay = fogColorDay;
    vec3 fogNight = fogColorNight;
    vec3 fogSunset = vec3(1.0, 0.6, 0.3);
    
    vec3 fog = mix(fogNight, fogDay, dayFactor);
    fog = mix(fog, fogSunset, sunsetFactor * sunInfluence);
    
    return fog;
}

#endif