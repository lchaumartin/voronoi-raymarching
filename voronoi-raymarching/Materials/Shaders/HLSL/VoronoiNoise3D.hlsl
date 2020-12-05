/* Voronoi noise 3D */
/* Author: Max Bittker */
/* https://github.com/MaxBittker/glsl-voronoi-noise */
/* Brought to HLSL by Léo Chaumartin */
/* Last modification on 04 dec 2020 */

const float2x2 myt = float2x2(.12121212, .13131313, -.13131313, .12121212);
const float2 mys = float2(1e4, 1e6);

float2 rhash(float2 uv) {
	uv = mul(uv, myt);
	uv *= mys;
	return frac(frac(uv / mys) * uv);
}

float3 hash(float3 p) {
	return frac(
		sin(float3(dot(p, float3(1.0, 57.0, 113.0)), dot(p, float3(57.0, 113.0, 1.0)),
			dot(p, float3(113.0, 1.0, 57.0)))) *
		43758.5453);
}

float2 VoronoiNoise3D(float3 x) {
	
	float2 output;
	float3 p = floor(x);
	float3 f = frac(x);

	float2 res = float2(100.0, 100.0);
	for (int k = -1; k <= 1; k++) {
		for (int j = -1; j <= 1; j++) {
			for (int i = -1; i <= 1; i++) {
				float3 b = float3(float(i), float(j), float(k));
				float3 r = float3(b) - f + hash(p + b);
				float d = dot(r, r);

				float cond = max(sign(res.x - d), 0.0);
				float nCond = 1.0 - cond;

				float cond2 = nCond * max(sign(res.y - d), 0.0);
				float nCond2 = 1.0 - cond2;

				res = float2(d, res.x) * cond + res * nCond;

				res.y = cond2 * d + nCond2 * res.y;
			}
		}
	}
	output = float2(sqrt(res));
	output.y = output.y - output.x;
	return output;
}
////

// Projection of A onto the plane defined by its normal B
float3 rejection(float3 A, float3 B)
{
	return A - (B * dot(A, B) / dot(B, B));
}


/* Expose some functions to Shadergraph */

void VoronoiNoise3D_float(in float3 x, out float2 output) {
	output = VoronoiNoise3D(x);
}

void RayMarchCrackedGlass_float(float3 startPoint, float3 dir, float3 normal, float fade, float border, int recursionDepth, bool rejected, out float intensity) {
	float3 currentPoint = startPoint;
	intensity = 1.0;
	float dst = 0.0;
	for(int i = 0 ; i < recursionDepth ; i+=1) {
		float2 v;
		if(rejected)
			v = VoronoiNoise3D(rejection(currentPoint, normal));
		else
			v = VoronoiNoise3D(currentPoint);
		float val = 1.0 - clamp(v.y + 1.0 - border, 0.0, 1.0);
		currentPoint -= 0.5 * v.y * dir;
		dst += 0.5 * v.y;
		intensity = 1.0 - clamp(dst*fade, 0.0, 1.0);
		if(intensity < 0.001 || val > 0.0) 
			return;	
	}
}
////