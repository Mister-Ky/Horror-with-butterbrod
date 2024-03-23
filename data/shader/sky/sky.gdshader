shader_type canvas_item;

// USING https://disk.yandex.ru/d/r-GuhpJQkr3TfQ
// USING https://www.shadertoy.com/view/XtBXDw (base on it)

uniform float iTime;
uniform vec2 wind_dir; //направление ветра, вектор
uniform float wind_strength : hint_range(0,1); //сила ветра
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform float DAY_TIME : hint_range(0,1);
uniform float COVERAGE : hint_range(0,1); //0.5
uniform float THICKNESS : hint_range(0,100); //25.
uniform float ABSORPTION : hint_range(0,10); //1.030725
uniform int STEPS : hint_range(0,100); //25

const vec3 night_color_sky = vec3(0.0, 0.0, 0.27);
const vec3 night_color_horizon = vec3(0.0, 0.03, 0.53);
const vec3 sunset_color_sky = vec3(0.3, 0.6, 0.8);
const vec3 sunset_color_horizon = vec3(0.8, 0.35, 0.1);
const vec3 day_color_sky = vec3(0.0, 0.1, 0.4);
const vec3 day_color_horizon = vec3(0.3, 0.6, 0.8);
const vec3 sun_color = vec3(1.0, 0.7, 0.55);
const vec3 moon_color = vec3(0.6, 0.6, 0.8);
const float PI = 3.1415926535;

//float rand(vec2 co){return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);}//просто пример рандома в шейдерах из инета

float noise(in vec3 x)
{
	x *= 0.01;
	float z = x.z * 256.0;
	vec2 offz = vec2(0.317, 0.123);
	vec2 uv1 = x.xy + offz * floor(z); 
	vec2 uv2 = uv1 + offz;
	return mix(textureLod(iChannel0, uv1, 0.0).x, textureLod(iChannel0, uv2, 0.0).x, fract(z));
}

float fbm(vec3 pos, float lacunarity){
	vec3 p = pos;
	float
	t  = 0.51749673 * noise(p); p *= lacunarity;
	t += 0.25584929 * noise(p); p *= lacunarity;
	t += 0.12527603 * noise(p); p *= lacunarity;
	t += 0.06255931 * noise(p);
	return t;
}

float get_noise(vec3 x)
{
	float FBM_FREQ = 2.76434;
	return fbm(x, FBM_FREQ);
}

vec3 render_sky_color(vec3 rd, vec2 day_time){
	vec3 horizon; vec3 color_sky;
	if (day_time.x == 1.0 || day_time.x == 2.0 || day_time.x == 3.0 || day_time.x == 12.0) //ночь
		{horizon = night_color_horizon; color_sky = night_color_sky;}
	if (day_time.x == 6.0 || day_time.x == 7.0 || day_time.x == 8.0 || day_time.x == 9.0) //день
		{horizon = day_color_horizon; color_sky = day_color_sky;}
	if (day_time.x == 4.0) //переход с ночи на рассвет
		{horizon = mix(sunset_color_horizon, night_color_horizon, day_time.y); color_sky = mix(sunset_color_sky, night_color_sky, day_time.y);}
	if (day_time.x == 5.0) //переход с рассвета на день
		{horizon = mix(day_color_horizon, sunset_color_horizon, day_time.y); color_sky = mix(day_color_sky, sunset_color_sky, day_time.y);}
	if (day_time.x == 10.0) //переход с дня на закат
		{horizon = mix(sunset_color_horizon, day_color_horizon, day_time.y); color_sky = mix(sunset_color_sky, day_color_sky, day_time.y);}
	if (day_time.x == 11.0) //переход от заката к ночи
		{horizon = mix(night_color_horizon, sunset_color_horizon, day_time.y); color_sky = mix(night_color_sky, sunset_color_sky, day_time.y);}
	vec3 sky = mix(horizon, color_sky, rd.y);
	float phi = ((day_time.x - 1.0) * 30.0 - day_time.y * 30.0) * 0.0174533;
	vec3 SUN_DIR = normalize(vec3(0, -cos(phi), -sin(phi)));
	float sun_amount = max(dot(rd, SUN_DIR), 0.0);
	
	sky = sky + sun_color * min(pow(sun_amount, 1500.0) * 5.0, 1.0);
	sky = sky + sun_color * min(pow(sun_amount, 10.0) * .6, 1.0);
	
	return sky;
}

