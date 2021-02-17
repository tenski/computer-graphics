#version 330 core

out vec4 gl_FragColor;

uniform float time;

vec3 colorA = vec3(0.0, 1.0, 1.0);
vec3 colorB = vec3(0.0, 1.0, 0.0);

void main() {
    vec3 color = mix(colorA, colorB, abs(sin(time)));

    gl_FragColor = vec4(color, 1.0);
}