#version 460 core
precision highp float;

// CRT: the analog chain from the medium over the signal and its color encoding to the TV.
// One scanline per source row; the analog stages work along the lines in source pixels and in gamma
// space like real video, the tube (beam, mask, glow) works in linear light and the mask in output pixels.

#include <flutter/runtime_effect.glsl>

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

// medium
uniform float uMedium;         // 0 = none, 1 = VHS, 2 = Betamax, 3 = Video8, 4 = Technicolor film
uniform float uWear;           // 0 .. 1
// signal
uniform float uSignal;         // 0 = RGB, 1 = S-Video, 2 = composite, 3 = RF
uniform float uArtifacts;      // 0 .. 1, composite cross-talk: dot crawl and rainbows
uniform float uNoise;          // 0 .. 1, snow
uniform float uGhosting;       // 0 .. 1, delayed echo of the signal
// color encoding
uniform float uEncoding;       // 0 = NTSC, 1 = PAL
uniform float uPhaseError;     // -45 .. 45 degrees
// TV
uniform float uSharpness;      // 0 .. 1, edge peaking
uniform float uConvergence;    // 0 .. 1, red and blue beam offset in source pixels
uniform float uScanlines;      // 0 .. 1
uniform float uMask;           // 0 = none, 1 = aperture grille, 2 = slot mask, 3 = shadow mask
uniform float uMaskStrength;   // 0 .. 1
uniform float uBloom;          // 0 .. 1
uniform float uCurvature;      // 0 .. 1
uniform float uVignette;       // 0 .. 1
uniform float uBrightness;     // 0.5 .. 2

uniform sampler2D uSource;

out vec4 fragColor;

const float PI = 3.14159265;

// maximum opacity of the white Video8 dropout specks (0 = invisible, 1 = solid white flash);
// each speck gets a random opacity between 0 and this value
const float VIDEO8_DROPOUT_OPACITY = 0.3;

bool isMode(float value, float mode)
{
    return abs(value - mode) < 0.5;
}

float hash(vec2 p)
{
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float gauss(float d, float sigma)
{
    return exp(-0.5 * (d * d) / (sigma * sigma));
}

// gamma encoded source pixel; transparency shows as the black screen, outside the picture is blanking
vec3 sourcePixel(vec2 texel)
{
    if (texel.x < 0.0 || texel.y < 0.0 || texel.x >= uSourceSize.x || texel.y >= uSourceSize.y)
    {
        return vec3(0.0);
    }
    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);
    return texture(uSource, uv).rgb;
}

vec3 encode(vec3 c, bool pal)
{
    if (pal)
    {
        return mat3(0.299, -0.147, 0.615, 0.587, -0.289, -0.515, 0.114, 0.436, -0.100) * c;   // YUV
    }
    return mat3(0.299, 0.596, 0.211, 0.587, -0.274, -0.523, 0.114, -0.322, 0.312) * c;        // YIQ
}

vec3 decode(vec3 s, bool pal)
{
    if (pal)
    {
        return mat3(1.0, 1.0, 1.0, 0.0, -0.395, 2.032, 1.140, -0.581, 0.0) * s;
    }
    return mat3(1.0, 1.0, 1.0, 0.956, -0.272, -1.106, 0.621, -0.647, 1.703) * s;
}

// a VHS, Betamax or Video8 tape with some wear
bool isTape()
{
    return uMedium > 0.5 && uMedium < 3.5 && uWear > 0.0;
}

// a Technicolor (three-strip dye transfer) film print, scanned by a telecine
bool isFilm()
{
    return isMode(uMedium, 4.0);
}