bool SphereIntersect(vec3 SpPos, float SpRad, vec3 ro, vec3 rd, out float t, out vec3 norm) {
	ro -= SpPos;
	
	float A = dot(rd, rd);
	float B = 2.0 * dot(ro, rd);
	float C = dot(ro, ro) - SpRad * SpRad;
	float D = B * B - 4.0 * A * C;
	if (D < 0.0) return false;
	
	D = sqrt(D);
	A *= 2.0;
	float t1 = (-B + D) / A;
	float t2 = (-B - D) / A;
	if (t1 < 0.0) t1 = t2;
	if (t2 < 0.0) t2 = t1;
	t1 = min(t1, t2);
	if (t1 < 0.0) return false;
	norm = ro + t1 * rd;
	t = t1;
	return true;
}

float density(vec3 pos, vec3 offset, float t){
	vec3 p = pos * .0212242 + offset;
	float dens = get_noise(p);
	
	float cov = 1. - COVERAGE;
	dens *= smoothstep(cov, cov + .05, dens);
	return clamp(dens, 0., 1.);
}

vec4 render_clouds(vec3 ro, vec3 rd){
	vec3 apos = vec3(0, -450, 0);
	float arad = 500.;
	vec2 WIND = normalize(wind_dir);
	vec3 C = vec3(0, 0, 0);
	float alpha = 0.;
	vec3 n;
	float tt;
	if (SphereIntersect(apos, arad, ro, rd, tt, n)){
		float thickness = THICKNESS;
		int steps = STEPS;
		float march_step = thickness / float(steps);
		vec3 dir_step = rd / rd.y * march_step;
		vec3 pos = n;
		float T = 1.;
		
		for (int i = 0; i < steps; i++) {
			float h = float(i) / float(steps);
			float dens = density(pos, vec3(WIND.x * iTime * wind_strength, 0.0, WIND.y * iTime * wind_strength), h);
			float T_i = exp(-ABSORPTION * dens * march_step);
			T *= T_i;
			if (T < .01) break;
			C += T * (exp(h) / 1.75) * dens * march_step;
			alpha += (1. - T_i) * (1. - alpha);
			pos += dir_step;
			if (length(pos) > 1e3) break;
		}
		
		return vec4(C, alpha);
	}
	return vec4(C, alpha);
}

float fbm2(in vec3 p)
{
	float f = 0.;
	f += .50000 * noise(.5 * (p + vec3(0.,0., -iTime * 0.275)));
	f += .25000 * noise(1. * (p + vec3(0.,0., -iTime * 0.275)));
	f += .12500 * noise(2. * (p + vec3(0.,0., -iTime * 0.275)));
	f += .06250 * noise(4. * (p + vec3(0.,0., -iTime * 0.275)));
	return f;
}

vec3 cube_bot(vec3 d, vec3 c1, vec3 c2)
{
	return fbm2(d) * mix(c1, c2, d * .5 + .5);
}

vec3 rotate_y(vec3 v, float angle)
{
	float ca = cos(angle); float sa = sin(angle);
	return v * mat3(
		vec3(+ca, +.0, -sa),
		vec3(+.0,+1.0, +.0),
		vec3(+sa, +.0, +ca));
}

vec3 rotate_x(vec3 v, float angle)
{
	float ca = cos(angle); float sa = sin(angle);
	return v * mat3(
		vec3(+1.0, +.0, +.0),
		vec3(+.0, +ca, -sa),
		vec3(+.0, +sa, +ca));
}

