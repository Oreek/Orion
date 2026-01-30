
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 viewPos;
out vec3 worldPos;
out float isWater;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform int blockEntityId;
uniform vec3 cameraPosition;

vec3 getWaterWave(vec3 worldPos, float time) {
    #ifdef WATER_WAVES
        float wave = 0.0;
        
        wave += sin(worldPos.x * 1.5 + time * WATER_WAVE_SPEED * 2.0) * 0.3;
        wave += sin(worldPos.z * 2.0 + time * WATER_WAVE_SPEED * 1.5) * 0.2;
        wave += sin((worldPos.x + worldPos.z) * 3.0 + time * WATER_WAVE_SPEED * 3.0) * 0.15;
        wave += sin((worldPos.x - worldPos.z) * 4.0 + time * WATER_WAVE_SPEED * 2.5) * 0.1;
        
        return vec3(0.0, wave * WATER_WAVE_AMPLITUDE, 0.0);
    #else
        return vec3(0.0);
    #endif
}

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmcoord = (lmcoord * 33.05 / 32.0) - (1.05 / 32.0);
    
    glcolor = gl_Color;

    isWater = float(glcolor.b > glcolor.r && glcolor.b > 0.5);
    
    viewPos = (gl_ModelViewMatrix * gl_Vertex).xyz;
    worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;
    
    vec4 pos = gl_Vertex;
    if (isWater > 0.5) {
        vec3 wave = getWaterWave(worldPos, frameTimeCounter);
        pos.xyz += wave;
    }
    
    gl_Position = gl_ModelViewProjectionMatrix * pos;
    
    normal = normalize(gl_NormalMatrix * gl_Normal);
    
    #ifdef WATER_WAVES
        if (isWater > 0.5) {
            float delta = 0.1;
            vec3 wave1 = getWaterWave(worldPos + vec3(delta, 0.0, 0.0), frameTimeCounter);
            vec3 wave2 = getWaterWave(worldPos - vec3(delta, 0.0, 0.0), frameTimeCounter);
            vec3 wave3 = getWaterWave(worldPos + vec3(0.0, 0.0, delta), frameTimeCounter);
            vec3 wave4 = getWaterWave(worldPos - vec3(0.0, 0.0, delta), frameTimeCounter);
            
            vec3 waveNormal = normalize(vec3(
                (wave2.y - wave1.y) / (2.0 * delta),
                1.0,
                (wave4.y - wave3.y) / (2.0 * delta)
            ));
            
            normal = normalize(mix(normal, mat3(gl_NormalMatrix) * waveNormal, 0.5));
        }
    #endif
    
    normal = mat3(gbufferModelViewInverse) * normal;
}
