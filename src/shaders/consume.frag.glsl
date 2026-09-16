uniform sampler2D tDiffuse;
uniform float uDarkness;
uniform float uCollapse;
uniform vec2 uResolution;
varying vec2 vUv;
void main() {
  vec2 p = (vUv - 0.5) * uResolution / min(uResolution.x, uResolution.y);
  p.y -= 0.02;
  float r = length(p);
  float radius = 0.230 * (1.0 - 0.92 * uCollapse);
  float pixelWidth = 1.0 / min(uResolution.x, uResolution.y);
  float exterior = smoothstep(radius, radius + pixelWidth, r);

  // Reconstruct a front hemisphere, with dim reflected light on its surface.
  vec2 xy = p / radius;
  float z = sqrt(max(0.0, 1.0 - dot(xy, xy)));
  vec3 normal = normalize(vec3(xy, z));
  float diffuse = max(dot(normal, normalize(vec3(-0.7,0.45,0.3))),0.0);
  float grazing = pow(1.0 - z, 2.4);
  float leftLight = 0.25 + 0.75 * max(-normal.x, 0.0);
  vec3 sphere = vec3(0.0035,0.0028,0.0038);
  sphere += vec3(0.022,0.009,0.006) * pow(diffuse,1.6);
  sphere += vec3(0.032,0.011,0.005) * grazing * leftLight;
  sphere *= 1.0 - smoothstep(0.78,1.0,uCollapse);
  // Replace light inside the sphere AFTER bloom so the beam cannot leak in.
  vec3 color = mix(sphere, texture2D(tDiffuse,vUv).rgb, exterior);
  float reach = length(uResolution / min(uResolution.x, uResolution.y)) * 0.62;
  float edge = uDarkness * reach;
  float mask = uDarkness <= 0.0 ? 1.0 : smoothstep(edge - 0.035, edge + 0.035, r);
  gl_FragColor = vec4(color * mask, 1.0);
}
