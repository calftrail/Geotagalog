/* General projections header file */
/*
** libproj4 -- library of cartographic projections
**
** $Id: lib_proj.h,v 3.2 2006/01/24 01:17:22 gie Exp $
**
** Copyright (c) 2003, 2005, 2006   Gerald I. Evenden
**
** Permission is hereby granted, free of charge, to any person obtaining
** a copy of this software and associated documentation files (the
** "Software"), to deal in the Software without restriction, including
** without limitation the rights to use, copy, modify, merge, publish,
** distribute, sublicense, and/or sell copies of the Software, and to
** permit persons to whom the Software is furnished to do so, subject to
** the following conditions:
**
** The above copyright notice and this permission notice shall be
** included in all copies or substantial portions of the Software.
**
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
** EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
** MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
** IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
** CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
** TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
** SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#ifndef PROJECTS_H
#define PROJECTS_H 1

    /* standard inclusions */
#include <math.h>
#include <stdlib.h>

	/* depending who's compiling */
#ifdef __cplusplus
#define BEGIN_C_DECLS extern "C" {
#define END_C_DECLS  }
#else
#define BEGIN_C_DECLS
#define END_C_DECLS
#endif

	/* some useful constants */
#define HALFPI		1.5707963267948966
#define FORTPI		0.78539816339744833
#ifndef PI
#define PI		3.14159265358979323846
#endif
#define TWOPI		6.2831853071795864769
#define RAD_TO_DEG	57.29577951308232
#define DEG_TO_RAD	.0174532925199432958

typedef struct { double u, v; }	PROJ_UV;
typedef struct { double r, i; }	PROJ_COMPLEX;

#ifdef PROJ_UV_TYPE
#define PROJ_XY PROJ_UV
#define PROJ_LP PROJ_UV
#else
typedef struct { double x, y; }     PROJ_XY;
typedef struct { double lam, phi; } PROJ_LP;
#endif

extern int * proj_errno_loc(void);
#define proj_errno (*proj_errno_loc())

typedef struct {int errnum; char * name; } PROJ_ERR_LIST;
typedef union { double  f; int  i; const char *s; } PROJ_PVALUE;

struct PROJ_ELLPS {
	char	*id;	/* ellipse keyword name */
	char	*major;	/* a= value */
	char	*ell;	/* elliptical parameter */
	char	*name;	/* comments */
};
struct PROJ_UNITS {
	char	*id;	/* units keyword */
	char	*to_meter;	/* multiply by value to get meters */
	char	*name;	/* comments */
};
struct PROJ_DERIVS {
		double x_l, x_p; /* derivatives of x for lambda-phi */
		double y_l, y_p; /* derivatives of y for lambda-phi */
};
struct PROJ_FACTORS {
	struct PROJ_DERIVS der;
	double h, k;	/* meridinal, parallel scales */
	double omega, thetap;	/* angular distortion, theta prime */
	double conv;	/* convergence */
	double s;		/* areal scale factor */
	double a, b;	/* max-min scale error */
	int code;		/* info as to analytics, see following */
};
#define IS_ANAL_XL_YL 01	/* derivatives of lon analytic */
#define IS_ANAL_XP_YP 02	/* derivatives of lat analytic */
#define IS_ANAL_HK	04		/* h and k analytic */
#define IS_ANAL_CONV 010	/* convergence analytic */
    /* parameter list struct */
typedef struct ARG_list {
	struct ARG_list *next;
	char used;
	char param[1]; } paralist;
	/* base projection data structure */
typedef struct PROJconsts {
	PROJ_XY  (*fwd)(PROJ_LP, struct PROJconsts *);
	PROJ_LP  (*inv)(PROJ_XY, struct PROJconsts *);
	void (*spc)(PROJ_LP, struct PROJconsts *, struct PROJ_FACTORS *);
	void (*pfree)(struct PROJconsts *);
	const char *descr;
	paralist *params;   /* parameter list */
	int over;   /* over-range flag */
	int geoc;   /* geocentric latitude flag */
	double
		a,  /* major axis or radius if es==0 */
		e,  /* eccentricity */
		es, /* e ^ 2 */
		ra, /* 1/A */
		one_es, /* 1 - e^2 */
		rone_es, /* 1/one_es */
		lam0, phi0, /* central longitude, latitude */
		x0, y0, /* easting and northing */
		k0,	/* general scaling factor */
		to_meter, fr_meter; /* cartesian scaling */
#ifdef PROJ_PARMS__
PROJ_PARMS__
#endif /* end of optional extensions */
} PROJ;

struct PROJ_LIST {
	char	*id;		/* projection keyword */
	PROJ	*(*proj)(PROJ *);	/* projection entry point */
	char 	* const *descr;	/* description text */
};