void panorama_uv(vec2 fragCoord, out vec3 ro,out vec3 rd, in vec2 iResolution)
{
	float ymul = 2.0; float ydiff = -1.0;
	vec2 uv = fragCoord.xy / iResolution.xy;
	uv.x = 2.0 * uv.x - 1.0;
	uv.y = ymul * uv.y + ydiff;
	ro = vec3(0., 5., 0.);
	rd = normalize(rotate_y(rotate_x(vec3(0.0, 0.0, 1.0), -uv.y * PI / 2.0), -uv.x * PI));
}

void mainImage(out vec4 fragColor, in vec2 fragCoord, in vec2 iResolution)
{
	vec3 ro = vec3(0., 0., 0.);
	vec3 rd = vec3(0.);
	vec3 col = vec3(0.);
	panorama_uv(fragCoord, ro, rd, iResolution);
	
	vec2 day_time;
	day_time.x = floor(DAY_TIME / 0.0835) + 1.0;
	day_time.y = abs(DAY_TIME - day_time.x * 0.0835) * 12.0;
	vec3 sky = render_sky_color(rd, day_time);
	vec4 cld = vec4(0.);
	float skyPow = dot(rd, vec3(0.0, -1.0, 0.0));
	float horizonPow = 1. - pow(1.0 - abs(skyPow), 5.0);
	if (rd.y > 0.)
	{cld = render_clouds(ro, rd);
	cld = clamp(cld, vec4(0.), vec4(1.));
	cld.rgb += 0.04 * cld.rgb * horizonPow;
	cld *= clamp((1.0 - exp(-2.3 * pow(max((0.0), horizonPow), (2.6)))), 0., 1.);
	}
	else{
	cld.rgb = cube_bot(rd, vec3(1.5,1.49,1.71), vec3(1.1,1.15,1.5));
	cld *= cld;
	//cld=clamp(cld,vec4(0.),vec4(1.));
	cld.a = 1.;
	cld *= clamp((1.0 - exp(-1.3 * pow(max((0.0), horizonPow), (2.6)))), 0., 1.);
	}
	col = mix(sky, cld.rgb / (0.0001 + cld.a), cld.a);
	if (day_time.x == 1.0 || day_time.x == 2.0 || day_time.x == 3.0 || day_time.x == 4.0 || day_time.x == 11.0 || day_time.x == 12.0) //Если ночь, закат или рассвет, надо рисовать звёзды и затемнять картинку
		{
			float luminosity;
			if (day_time.x == 4.0) luminosity = clamp(day_time.y, 0.0, 0.99);//постепенно осветляем с рассветом
			if (day_time.x == 11.0) luminosity = clamp(1.0 - day_time.y, 0.0, 0.99);//постепенно затеняем с закатом
			if (day_time.x == 1.0 || day_time.x == 2.0 || day_time.x == 3.0 || day_time.x == 12.0) luminosity = 0.99; //тёмная ночь
			col = mix(col, vec3(0.0,0.0,0.0), luminosity);
			//рисуем звёзды
			if (cld.rgb == vec3 (0.0, 0.0, 0.0)) //Если нет облаков
				{
					if (texture(iChannel1, vec2(abs(rd.x), abs(rd.z))).r > 0.5) //Если есть звёзды на текстуре (точка светлая, то рисуем звезду)
					{col = vec3(0.5, 0.5, 0.5);} //Рисуем звёзды с яркостью 0.5 //тут можно потом придумать мерцание
				//рисуем луну
				float phi = ((day_time.x-1.0) * 30.0 - day_time.y * 30.0) * 0.0174533;
				vec3 MOON_DIR = normalize(vec3(0, cos(phi), sin(phi)));
				float moon_amount = min(pow(max(dot(rd, MOON_DIR), 0.0), 3000.0) * 5.0, luminosity);
				col = col + moon_color * moon_amount;
				}
		}
	fragColor = vec4(col, 1.0);
}

void fragment(){
	vec2 iResolution = 1. / TEXTURE_PIXEL_SIZE;
	mainImage(COLOR, UV * iResolution, iResolution);
}
