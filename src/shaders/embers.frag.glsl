varying float vAlpha;
void main() {
  float glow = 1.0 - smoothstep(0.05, 0.5, length(gl_PointCoord - 0.5));
  gl_FragColor = vec4(vec3(2.3,0.65,0.12), glow * vAlpha * 0.8);
}