/* Generate proj_list external or make list from include file */
#ifndef PROJ_LIST_H
extern const struct PROJ_LIST proj_list[];
#else
#define PROJ_HEAD(id, name) \
	extern PROJ *proj_##id(PROJ *); extern char * const proj_s_##id;
#include PROJ_LIST_H
#undef PROJ_HEAD
#define PROJ_HEAD(id, name) {#id, proj_##id, &proj_s_##id},
	const struct PROJ_LIST
proj_list[] = {
#include PROJ_LIST_H
		{0,     0,  0},
	};
#undef PROJ_HEAD
#endif

#ifndef PROJ_ELLPS__
extern const struct PROJ_ELLPS proj_ellps[];
#endif

#ifndef PROJ_UNITS__
extern const struct PROJ_UNITS proj_units[];
#endif

#ifdef PROJ_LIB__
    /* repeatative projection code */
#define PROJ_HEAD(id, name) static const char des_##id [] = name
#define ENTRYA(name) const char * const proj_s_##name = des_##name; \
	PROJ *proj_##name(PROJ *P) { if (!P) { \
	if ((P = (PROJ *)malloc(sizeof(PROJ)))) { \
	P->pfree = freeup; P->fwd = 0; P->inv = 0; \
	P->spc = 0; P->descr = des_##name;
#define ENTRYX } return P; } else {
#define ENTRY0(name) ENTRYA(name) ENTRYX
#define ENTRY1(name, a) ENTRYA(name) P->a = 0; ENTRYX
#define ENTRY2(name, a, b) ENTRYA(name) P->a = 0; P->b = 0; ENTRYX
#define ENDENTRY(p) } return (p); }
#define E_ERROR(err) { proj_errno = err; freeup(P); return(0); }
#define E_ERROR_0 { freeup(P); return(0); }
#define F_ERROR { proj_errno = -20; return(xy); }
#define I_ERROR { proj_errno = -20; return(lp); }
#define FORWARD(name) static PROJ_XY name(PROJ_LP lp,PROJ*P) {PROJ_XY xy={0.,0.}
#define INVERSE(name) static PROJ_LP name(PROJ_XY xy,PROJ*P) {PROJ_LP lp={0.,0.}
#define FREEUP static void freeup(PROJ *P) {
#define SPECIAL(name) static void name(PROJ_LP lp, PROJ *P, struct PROJ_FACTORS *fac)
#endif
	/* procedure prototypes */
double  proj_dmstor(const char *, char **);
void proj_set_rtodms(int, int);
char *proj_rtodms(char *, double, const char *);
double proj_adjlon(double);
double proj_acos(double), proj_asin(double), proj_sqrt(double),
	proj_atan2(double, double);
PROJ_PVALUE proj_param(paralist *, const char *);
paralist *proj_mkparam(char *);
int proj_ell_set(paralist *, double *, double *);
void *proj_mdist_ini(double);
double proj_mdist(double, double, double, const void *);
double proj_inv_mdist(double, const void *);
void *proj_gauss_ini(double, double, double *,double *);
PROJ_LP proj_gauss(PROJ_LP, const void *);
PROJ_LP proj_inv_gauss(PROJ_LP, const void *);
PROJ_LP proj_translate(PROJ_LP, const void *);
PROJ_LP proj_inv_translate(PROJ_LP, const void *);
void *proj_translate_ini(double, double);
double proj_tsfn(double, double, double);
double proj_msfn(double, double, double);
double proj_phi2(double, double);
double proj_qsfn(double, const void *);
void *proj_auth_ini(double, double *);
double proj_auth_lat(double, const void *);
double proj_auth_inv(double, const void *);
PROJ_COMPLEX proj_zpoly1(PROJ_COMPLEX, PROJ_COMPLEX *, int);
PROJ_COMPLEX proj_zpolyd1(PROJ_COMPLEX, PROJ_COMPLEX *, int, PROJ_COMPLEX *);
int proj_deriv(PROJ_LP, double, PROJ *, struct PROJ_DERIVS *);
int proj_factors(PROJ_LP, PROJ *, double, struct PROJ_FACTORS *);
PROJ_XY proj_fwd(PROJ_LP, PROJ *);
PROJ_LP proj_inv(PROJ_XY, PROJ *);
void proj_pr_list(PROJ *);
void proj_free(PROJ *);
PROJ *proj_init(int, char **);
char *proj_strerrno(int);
int proj_strerror_r(int, char *, int);

#endif /* end of basic projections header */
/*
** $Log: lib_proj.h,v $
** Revision 3.2  2006/01/24 01:17:22  gie
** updates
**
** Revision 3.1  2006/01/11 02:41:14  gie
** Initial
**
**
*/