// the source pixel as it appears on the medium: unchanged for tapes (they work on the signal),
// a dye transfer print for film
vec3 mediumPixel(vec2 texel)
{
    vec3 c = sourcePixel(texel);
    if (!isFilm() || texel.x < 0.0 || texel.y < 0.0 || texel.x >= uSourceSize.x || texel.y >= uSourceSize.y)
    {
        return c;
    }
    float wear = clamp(uWear, 0.0, 1.0);

    // three separate black and white records printed with pure dyes: every channel is cleaned of
    // the others, which gives the typical deep, pure primaries (crimson reds, rich greens, strong blues)
    c = mat3(1.30, -0.12, -0.06,
            -0.20, 1.28, -0.18,
            -0.10, -0.16, 1.24) * c;
    c = clamp(c, 0.0, 1.0);

    // extra saturation on top
    float luma = dot(c, vec3(0.299, 0.587, 0.114));
    c = clamp(mix(vec3(luma), c, 1.15), 0.0, 1.0);

    // print contrast: an S-curve with dense, inky blacks
    c = mix(c, c * c * (3.0 - 2.0 * c), 0.45);
    c = max(c - 0.04, 0.0) / 0.96;

    // warm, golden highlights and slightly cool, teal shadows
    c *= mix(vec3(0.94, 1.0, 1.06), vec3(1.04, 1.01, 0.94), smoothstep(0.0, 1.0, luma));

    // grain: three independent dye layers, strongest in the midtones; even a new print has some
    vec3 grain = vec3(hash(texel + 0.13), hash(texel + 0.47), hash(texel + 0.81)) - 0.5;
    c += grain * (0.08 + 0.25 * wear) * 4.0 * c * (1.0 - c);

    // vertical scratches along the running direction, broken into segments; they let light through
    if (hash(vec2(texel.x, 41.0)) < 0.015 * wear && hash(vec2(texel.x, floor(texel.y / 16.0) + 0.5)) < 0.7)
    {
        c = mix(c, vec3(1.0), 0.2 + 0.2 * hash(vec2(texel.x, texel.y + 0.25)));
    }

    // dust: specks on the print block the light, the rarer ones from the negative show bright
    vec2 cell = floor(texel / 8.0);
    vec2 spot = cell * 8.0 + floor(7.0 * vec2(hash(cell + 3.1), hash(cell + 5.7)));
    vec2 d = texel - spot;
    float size = hash(cell + 7.3) < 0.3 ? 2.0 : 1.0;
    if (hash(cell + 1.9) < 0.15 * wear && d.x >= 0.0 && d.y >= 0.0 && d.x < size && d.y < size)
    {
        c = hash(cell + 9.1) < 0.75 ? c * 0.15 : mix(c, vec3(1.0), 0.6);
    }

    return clamp(c, 0.0, 1.0);
}

// the value for the current tape format
float byTape(float vhs, float betamax, float video8)
{
    return isMode(uMedium, 1.0) ? vhs : (isMode(uMedium, 2.0) ? betamax : video8);
}

// whether the chain carries luma and chroma separately (any analog signal or a tape)
bool separateChroma()
{
    return !isMode(uSignal, 0.0) || isTape();
}

