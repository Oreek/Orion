
#ifndef LIGHTNING_GLSL
#define LIGHTING_GLSL

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

// DIFFUSE LIGHTNING

float diffuseLambert(vec3 normal, vec3 lightDir) {
    return max(dot(normal, lightDir), 0.0);
}

float diffuseHalfLambert(vec3 normal, vec3 lightDir) {
    float NdotL = dot(normal, lightDir) * 0.5 + 0.5;
    return NdotL * NdotL;
}

float diffuseOrenNayar(vec3 normal, vec3 viewDir, vec3 lightDir, float roughness) {
    float NdotL = max(dot(normal, lightDir), 0.0);
    float NdotV = max(dot(normal, viewDir), 0.0);
    
    float angleVN = acos(NdotV);
    float angleLN = acos(NdotL);
    
    float alpha = max(angleVN, angleLN);
    float beta = min(angleVN, angleLN);
    float gamma = dot(viewDir - normal * NdotV, lightDir - normal * NdotL);
    
    float roughSq = roughness * roughness;
    float A = 1.0 - 0.5 * roughSq / (roughSq + 0.33);
    float B = 0.45 * roughSq / (roughSq + 0.09);
    float C = sin(alpha) * tan(beta);
    
    return NdotL * (A + B * max(0.0, gamma) * C);
}


// SPECULAR LIGHTING

float specularBlinnPhong(vec3 normal, vec3 viewDir, vec3 lightDir, float shininess) {
    vec3 halfDir = normalize(lightDir + viewDir);
    return pow(max(dot(normal, halfDir), 0.0), shininess);
}

float distributionGGX(vec3 normal, vec3 halfVec, float roughness) {
    float a = roughness * roughness;
    float a2 = a * a;
    float NdotH = max(dot(normal, halfVec), 0.0);
    float NdotH2 = NdotH * NdotH;
    
    float denom = NdotH2 * (a2 - 1.0) + 1.0;
    denom = PI * denom * denom;
    
    return a2 / denom;
}

float geometrySchlickGGX(float NdotV, float roughness) {
    float r = roughness + 1.0;
    float k = (r * r) / 8.0;
    return NdotV / (NdotV * (1.0 - k) + k);
}

float geometrySmith(vec3 normal, vec3 viewDir, vec3 lightDir, float roughness) {
    float NdotV = max(dot(normal, viewDir), 0.0);
    float NdotL = max(dot(normal, lightDir), 0.0);
    return geometrySchlickGGX(NdotV, roughness) * geometrySchlickGGX(NdotL, roughness);
}

vec3 fresnelSchlick(float cosTheta, vec3 F0) {
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

vec3 fresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness) {
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}


// COMPLETE FOR LIGHTING

vec3 calculatePBR(vec3 albedo, vec3 normal, vec3 viewDir, vec3 lightDir, vec3 lightColor, float roughness, float metallic) {
    vec3 halfVec = normalize(viewDir + lightDir);

    vec3 F0 = vec3(0.04);
    F0 = mix(F0, albedo, metallic);
    float NDF = distributionGGX(normal, halfVec, roughness);
    float G = geometrySmith(normal, viewDir, lightDir, roughness);
    vec3 F = fresnelSchlick(max(dot(halfVec, viewDir), 0.0), F0);
    
    vec3 kS = F;
    vec3 kD = (1.0 - kS) * (1.0 - metallic);
    
    float NdotL = max(dot(normal, lightDir), 0.0);
    float NdotV = max(dot(normal, viewDir), 0.0);

    vec3 numerator = NDF * G * F;
    float denominator = 4.0 * NdotV * NdotL + 0.0001;
    vec3 specular = numerator / denominator;

    return (kD * albedo / PI + specular) * lightColor * NdotL;
}


// SIMPLE LIGHTING

vec3 calculateSimpleLighting(vec3 albedo, vec3 normal, vec3 viewDir, vec3 lightDir, vec3 lightColor, float ambientStrength) {
    float diff = diffuseLambert(normal, lightDir);
    
    float spec = specularBlinnPhong(normal, viewDir, lightDir, 32.0) * 0.5;
    
    vec3 ambient = albedo * ambientStrength;
    vec3 diffuse = albedo * diff * lightColor;
    vec3 specular = spec * lightColor;
    
    return ambient + diffuse + specular;
}


// PROCESSING LIGHTMAP

vec3 getLightmapColor(vec2 lightmapCoord, float sunAngle) {
    float blockLight = pow(lightmapCoord.x, 2.2);
    vec3 blockColor = torchColor * blockLight * 1.5;
    
    float skyLight = pow(lightmapCoord.y, 2.2);
    
    float dayFactor = smoothstep(-0.1, 0.2, sunAngle);
    vec3 skyColor = mix(ambientNightColor, ambientDayColor, dayFactor);
    
    vec3 minAmbient = vec3(0.03);
    
    #ifdef COLORED_LIGHTING
        return blockColor + skyColor * skyLight + minAmbient;
    #else
        float combinedLight = max(blockLight, skyLight * 0.5);
        return vec3(combinedLight) + skyColor * skyLight + minAmbient;
    #endif
}

float calculateAO(float ao, vec2 lightmapCoord) {
    #ifdef AO_ENABLED
        float aoFactor = mix(1.0, ao, AO_STRENGTH);
        // Reduce AO in bright areas
        float brightnessFactor = max(lightmapCoord.x, lightmapCoord.y);
        aoFactor = mix(aoFactor, 1.0, brightnessFactor * 0.5);
        return aoFactor;
    #else
        return 1.0;
    #endif
}


// SUBSURFACE SCATTERING

vec3 subsurfaceScattering(vec3 albedo, vec3 normal, vec3 viewDir, vec3 lightDir, float thickness, float scatterPower) {
    float VdotL = max(dot(-viewDir, lightDir), 0.0);
    float scatter = pow(VdotL, scatterPower) * thickness;
    
    float NdotL = dot(normal, lightDir) * 0.5 + 0.5;
    float wrap = pow(NdotL, 2.0) * thickness;
    
    return albedo * (scatter + wrap) * 0.5;
}

#endif