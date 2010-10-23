# Makefile for basic compilation of libproj4 software
#
# libproj4 -- library of cartographic projections
#
# Copyright (c) 2003, 2005, 2006   Gerald I. Evenden
#
# $Id: Makefile,v 1.2 2006/01/24 03:06:11 gie Exp $
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
#
#  The following is a site dependent, edittable section

prefix = /usr/local

# edit to reflect directory where system defaults and inits are located
LIB = $(prefix)/lib
BIN = $(prefix)/bin
INC = $(prefix)/include

# remove comment from following line to use GSL library
GSL=1

# remove comment from following line for thread friendly library
THREADS=1

# select local compiler to use
CC = gcc

# normally set on runline when debugging or testing file
T =

#------------- end of editables ----------------------------

L = libproj4.a

azim = \
	$L(proj_aeqd.o) $L(proj_aitoff.o) $L(proj_geos.o)	\
	$L(proj_gilbert.o) $L(proj_gnom.o) $L(proj_hammer.o)	\
	$L(proj_laea.o) $L(proj_mod_ster.o) $L(proj_nsper.o)	\
	$L(proj_nzmg.o) $L(proj_ortho.o) $L(proj_rouss.o)	\
	$L(proj_sterea.o) $L(proj_stere.o) $L(proj_wag7.o)	\
	$L(proj_wag9.o)

conic = \
	$L(proj_aea.o) $L(proj_bipc.o) $L(proj_bonne.o) \
	$L(proj_eqdc.o) $L(proj_hall.o) $L(proj_imw_p.o) \
	$L(proj_kocc.o) $L(proj_lcca.o) $L(proj_lcc.o) \
	$L(proj_poly.o) $L(proj_rpoly.o) $L(proj_sconics.o)

cylind = \
	$L(proj_ardn_cls.o) $L(proj_braun2.o) $L(proj_cass.o) \
	$L(proj_cc.o) $L(proj_cea.o) $L(proj_cubic.o) \
	$L(proj_cyl_stere.o) $L(proj_eqc.o) $L(proj_labrd.o) \
	$L(proj_lsat.o) $L(proj_merc.o) $L(proj_mill_2.o) \
	$L(proj_mill.o) $L(proj_mill_per.o) $L(proj_ocea.o) \
	$L(proj_omerc.o) $L(proj_somerc.o) $L(proj_stmerc.o) \
	$L(proj_tcc.o) $L(proj_tcea.o) $L(proj_tmerc.o) \
	$L(proj_tob_sqr.o)

misc = \
	$L(proj_airy.o) $L(proj_apian2.o) $L(proj_armadillo.o) \
	$L(proj_august.o) $L(proj_bacon.o) $L(proj_dummy.o) \
	$L(proj_eisen.o) $L(proj_four1.o) $L(proj_guyou.o) \
	$L(proj_lagrng.o) $L(proj_larr.o) $L(proj_lask.o) \
	$L(proj_nocol.o) $L(proj_ob_tran.o) $L(proj_oea.o) \
	$L(proj_tpeqd.o) $L(proj_vandg2.o) $L(proj_vandg4.o) \
	$L(proj_vandg.o)

pseudo = \
	$L(proj_baker.o) $L(proj_baranyi4.o) $L(proj_baranyi.o) \
	$L(proj_boggs.o) $L(proj_collg.o) $L(proj_crast.o) \
	$L(proj_denoy.o) $L(proj_eck1.o) $L(proj_eck2.o) \
	$L(proj_eck3.o) $L(proj_eck4.o) $L(proj_eck5.o) \
	$L(proj_equi_moll.o) $L(proj_erdi_ksz.o) $L(proj_fahey.o) \
	$L(proj_fc-loerr.o) $L(proj_fouc_s.o) $L(proj_four2.o) \
	$L(proj_gins8.o) $L(proj_gn_sinu.o) $L(proj_goode.o) \
	$L(proj_hatano.o) $L(proj_holzel.o) $L(proj_loxim.o) \
	$L(proj_maurer.o) $L(proj_mayr.o) $L(proj_mbtfpp.o) \
	$L(proj_mbtfpq.o) $L(proj_mbt_fps.o) $L(proj_mcb_s3.o) \
	$L(proj_moll.o) $L(proj_nell.o) $L(proj_nell_h.o) \
	$L(proj_oxford.o) $L(proj_putp2.o) $L(proj_putp3.o) \
	$L(proj_putp4p.o) $L(proj_putp5.o) $L(proj_putp6.o) \
	$L(proj_robin.o) $L(proj_semiconf.o) $L(proj_s_min_err.o) \
	$L(proj_sts.o) $L(proj_tob_g1.o) $L(proj_trapez.o) \
	$L(proj_urm5.o) $L(proj_urmfps.o) $L(proj_wag2.o) \
	$L(proj_wag3.o) $L(proj_wag5.o) $L(proj_wink1.o) \
	$L(proj_wink2.o)

support = \
	$L(proj_adjlon.o) $L(proj_auth.o) $L(proj_deriv.o) \
	$L(proj_dmstor.o) $L(proj_ellps.o) $L(proj_ell_set.o) \
	$L(proj_err_list.o) $L(proj_errno.o) $L(proj_factors.o) \
	$L(proj_fwd.o) $L(proj_gauss.o) $L(proj_init.o) \
	$L(proj_inv.o) $L(proj_list.o) $L(proj_mdist.o) \
	$L(proj_msfn.o) $L(proj_param.o) $L(proj_phi2.o) \
	$L(proj_pr_list.o) $L(proj_rtodms.o) $L(proj_strerrno.o) \
	$L(proj_strerror_r.o) $L(proj_trans.o) $L(proj_translate.o) \
	$L(proj_tsfn.o) $L(proj_units.o) $L(proj_zpoly1.o)

RLIB = $(azim) $(conic) $(cylind) $(misc) $(pseudo) $(support)

# set added libraries and Flags for Gnu Scientific Library
ifdef GSL
gsll = -lgsl -lgslcblas
gslf = -DPROJ_HAVE_GSL=1
endif

# set added library and flags for Threads compatibility
ifdef THREADS
thrl = -lpthread
thrf = -DPROJ_HAVE_THREADS=1
endif

CFLAGS = -O -I./ $(gslf) $(thrf)

LDFLAGS = -L./ -lproj4 $(gsll) $(thrl) -lm

lproj: lproj.o $T $L
	$(CC) -o lproj -I./ lproj.o $T -L./ -lproj4 $(gsll) $(thrl) -lm 

lproj.o: lib_proj.h

libproj4: $(RLIB)
	if [ -f /usr/bin/ranlib -o -f /bin/ranlib ] ; then ranlib $L ; fi

$(RLIB): lib_proj.h
proj_list.o: proj_list.h

all: libproj4

install:
	install libproj4.a $(LIB)
	install lproj $(BIN)
	install lib_proj.h $(INC)

clean:
	/bin/rm -f core *.o

veryclean:
	/bin/rm -f core *.o lproj libproj4.a

$(RLIB) : lib_proj.h
#
# $Log: Makefile,v $
# Revision 1.2  2006/01/24 03:06:11  gie
# correction.
#
# Revision 1.1  2006/01/24 01:16:03  gie
# Initial revision
#
