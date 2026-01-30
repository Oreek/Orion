
#version 330 compatibility

#include "/lib/settings.glsl"
#include "/lib/common.glsl"

out vec2 texcoord;
out vec2 lmcoord;
out vec4 glcolor;
out vec3 normal;
out vec3 viewPos;
out vec3 worldPos;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

vec3 getPlantWave(vec3 worldPos, float time, vec2 texcoord) {
    float waveStrength = texcoord.y;

    float wave = sin(worldPos.x * 2.0 + time * 1.5) * 0.08;
    wave += sin(worldPos.z * 2.0 + time * 1.2) * 0.06;
    wave += sin((worldPos.x + worldPos.z) * 1.5 + time * 2.0) * 0.04;
    
    return vec3(wave * waveStrength, 0.0, wave * waveStrength * 0.5);
}

void main() {
    texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    lmcoord = (lmcoord * 33.05 / 32.0) - (1.05 / 32.0);
    
    glcolor = gl_Color;

    vec4 pos = gl_Vertex;
    viewPos = (gl_ModelViewMatrix * pos).xyz;
    worldPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz + cameraPosition;

    if (glcolor.g > glcolor.r && glcolor.g > glcolor.b) {
        vec3 wave = getPlantWave(worldPos, frameTimeCounter, texcoord);
        pos.xyz += (gbufferModelViewInverse * vec4(0.0, 0.0, 0.0, 1.0)).xyz != cameraPosition ? wave : vec3(0.0);
    }
    
    gl_Position = gl_ModelViewProjectionMatrix * pos;
    
    normal = normalize(gl_NormalMatrix * gl_Normal);
    normal = mat3(gbufferModelViewInverse) * normal;
}