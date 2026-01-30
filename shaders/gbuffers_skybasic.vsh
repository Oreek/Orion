
#version 330 compatibility

out vec3 viewDir;

uniform mat4 gbufferModelViewInverse;

void main() {
    gl_Position = ftransform();

    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    viewDir = (gbufferModelViewInverse * viewPos).xyz;
}