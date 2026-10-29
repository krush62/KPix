#version 460 core
precision highp float;

// SPDX-FileCopyrightText: 2011-2022 Hyllian <sergiogdb@gmail.com>
// SPDX-License-Identifier: MIT

#include <flutter/runtime_effect.glsl>

// Hyllian's xBR-lv2 (standalone), ported from the libretro slang version, corner detection C.
// KPix changes: texel taps instead of texture offsets, the 4x3 matrices of four pixels as a struct
// (the Skia backend has no non-square matrices), colors keep their alpha and alpha counts as a difference.

/*
   Hyllian's xBR-lv2 Shader

   Copyright (C) 2011-2022 Hyllian - sergiogdb@gmail.com

   Permission is hereby granted, free of charge, to any person obtaining a
   copy of this software and associated documentation files (the
   "Software"), to deal in the Software without restriction, including
   without limitation the rights to use, copy, modify, merge, publish,
   distribute, sublicense, and/or sell copies of the Software, and to permit
   persons to whom the Software is furnished to do so, subject to the
   following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
   DEALINGS IN THE SOFTWARE.

   Incorporates some of the ideas from SABR shader. Thanks to Joshua Street.
*/

// set by the renderer for every export shader
uniform vec2 uOffset;
uniform vec2 uSourceSize;
uniform float uScale;
uniform float uFlipY;

uniform float uEqThreshold;   // XBR_EQ_THRESHOLD
uniform float uCoefficient;   // XBR_LV2_COEFFICIENT
uniform float uBlending;      // XBR_BLENDING

uniform sampler2D uSource;

out vec4 fragColor;

const vec4 Ao = vec4( 1.0, -1.0, -1.0, 1.0 );
const vec4 Bo = vec4( 1.0,  1.0, -1.0,-1.0 );
const vec4 Co = vec4( 1.5,  0.5, -0.5, 0.5 );
const vec4 Ax = vec4( 1.0, -1.0, -1.0, 1.0 );
const vec4 Bx = vec4( 0.5,  2.0, -0.5,-2.0 );
const vec4 Cx = vec4( 1.0,  1.0, -0.5, 0.0 );
const vec4 Ay = vec4( 1.0, -1.0, -1.0, 1.0 );
const vec4 By = vec4( 2.0,  0.5, -2.0,-0.5 );
const vec4 Cy = vec4( 2.0,  0.0, -1.0, 0.5 );
const vec4 Ci = vec4(0.25, 0.25, 0.25, 0.25);

const vec3 v2f = vec3( 65536, 256, 1); // vec to float encode
const vec3 Y = vec3(0.2627, 0.6780, 0.0593);

// the columns of an upstream mat4x3
struct Quad
{
    vec4 p0;
    vec4 p1;
    vec4 p2;
    vec4 p3;
};

vec4 tap(vec2 texel)
{
    vec2 uv = (texel + 0.5) / uSourceSize;
    uv.y = mix(uv.y, 1.0 - uv.y, uFlipY);
    return texture(uSource, uv);
}

// Return if A components are less than or equal B ones.
vec4 LTE(vec4 A, vec4 B)
{
    return step(A, B);
}

// Return if A components are less than B ones.
vec4 LT(vec4 A, vec4 B)
{
    return vec4(lessThan(A, B));
}

// Return logically inverted vector components. BEWARE: Only works with 0.0 or 1.0 components.
vec4 NOT(vec4 A)
{
    return (vec4(1.0) - A);
}

// Compare two vectors and return their components are different.
vec4 diff(vec4 A, vec4 B)
{
    return vec4(notEqual(A, B));
}

// v2f * mat4x3: one number per pixel for exact comparisons
vec4 encode(Quad q)
{
    return vec4(dot(v2f, q.p0.rgb), dot(v2f, q.p1.rgb), dot(v2f, q.p2.rgb), dot(v2f, q.p3.rgb));
}

vec4 alphas(Quad q)
{
    return vec4(q.p0.a, q.p1.a, q.p2.a, q.p3.a);
}