// the signal of row [r] at position [x] (source pixels) after medium, signal and encoding, always as Y and chroma:
// with a color space branch instead, some mobile GPUs decoded RGB that was never encoded (pink image)
vec3 lineSignal(float x, float r)
{
    float wear = clamp(uWear, 0.0, 1.0);
    bool tape = isTape();
    bool vhs = tape && isMode(uMedium, 1.0);
    bool betamax = tape && isMode(uMedium, 2.0);
    float signal = floor(uSignal + 0.5);
    bool pal = isMode(uEncoding, 1.0);
    bool yc = separateChroma();

    // tape: per line timing jitter (Betamax runs steadiest)
    if (tape)
    {
        x += (hash(vec2(r, 17.0)) - 0.5) * byTape(0.8, 0.4, 0.6) * wear;
    }

    // the thin metal tape of Video8 drops out often: the deck fills about half of the dropouts with the
    // line above, the others show as faint white specks
    float sampleRow = r;
    float dropout = 0.0;
    if (tape && isMode(uMedium, 3.0))
    {
        float cell = floor(x / 6.0);
        vec2 id = vec2(cell, r + 0.375);
        float begin = cell * 6.0 + 3.0 * hash(id + 0.25);
        if (hash(id) < 0.12 * wear && x >= begin && x < begin + 1.0 + 2.0 * hash(id + 0.5))
        {
            if (hash(id + 0.75) < 0.45)
            {
                sampleRow = r - 1.0;
            }
            else
            {
                dropout = VIDEO8_DROPOUT_OPACITY * hash(id + 0.875);
            }
        }
    }

    // bandwidths as gaussian widths in source pixels: RGB (practically lossless), S-Video, composite, RF
    float sigmaY = signal < 0.5 ? 0.05 : (signal < 1.5 ? 0.35 : (signal < 2.5 ? 0.55 : 0.7));
    float sigmaC = signal < 0.5 ? 0.05 : (signal < 1.5 ? 0.9 : (signal < 2.5 ? 1.2 : 1.4));
    // tapes record chroma with a fraction of the bandwidth: delayed and smeared to the right;
    // Betamax has the most bandwidth, so it stays sharper and smears less
    float sigmaLead = sigmaC;
    float sigmaTrail = sigmaC;
    float chromaDelay = 0.0;
    if (tape)
    {
        sigmaY = sqrt(sigmaY * sigmaY + byTape(0.5, 0.12, 0.3) * wear * wear);
        sigmaLead = sqrt(sigmaC * sigmaC + byTape(1.0, 0.5, 0.8) * wear * wear);
        sigmaTrail = sqrt(sigmaC * sigmaC + byTape(9.0, 5.0, 7.0) * wear * wear);
        chromaDelay = byTape(0.6, 0.4, 0.5) * wear;
    }
    sigmaLead = min(sigmaLead, 2.4);
    sigmaTrail = min(sigmaTrail, 2.4);
    float sigmaWide = sigmaY + 1.0;
    float ghostOffset = 4.0;

    vec3 sumMain = vec3(0.0);
    vec2 sumChromaFine = vec2(0.0);
    vec3 sumWide = vec3(0.0);
    vec3 sumGhost = vec3(0.0);
    float weightY = 0.0;
    float weightC = 0.0;
    float weightWide = 0.0;
    float weightGhost = 0.0;
    float base = floor(x);
    for (int k = -7; k <= 7; k++)
    {
        float column = base + float(k);
        float d = column + 0.5 - x;
        vec3 c = mediumPixel(vec2(column, sampleRow));
        vec3 e = encode(c, pal);

        float wy = gauss(d, sigmaY);
        float dc = d + chromaDelay;
        float wc = gauss(dc, dc < 0.0 ? sigmaTrail : sigmaLead);
        float ww = gauss(d, sigmaWide);
        float wg = gauss(d + ghostOffset, sigmaY);
        sumMain += vec3(e.x * wy, e.yz * wc);
        sumChromaFine += e.yz * wy;
        sumWide += e * ww;
        sumGhost += e * wg;
        weightY += wy;
        weightC += wc;
        weightWide += ww;
        weightGhost += wg;
    }
    vec3 s = vec3(sumMain.x / weightY, sumMain.yz / weightC);
    vec3 wide = sumWide / weightWide;
    vec3 ghost = sumGhost / weightGhost;
    // over RGB the luma effects below hit all channels alike
    float chromaLikeLuma = yc ? 0.0 : 1.0;

    // reflections in the cable or the antenna: a weaker copy a few pixels later
    float ghosting = 0.35 * clamp(uGhosting, 0.0, 1.0);
    s.x = mix(s.x, ghost.x, ghosting);
    s.yz = mix(s.yz, ghost.yz, ghosting * chromaLikeLuma);

    if (yc)
    {
        float lumaDetail = s.x - wide.x;
        vec2 chromaDetail = sumChromaFine / weightY - wide.yz;

        if (tape)
        {
            // tape noise, worst in the color; finer and weaker on Betamax, strongest on Video8
            float grain = byTape(2.0, 3.0, 2.0);
            float blotch = byTape(3.0, 2.0, 3.0);
            s.x += (hash(vec2(floor(x * grain), r + 0.25)) - 0.5) * byTape(0.06, 0.04, 0.1) * wear;
            s.yz += (vec2(hash(vec2(floor(x / blotch), r + 0.5)), hash(vec2(floor(x / blotch), r + 0.75))) - 0.5) * byTape(0.12, 0.06, 0.1) * wear;
            if (vhs)
            {
                // the color-under recording: pale colors that drop out for a line now and then, milky blacks and dull whites
                s.yz *= (1.0 - 0.45 * wear) * step(0.04 * wear * wear, hash(vec2(r, 29.0)));
                s.x = 0.07 * wear + s.x * (1.0 - 0.15 * wear);
                wide.x = 0.07 * wear + wide.x * (1.0 - 0.15 * wear);
            }
            else if (betamax)
            {
                // Betamax keeps most of the color, and the deck's detail enhancer draws crisp halos around edges
                s.yz *= 1.0 - 0.1 * wear;
                s.x += 0.6 * wear * lumaDetail;
            }
            else
            {
                // Video8 keeps more color than VHS and lifts the blacks less; a dropout shows as a faint white speck
                s.yz *= (1.0 - 0.25 * wear) * (1.0 - dropout);
                s.x = mix(0.04 * wear + s.x * (1.0 - 0.08 * wear), 0.8 + 0.4 * (hash(vec2(floor(x * 4.0), r + 0.625)) - 0.5), dropout);
                wide.x = 0.04 * wear + wide.x * (1.0 - 0.08 * wear);
            }
        }

        // composite and RF carry chroma on a subcarrier in the luma band that the TV filters out again:
        // a flat color is removed completely, but its edges leak into luma (dot crawl) and fine luma detail
        // is decoded as color (rainbows); the pattern follows the encoding
        if (signal > 1.5)
        {
            float period = pal ? 1.2 : 1.5;
            float phase = 2.0 * PI * x / period + r * (pal ? 1.5 * PI : PI);
            vec2 carrier = vec2(cos(phase), sin(phase));
            float artifacts = clamp(uArtifacts, 0.0, 1.0);
            s.x += artifacts * dot(chromaDetail, carrier);
            s.yz += 0.5 * artifacts * lumaDetail * carrier;
        }

        // a phase error turns the hue, on a tape it wanders from line to line;
        // PAL flips the phase every other line, so its delay line averages the error out
        float hue = radians(uPhaseError);
        if (tape)
        {
            hue += (hash(vec2(r, 23.0)) - 0.5) * byTape(0.5, 0.2, 0.35) * wear;
        }
        if (pal && mod(r, 2.0) >= 1.0)
        {
            hue = -hue;
        }
        s.yz = vec2(s.y * cos(hue) - s.z * sin(hue), s.y * sin(hue) + s.z * cos(hue));
    }

    // snow, strongest over the air (adding it to luma equals adding it to R, G and B alike)
    float noise = clamp(uNoise, 0.0, 1.0) * (signal > 2.5 ? 0.35 : 0.2);
    float n = hash(vec2(floor(x * 3.0), r + 0.125)) - 0.5;
    s.x += n * noise;
    if (signal > 2.5)
    {
        s.yz += (vec2(hash(vec2(floor(x * 3.0), r + 0.375)), hash(vec2(floor(x * 3.0), r + 0.625))) - 0.5) * noise * 0.5;
    }

    // the TV's sharpness control: edge peaking with its typical ringing
    float peaking = 1.5 * clamp(uSharpness, 0.0, 1.0);
    s.x += peaking * (s.x - wide.x);
    s.yz += peaking * chromaLikeLuma * (s.yz - wide.yz);
    return s;
}

