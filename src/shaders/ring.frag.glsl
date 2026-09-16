precision highp float;
varying vec2 vUv;
uniform vec2 uResolution;
uniform vec2 uPointer;
uniform float uTime;
uniform float uCollapse;
uniform float uPresence;

float hash(vec3 p) {
  p = fract(p * 0.3183099 + vec3(0.13, 0.27, 0.41));
  p *= 17.0;
  return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float noise(vec3 p) {
  vec3 i = floor(p), f = fract(p);
  f = f * f * (3.0 - 2.0 * f);
  return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),
             mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);
}
float fbm(vec3 p) {
  float sum = 0.0, amplitude = 0.5;
  for (int i = 0; i < 5; i++) {
    sum += amplitude * noise(p);
    p = p * 2.03 + vec3(5.2, 1.3, 7.1);
    amplitude *= 0.5;
  }
  return sum;
}
void main() {
  vec2 p = (vUv - 0.5) * uResolution / min(uResolution.x, uResolution.y);
  p.y -= 0.02;
  float t = uTime * 0.38;
  float scale = 1.0 - 0.92 * uCollapse;
  float radius = 0.230 * scale;
  float r = length(p);
  vec2 polar = p / max(r, 0.00001);
  float proximity = exp(-length(p - uPointer) * 16.0) * uPresence;
  float rimNoise = fbm(vec3(polar * 5.0, t * 0.32));
  float d = r - radius; // Keep the occulting disk circular; only the exterior light fluctuates.

  // Two overlapping circular fields form a soft almond-shaped light volume.
  // It is filled haze, not a drawn eyelid or a radially advected flame texture.
  vec2 q = p / scale;
  // Rising, domain-warped fog: negative time on y moves features upward.
  vec2 fogDrift = vec2(
    fbm(vec3(q * 5.0, t * 0.18)),
    fbm(vec3(q * 5.0 + 7.3, t * 0.16))
  ) - 0.5;
  vec2 flowing = q * vec2(7.0, 9.0) + fogDrift * 1.4 - vec2(0.0, t * 0.65);
  float mist = fbm(vec3(flowing, t * 0.12));
  float broad = fbm(vec3(q * 3.5 - vec2(0.0,t * 0.22), t * 0.10));
  // Raise the almond relative to the sphere, rather than moving the whole eye.
  vec2 fogPoint = q - vec2(0.0, 0.085);
  float upper = smoothstep(0.03, 0.22, q.y);
  fogPoint.x += fogDrift.x * 0.03 * upper;
  fogPoint.y += (mist - 0.5) * (0.025 + upper * 0.10 + proximity * 0.04);
  float roundedY = sqrt(fogPoint.y * fogPoint.y + 0.004);
  float almond = length(vec2(fogPoint.x, roundedY + 0.30)) - 0.58;
  almond += fogDrift.x * 0.055 + (broad - 0.5) * 0.07;
  float almondMist = 1.0 - smoothstep(-0.14, 0.16, almond);
  float diffuseMist = exp(-2.0 * dot(fogPoint / vec2(0.53, 0.39), fogPoint / vec2(0.53, 0.39)));
  float eyeVolume = mix(diffuseMist, almondMist, 0.48);
  float outside = max(length(q) - 0.23, 0.0);
  float billows = smoothstep(0.25, 0.72, mist);
  float haze = eyeVolume * exp(-outside * 4.0) * (0.34 + billows * 1.05);
  haze *= 0.75 + upper * 0.5;
  // No luminous outline: diffuse fog only hints at the eye silhouette.
  float closeGlow = exp(-outside * 35.0) * (0.65 + mist * 0.4);
  vec3 color = vec3(1.0,0.13,0.027) * haze * 0.62;

  color += vec3(1.0,0.27,0.07) * closeGlow * 0.40;
  // A diffuse plume curls off the upper arc and fades before its outer edge.
  float plume = exp(-pow(q.x / 0.29, 2.0));
  plume *= smoothstep(0.17, 0.28, q.y) * (1.0 - smoothstep(0.31, 0.53, q.y));
  plume *= smoothstep(0.34, 0.70, mist) * (0.55 + broad);
  color += vec3(1.0,0.13,0.028) * plume * 0.34;
  color *= smoothstep(-0.004, 0.007, d);

  // A continuous warm rim with restrained flicker keeps the sphere readable.
  float edge = exp(-pow((d - 0.0015 * scale) / (0.0025 * scale + 0.0006), 2.0));
  color += vec3(1.0,0.47,0.16) * edge * (1.65 + rimNoise * 0.65);
  // Signed angle around the leftward axis: positive is counterclockwise.
  // One continuous highlight spans -84 to +104 degrees, feathered at both ends.
  float leftAngle = atan(-polar.y, -polar.x);
  float highlightStart = radians(-84.0);
  float highlightEnd = radians(104.0);
  float feather = radians(7.0);
  float highlightArc = smoothstep(highlightStart, highlightStart + feather, leftAngle);
  highlightArc *= 1.0 - smoothstep(highlightEnd - feather, highlightEnd, leftAngle);
  highlightArc *= 0.82 + 0.18 * max(-polar.x, 0.0);
  float surfaceLip = exp(-pow((d - 0.004 * scale) / (0.005 * scale), 2.0));
  float softReflection = exp(-max(d, 0.0) / ((0.018 + proximity * 0.012) * scale));
  color += vec3(1.0,0.76,0.43) * surfaceLip * highlightArc * 2.8;
  color += vec3(1.0,0.30,0.07) * softReflection * highlightArc * 0.40;

  // Light gathers along the lower arc into a shared corona/shaft attachment.
  float bottomAngle = abs(atan(p.x, -p.y));
  float gatheringArc = exp(-pow(bottomAngle / 0.40, 2.0));
  float gatheringFlow = 0.90 + 0.10 * sin(bottomAngle * 28.0 + t * 2.6);
  color += vec3(1.0,0.78,0.46) * surfaceLip * gatheringArc * gatheringFlow * 4.6;
  color += vec3(1.0,0.34,0.09) * softReflection * gatheringArc * 0.9;

  // Both the bright junction and tapering shaft originate at the same pole.
  float down = -p.y - radius;
  float positiveDown = max(down, 0.0);
  float rootFalloff = exp(-positiveDown / (0.035 * scale));
  float gate = smoothstep(0.0, 0.003 * scale, down);
  float flow = fbm(vec3(p.x * 85.0, down * 13.0 + t * 1.8, t * 0.18));
  float drift = sin(down * 17.0 - t) * 0.001 + (flow - 0.5) * 0.003;
  // Anchor the centerline exactly at the pole; allow gentle drift farther down.
  drift *= 1.0 - exp(-positiveDown / (0.055 * scale));
  float x = abs(p.x - drift);
  float width = (0.003 + 0.010 * rootFalloff) * scale;
  float shaft = exp(-x / width) * (0.85 + flow * 0.3);
  float sheath = exp(-x / ((0.014 + 0.012 * rootFalloff) * scale)) * 0.18;
  vec3 beamColor = mix(vec3(1.0,0.29,0.065),vec3(1.0,0.76,0.40),rootFalloff);
  vec3 beam = beamColor * shaft * (1.8 + rootFalloff * 2.6);
  beam += vec3(0.85,0.075,0.016) * sheath;
  float junction = exp(-pow(p.x / (0.018 * scale),2.0)
                       -pow((down - 0.006 * scale) / (0.017 * scale),2.0));
  color += vec3(1.0,0.83,0.54) * junction * 4.0;
  color += beam * gate * (1.0 - smoothstep(0.65,1.0,uCollapse));
  // The disk occludes the corona and shaft; neither emits from its interior.
  color *= smoothstep(0.0, 0.001 * scale, d);
  color *= 1.0 - smoothstep(0.78,1.0,uCollapse);
  gl_FragColor = vec4(color, 1.0);
}