float dist(vec4 A, vec4 B)
{
    return dot(abs(A.rgb - B.rgb), Y) + abs(A.a - B.a);
}

// Calculate color distance between two vectors of four pixels
vec4 dist4(Quad A, Quad B)
{
    return vec4(dist(A.p0, B.p0), dist(A.p1, B.p1), dist(A.p2, B.p2), dist(A.p3, B.p3));
}

// Tests if color components are under a threshold. In this case they are considered 'equal'.
vec4 eq(Quad A, Quad B)
{
    return (step(dist4(A, B), vec4(uEqThreshold)));
}

// Determine if two vector components are NOT equal based on a threshold.
vec4 neq(Quad A, Quad B)
{
    return (vec4(1.0, 1.0, 1.0, 1.0) - eq(A, B));
}

// Calculate weighted distance among pixels in some directions.
vec4 weighted_distance(Quad a, Quad b, Quad c, Quad d, Quad e, Quad f, Quad g, Quad h)
{
    return (dist4(a,b) + dist4(a,c) + dist4(d,e) + dist4(d,f) + 4.0*dist4(g,h));
}

void main()
{
    vec2 position = (FlutterFragCoord().xy + uOffset) / uScale;
    vec2 texel = floor(position);
    vec2 fp = fract(position);
    float aa_factor = 2.0 / uScale;
    float lv2_cf = uCoefficient + 2.0;

    vec4 edri, edr, edr_l, edr_u, px; // px = pixel, edr = edge detection rule
    vec4 irlv0, irlv1, irlv2l, irlv2u;
    vec4 fx, fx_l, fx_u; // inequations of straight lines.
    vec4 res1, res2;
    vec4 fx45i, fx45, fx30, fx60;

    //    A1 B1 C1
    // A0  A  B  C C4
    // D0  D  E  F F4
    // G0  G  H  I I4
    //    G5 H5 I5

    vec4 A1 = tap(texel + vec2(-1.0, -2.0));
    vec4 B1 = tap(texel + vec2( 0.0, -2.0));
    vec4 C1 = tap(texel + vec2( 1.0, -2.0));
    vec4 A  = tap(texel + vec2(-1.0, -1.0));
    vec4 B  = tap(texel + vec2( 0.0, -1.0));
    vec4 C  = tap(texel + vec2( 1.0, -1.0));
    vec4 D  = tap(texel + vec2(-1.0,  0.0));
    vec4 E  = tap(texel);
    vec4 F  = tap(texel + vec2( 1.0,  0.0));
    vec4 G  = tap(texel + vec2(-1.0,  1.0));
    vec4 H  = tap(texel + vec2( 0.0,  1.0));
    vec4 I  = tap(texel + vec2( 1.0,  1.0));
    vec4 G5 = tap(texel + vec2(-1.0,  2.0));
    vec4 H5 = tap(texel + vec2( 0.0,  2.0));
    vec4 I5 = tap(texel + vec2( 1.0,  2.0));
    vec4 A0 = tap(texel + vec2(-2.0, -1.0));
    vec4 D0 = tap(texel + vec2(-2.0,  0.0));
    vec4 G0 = tap(texel + vec2(-2.0,  1.0));
    vec4 C4 = tap(texel + vec2( 2.0, -1.0));
    vec4 F4 = tap(texel + vec2( 2.0,  0.0));
    vec4 I4 = tap(texel + vec2( 2.0,  1.0));

    Quad b  = Quad(B, D, H, F);
    Quad c  = Quad(C, A, G, I);
    Quad d  = Quad(D, H, F, B);
    Quad e  = Quad(E, E, E, E);
    Quad f  = Quad(F, B, D, H);
    Quad g  = Quad(G, I, C, A);
    Quad h  = Quad(H, F, B, D);
    Quad i  = Quad(I, C, A, G);

    Quad i4 = Quad(I4, C1, A0, G5);
    Quad i5 = Quad(I5, C4, A1, G0);
    Quad h5 = Quad(H5, F4, B1, D0);
    Quad f4 = Quad(F4, B1, D0, H5);

    // the encoded colors and, kept apart, the alphas
    vec4 b_   = encode(b);
    vec4 c_   = encode(c);
    vec4 d_   = b_.yzwx;
    vec4 e_   = encode(e);
    vec4 f_   = b_.wxyz;
    vec4 g_   = c_.zwxy;
    vec4 h_   = b_.zwxy;
    vec4 ba   = alphas(b);
    vec4 ca   = alphas(c);
    vec4 da   = ba.yzwx;
    vec4 ea   = alphas(e);
    vec4 fa   = ba.wxyz;
    vec4 ga   = ca.zwxy;
    vec4 ha   = ba.zwxy;

    // These inequations define the line below which interpolation occurs.
    fx    = ( Ao*fp.y + Bo*fp.x );
    fx_l  = ( Ax*fp.y + Bx*fp.x );
    fx_u  = ( Ay*fp.y + By*fp.x );

    irlv0 = max(diff(e_,f_), diff(ea,fa)) * max(diff(e_,h_), diff(ea,ha));

    // CORNER_C
    irlv1     = clamp(irlv0  * ( neq(f,b) * neq(f,c) + neq(h,d) * neq(h,g) + eq(e,i) * (neq(f,f4) * neq(f,i4) + neq(h,h5) * neq(h,i5)) + eq(e,g) + eq(e,c)), 0.0, 1.0);

    irlv2l = max(diff(e_,g_), diff(ea,ga)) * max(diff(d_,g_), diff(da,ga));
    irlv2u = max(diff(e_,c_), diff(ea,ca)) * max(diff(b_,c_), diff(ba,ca));

    if (uBlending > 0.5) {
        vec4 delta  = vec4(aa_factor);
        vec4 deltaL = vec4(0.5, 1.0, 0.5, 1.0) * aa_factor;
        vec4 deltaU = deltaL.yxwz;

        fx45i = clamp( 0.5 + (fx   - Co - Ci) / delta , 0.0, 1.0);
        fx45  = clamp( 0.5 + (fx   - Co     ) / delta , 0.0, 1.0);
        fx30  = clamp( 0.5 + (fx_l - Cx     ) / deltaL, 0.0, 1.0);
        fx60  = clamp( 0.5 + (fx_u - Cy     ) / deltaU, 0.0, 1.0);
    }
    else {
        fx45i = LT( Co + Ci, fx   );
        fx45  = LT(      Co, fx   );
        fx30  = LT(      Cx, fx_l );
        fx60  = LT(      Cy, fx_u );
    }

    vec4 wd1 = weighted_distance( e, c,  g, i, h5, f4, h, f);
    vec4 wd2 = weighted_distance( h, d, i5, f, i4,  b, e, i);

    vec4 d_fg = dist4(f, g);
    vec4 d_hc = dist4(h, c);

    edri      = LTE(wd1, wd2) * irlv0;
    edr       = LT( wd1, wd2) * irlv1 * NOT(edri.yzwx * edri.wxyz);
    edr_l     = LTE( lv2_cf * d_fg, d_hc ) * irlv2l * edr * (NOT(edri.yzwx) * eq(e, c));
    edr_u     = LTE( lv2_cf * d_hc, d_fg ) * irlv2u * edr * (NOT(edri.wxyz) * eq(e, g));

    fx45i = edri   * fx45i;
    fx45  = edr    * fx45;
    fx30  = edr_l  * fx30;
    fx60  = edr_u  * fx60;

    px = LTE(dist4(e,f), dist4(e,h));

    vec4 maximos = max(max(fx30, fx60), max(fx45, fx45i));

    res1 = mix(E, mix(H, F, px.x), maximos.x);
    res2 = mix(E, mix(B, D, px.z), maximos.z);

    vec4 res1a = mix(res1, res2, step(dist(E, res1), dist(E, res2)));

    res1 = mix(E, mix(F, B, px.y), maximos.y);
    res2 = mix(E, mix(D, H, px.w), maximos.w);

    vec4 res1b = mix(res1, res2, step(dist(E, res1), dist(E, res2)));

    fragColor = mix(res1a, res1b, step(dist(E, res1a), dist(E, res1b)));
}