// phosphor mask at output pixel [p]; keeps the average brightness
vec3 maskColor(vec2 p)
{
    float strength = clamp(uMaskStrength, 0.0, 1.0);
    float mode = floor(uMask + 0.5);
    if (mode < 0.5 || strength <= 0.0)
    {
        return vec3(1.0);
    }
    float dark = 1.0 - 0.7 * strength;
    vec3 m = vec3(dark);
    float phase;
    if (mode < 2.5)
    {
        phase = mod(p.x, 3.0);                                   // aperture grille / slot mask: RGB stripes
    }
    else
    {
        phase = mod(p.x + 3.0 * floor(p.y * 0.5), 6.0) * 0.5;  // shadow mask: triads shifted every two rows
    }
    if (phase < 1.0)
    {
        m.r = 1.0;
    }
    else if (phase < 2.0)
    {
        m.g = 1.0;
    }
    else
    {
        m.b = 1.0;
    }
    float average = (1.0 + 2.0 * dark) / 3.0;
    if (mode > 1.5 && mode < 2.5)
    {
        // slot mask: every fourth row of a triad is dark, staggered between neighboring triads
        float slotRow = mod(p.y + 2.0 * mod(floor(p.x / 3.0), 2.0), 4.0);
        if (slotRow >= 3.0)
        {
            m = vec3(dark);
        }
        average = (3.0 * average + dark) / 4.0;
    }
    return m / average;
}

