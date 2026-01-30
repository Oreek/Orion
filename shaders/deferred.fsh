#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/lighting.glsl"
#include "/lib/shadow.glsl"
#include "/lib/atmosphere.glsl"

in vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 cameraPosition;
uniform float sunAngle;
uniform float frameTimeCounter;
uniform float viewWidth;
uniform float viewHeight;
uniform float far;
uniform float near;

uniform int worldTime;
uniform ivec2 eyeBrightnessSmooth;
uniform float rainStrength;
uniform int isEyeInWater;

uniform int dimensionId;

/* RENDERTARGETS: 0,4 */
layout(location = 0) out vec4 outColor;
layout(location = 1) out vec4 outBloom;

void main() {
    vec4 albedo = texture(colortex0, texcoord);
    vec3 encodedNormal = texture(colortex1, texcoord).rgb;
    vec4 lightmapData = texture(colortex2, texcoord);
    vec4 materialData = texture(colortex3, texcoord);
    float depth = texture(depthtex0, texcoord).r;

    if (depth >= 1.0) {
        outColor = albedo;
        outBloom = vec4(albedo.rgb * 0.1, 1.0);
        return;
    }

    vec3 normal = decodeNormal(encodedNormal);
    vec2 lmcoord = lightmapData.xy;
    float roughness = materialData.r;
    float metallic = materialData.g;
    float emission = materialData.b;

    vec3 ndcPos = vec3(texcoord, depth) * 2.0 - 1.0;
    vec3 viewPos = projectAndDivide(gbufferProjectionInverse, ndcPos);
    vec3 worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    vec3 eyePlayerPos = worldPos;

    vec3 viewDir = normalize(-viewPos);
    viewDir = mat3(gbufferModelViewInverse) * viewDir;

    vec3 sunDir = normalize((gbufferModelViewInverse * vec4(sunPosition, 0.0)).xyz);
    vec3 moonDir = normalize((gbufferModelViewInverse * vec4(moonPosition, 0.0)).xyz);

    float dayFactor = smoothstep(-0.1,0.2, sunAngle);
    float nightFactor = 1.0 - dayFactor;
    float sunsetFactor = smoothstep(0.0, 0.3, sunAngle) * smoothstep(0.5, 0.2, sunAngle);
    
    vec3 lightDir = sunAngle > 0.0 ? sunDir : moonDir;

    vec3 shadowViewPos = (shadowModelView * vec4(eyePlayerPos, 1.0)).xyz;
    vec4 shadowClipPos = shadowProjection * vec4(shadowViewPos, 1.0);
    
    #if SHADOW_QUALITY >= 3

        vec3 shadow = getPCSSShadow(shadowtex0, shadowtex1, shadowcolor0, noisetex, shadowClipPos, texcoord, vec2(viewWidth, viewHeight), shadowProjection);

    #else

        vec3 shadow = getPCFShadow(shadowtex0, shadowtex1, shadowcolor0, noisetex, shadowClipPos, texcoord, vec2(viewWidth, viewHeight), shadowProjection);

    #endif

    vec3 lightmapColor = getLightmapColor(lmcoord, sunAngle);

    vec3 color;

    if (dimensionId == -1) {
        vec3 netherAmbient = netherAmbientColor * NETHER_AMBIENT_STRENGTH;
        
        vec3 ambient = albedo.rgb * netherAmbient;
        
        float blockLightIntensity = pow(lmcoord.x, 2.0);
        vec3 blockLight = albedo.rgb * mix(torchColor, netherLavaGlow, 0.5) * blockLightIntensity * 2.0;

        float rimLight = pow(1.0 - max(dot(normal, vec3(0.0, 1.0, 0.0)), 0.0), 2.0);
        vec3 lavaRim = netherLavaGlow * rimLight * 0.3;
        
        float lavaDiffuse = max(dot(normal, normalize(vec3(0.3, -0.5, 0.2))), 0.0) * 0.5 + 0.5;
        vec3 diffuse = albedo.rgb * netherLavaGlow * lavaDiffuse * 0.4;
        
        color = ambient + blockLight + lavaRim + diffuse;
        
        #ifdef NETHER_LAVA_GLOW
            float pulse = sin(frameTimeCounter * 2.0) * 0.1 + 0.9;
            color *= pulse;
        #endif
        
        color += albedo.rgb * emission * 3.0;

    } else if (dimensionId == 1) {
        vec3 endAmbient = vec3(0.2, 0.15, 0.3) * 0.5;
        vec3 ambient = albedo.rgb * endAmbient;
        vec3 blockLight = albedo.rgb * lightmapColor * pow(lmcoord.x, 2.2);
        
        color = ambient + blockLight;
        color += albedo.rgb * emission * 2.0;

    } else {
        vec3 skyLightColor = mix(moonlightColor * 0.3, sunlightColor, dayFactor);
        skyLightColor = mix(skyLightColor, skyColorSunset * 1.5, sunsetFactor * 0.5);
        skyLightColor *= SUNLIGHT_STRENGTH;
        
        skyLightColor *= 1.0 - rainStrength * 0.7;
        shadow *= 1.0 - rainStrength * 0.5;
        
        shadow = mix(vec3(SHADOW_BRIGHTNESS), vec3(1.0), shadow);
        
        float NdotL = max(dot(normal, lightDir), 0.0);
        vec3 diffuse = albedo.rgb * NdotL * skyLightColor * shadow * lmcoord.y;
        
        vec3 halfVec = normalize(viewDir + lightDir);
        float shininess = mix(4.0, 128.0, pow(1.0 - roughness, 2.0));
        float spec = pow(max(dot(normal, halfVec), 0.0), shininess);
        float specStrength = pow(1.0 - roughness, 3.0) * 0.15;
        vec3 specular = skyLightColor * spec * shadow * specStrength;
        
        vec3 ambientColor = mix(ambientNightColor, ambientDayColor, dayFactor);
        ambientColor *= AMBIENT_STRENGTH;
        vec3 ambient = albedo.rgb * ambientColor * lmcoord.y;
        
        vec3 blockLight = albedo.rgb * lightmapColor * pow(lmcoord.x, 2.2);
        
        color = diffuse + specular + ambient + blockLight;
        
        color += albedo.rgb * emission * 2.0;
    }

    float ao = calculateAO(1.0, lmcoord);
    ao = mix(1.0, ao, 0.5 * AO_STRENGTH);
    color *= ao;

    float distance = length(viewPos);
    vec3 fogColor;
    float fogDensity;

    if (dimensionId == -1) {
        fogColor = netherFogColor;
        fogDensity = NETHER_FOG_DENSITY;
        
        fogDensity *= 0.8 + sin(frameTimeCounter * 0.5) * 0.2;
        
        float fogFactor = 1.0 - exp(-distance * fogDensity);
        color = mix(color, fogColor, fogFactor);
    
    } else if (dimensionId == 1) {
        fogColor = vec3(0.1, 0.05, 0.15);
        float fogFactor = 1.0 - exp(-distance * 0.008);
        color = mix(color, fogColor, fogFactor);
    
    } else {
        fogColor = getFogColor(normalize(worldPos), sunDir, sunAngle);

        if (isEyeInWater == 1) {
            fogColor = vec3(0.1, 0.3, 0.5);
            distance *= 3.0;
        }

        color = applyDistanceFog(color, fogColor, distance * 0.01);
    }

    outColor = vec4(color, 1.0);

    float brightness = getLuminance(color);
    vec3 bloomColor = color * smoothstep(BLOOM_THRESHOLD, BLOOM_THRESHOLD + 0.5, brightness);
    bloomColor += albedo.rgb * emission;
    outBloom = vec4(bloomColor, 1.0);
}