void main()
{
    vec2 outSize = uSourceSize * uScale;
    vec2 q = FlutterFragCoord().xy + uOffset;
    vec2 uv = q / outSize;

    // curved tube
    vec2 cc = uv * 2.0 - 1.0;
    float curvature = clamp(uCurvature, 0.0, 1.0);
    cc *= vec2(1.0 + cc.y * cc.y * 0.06 * curvature, 1.0 + cc.x * cc.x * 0.08 * curvature);
    vec2 tube = cc * 0.5 + 0.5;
    vec2 edge = min(tube, 1.0 - tube) * outSize;
    float inside = clamp(min(edge.x, edge.y) + 0.5, 0.0, 1.0);
    if (inside <= 0.0)
    {
        fragColor = vec4(0.0, 0.0, 0.0, 1.0);
        return;
    }

    // the beam: the two nearest scanlines, a brighter line is a wider line
    vec2 t = tube * uSourceSize;
    float rowPos = t.y - 0.5;
    float r0 = floor(rowPos);
    float f = rowPos - r0;

    // all lineSignal() calls in one place, so the shader inlines it only once:
    // per scanline the green beam, the misconverged red and blue beams, and the previous line for the chroma
    bool yc = separateChroma();
    bool pal = isMode(uEncoding, 1.0);
    // the PAL delay line averages the chroma of two lines, so does the comb filter of a tape deck
    bool blendLines = yc && (pal || isTape());
    float lineBlend = pal ? 0.5 : 0.5 * min(2.0 * uWear, 1.0);
    float convergence = clamp(uConvergence, 0.0, 1.0);
    // Technicolor prints the three dye records one after another, so a worn print shows color fringes
    float registration = isFilm() ? clamp(uWear, 0.0, 1.0) : 0.0;
    float offsetR = -convergence + 0.4 * registration;
    float offsetB = convergence - 0.3 * registration;
    bool splitBeams = convergence > 0.0 || registration > 0.0;
    vec3 c0 = vec3(0.0);
    vec3 c1 = vec3(0.0);
    for (int row = 0; row < 2; row++)
    {
        vec3 color = vec3(0.0);
        for (int b = 0; b < 3; b++)
        {
            if (b > 0 && !splitBeams)
            {
                continue;
            }
            float x = t.x + (b == 1 ? offsetR : (b == 2 ? offsetB : 0.0));
            vec3 s = vec3(0.0);
            vec2 previousChroma = vec2(0.0);
            for (int line = 0; line < 2; line++)
            {
                if (line > 0 && !blendLines)
                {
                    continue;
                }
                vec3 v = lineSignal(x, r0 + float(row) - float(line));
                if (line == 0)
                {
                    s = v;
                }
                else
                {
                    previousChroma = v.yz;
                }
            }
            if (blendLines)
            {
                s.yz = mix(s.yz, previousChroma, lineBlend);
            }
            s = decode(s, pal);
            if (b == 0)
            {
                color = s;
            }
            else if (b == 1)
            {
                color.r = s.r;
            }
            else
            {
                color.b = s.b;
            }
        }
        color = pow(clamp(color, 0.0, 1.0), vec3(2.2));
        if (row == 0)
        {
            c0 = color;
        }
        else
        {
            c1 = color;
        }
    }
    // each beam carries the energy of its line, so the average brightness stays: dark lines are thin and bright,
    // bright lines wide enough to merge
    vec3 sigma0 = mix(vec3(0.2), vec3(0.4), c0);
    vec3 sigma1 = mix(vec3(0.2), vec3(0.4), c1);
    vec3 beam = c0 * exp(-0.5 * (f * f) / (sigma0 * sigma0)) / (sigma0 * 2.5066)
    + c1 * exp(-0.5 * ((1.0 - f) * (1.0 - f)) / (sigma1 * sigma1)) / (sigma1 * 2.5066);
    vec3 color = mix(f < 0.5 ? c0 : c1, beam, clamp(uScanlines, 0.0, 1.0));

    color *= maskColor(floor(q));

    // halation: light scattered in the glass
    float bloom = clamp(uBloom, 0.0, 1.0);
    if (bloom > 0.0)
    {
        vec3 glow = vec3(0.0);
        float weight = 0.0;
        for (int y = -2; y <= 2; y++)
        {
            for (int x = -2; x <= 2; x++)
            {
                vec2 o = vec2(float(x), float(y)) * 1.5;
                float w = exp(-dot(o, o) / 8.0);
                glow += pow(mediumPixel(floor(t + o)), vec3(2.2)) * w;
                weight += w;
            }
        }
        // the scattered light shows where the surroundings are brighter than the spot itself
        color += bloom * max(glow / weight - color, 0.0);
    }

    float vignette = 16.0 * tube.x * tube.y * (1.0 - tube.x) * (1.0 - tube.y);
    color *= pow(max(vignette, 0.0), 0.35 * clamp(uVignette, 0.0, 1.0));
    color *= max(uBrightness, 0.0);

    fragColor = vec4(pow(clamp(color, 0.0, 1.0), vec3(1.0 / 2.2)) * inside, 1.0);
}