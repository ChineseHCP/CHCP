#!/usr/bin/env make -f
# Makefile called by {SPM}/src/Makefile to compile SPM external's
#
# Copyright (C) 2008-2012 Wellcome Trust Centre for Neuroimaging
#
# $Id: Makefile 6144 2014-09-01 16:55:31Z guillaume $

include ../src/Makefile.var

FIELDTRIPMEX =\
	fieldtrip/src/read_24bit.$(SUF) fieldtrip/src/read_16bit.$(SUF) \
	fieldtrip/src/ft_getopt.$(SUF) \
	\
	fieldtrip/src/nanmean.$(SUF) fieldtrip/src/nannumel.$(SUF) \
	fieldtrip/src/nansum.$(SUF) fieldtrip/src/nanvar_base.$(SUF) \
	\
	fieldtrip/fileio/@uint64/max.$(SUF) fieldtrip/fileio/@uint64/min.$(SUF) \
	fieldtrip/fileio/@uint64/minus.$(SUF) fieldtrip/fileio/@uint64/plus.$(SUF) \
	fieldtrip/fileio/@uint64/rdivide.$(SUF) fieldtrip/fileio/@uint64/times.$(SUF) \
	fieldtrip/fileio/@uint64/abs.$(SUF) \
	\
	fieldtrip/src/meg_leadfield1.$(SUF) fieldtrip/src/ptriproj.$(SUF) \
	fieldtrip/src/lmoutr.$(SUF) fieldtrip/src/plgndr.$(SUF) \
	fieldtrip/src/solid_angle.$(SUF) fieldtrip/src/routlm.$(SUF) \
	\
	fieldtrip/src/ltrisect.$(SUF) fieldtrip/src/plinproj.$(SUF) \
	fieldtrip/src/splint_gh.$(SUF)
	
BEMCP = bemcp

all: $(FIELDTRIPMEX) bemcp-all

clean: bemcp-clean

distclean: clean bemcp-distclean
	$(DEL) $(FIELDTRIPMEX)

install: bemcp-install
	$(COPY) fieldtrip/src/read_24bit.$(SUF) fieldtrip/fileio/private/
	$(COPY) fieldtrip/src/read_16bit.$(SUF) fieldtrip/fileio/private/
	$(COPY) fieldtrip/src/nanmean.$(SUF) fieldtrip/fileio/private/
	$(COPY) fieldtrip/src/nannumel.$(SUF) fieldtrip/fileio/private/
	$(COPY) fieldtrip/src/nansum.$(SUF) fieldtrip/fileio/private/
	$(COPY) fieldtrip/src/nanvar_base.$(SUF) fieldtrip/fileio/private/
	$(COPY) fieldtrip/src/ft_getopt.$(SUF) fieldtrip/fileio/private/
	$(COPY) fieldtrip/src/solid_angle.$(SUF) fieldtrip/fileio/private/

	$(COPY) fieldtrip/src/meg_leadfield1.$(SUF) fieldtrip/forward/private/
	$(COPY) fieldtrip/src/ptriproj.$(SUF) fieldtrip/forward/private/
	$(COPY) fieldtrip/src/lmoutr.$(SUF) fieldtrip/forward/private/
	$(COPY) fieldtrip/src/plgndr.$(SUF) fieldtrip/forward/private/
	$(COPY) fieldtrip/src/solid_angle.$(SUF) fieldtrip/forward/private/
	$(COPY) fieldtrip/src/routlm.$(SUF) fieldtrip/forward/private/
	$(COPY) fieldtrip/src/ft_getopt.$(SUF) fieldtrip/forward/private/
	
	$(COPY) fieldtrip/src/solid_angle.$(SUF) fieldtrip/inverse/private/
	$(COPY) fieldtrip/src/ft_getopt.$(SUF) fieldtrip/inverse/private/
	
	$(COPY) fieldtrip/src/ptriproj.$(SUF) fieldtrip/private/
	$(COPY) fieldtrip/src/lmoutr.$(SUF) fieldtrip/private/
	$(COPY) fieldtrip/src/plgndr.$(SUF) fieldtrip/private/
	$(COPY) fieldtrip/src/routlm.$(SUF) fieldtrip/private/
	$(COPY) fieldtrip/src/solid_angle.$(SUF) fieldtrip/private/
	$(COPY) fieldtrip/src/nanmean.$(SUF) fieldtrip/private/
	$(COPY) fieldtrip/src/nannumel.$(SUF) fieldtrip/private/
	$(COPY) fieldtrip/src/nansum.$(SUF) fieldtrip/private/
	$(COPY) fieldtrip/src/nanvar_base.$(SUF) fieldtrip/private/

	$(COPY) fieldtrip/src/ft_getopt.$(SUF) fieldtrip/utilities/
	$(COPY) fieldtrip/src/nanmean.$(SUF) fieldtrip/utilities/private/
	$(COPY) fieldtrip/src/nannumel.$(SUF) fieldtrip/utilities/private/
	$(COPY) fieldtrip/src/nansum.$(SUF) fieldtrip/utilities/private/
	$(COPY) fieldtrip/src/nanvar_base.$(SUF) fieldtrip/utilities/private/
	$(COPY) fieldtrip/src/ptriproj.$(SUF) fieldtrip/utilities/private/
	$(COPY) fieldtrip/src/lmoutr.$(SUF) fieldtrip/utilities/private/

	$(COPY) fieldtrip/src/nanmean.$(SUF) fieldtrip/connectivity/private/
	$(COPY) fieldtrip/src/nannumel.$(SUF) fieldtrip/connectivity/private/
	$(COPY) fieldtrip/src/nansum.$(SUF) fieldtrip/connectivity/private/
	$(COPY) fieldtrip/src/nanvar_base.$(SUF) fieldtrip/connectivity/private/
	$(COPY) fieldtrip/src/ft_getopt.$(SUF) fieldtrip/connectivity/private/

	$(COPY) fieldtrip/src/nanmean.$(SUF) fieldtrip/statfun/private/
	$(COPY) fieldtrip/src/nannumel.$(SUF) fieldtrip/statfun/private/
	$(COPY) fieldtrip/src/nansum.$(SUF) fieldtrip/statfun/private/
	$(COPY) fieldtrip/src/nanvar_base.$(SUF) fieldtrip/statfun/private/

tarball: all bemcp-tarball
	$(TAR) cf spm_mex.tar $(FIELDTRIPMEX)
	$(TAR) Af spm_mex.tar $(BEMCP)/spm_mex.tar

bemcp bemcp-all bemcp-clean bemcp-distclean bemcp-install bemcp-tarball:
	@ $(MAKE) -C $(BEMCP) --no-print-directory $(subst -,,$(subst bemcp,,$@));

fieldtrip/src/%.$(SUF) : fieldtrip/src/%.c
	$(MEX) $< -outdir $(shell dirname $<) $(MEXEND)

fieldtrip/fileio/@uint64/%.$(SUF) : fieldtrip/fileio/@uint64/%.c
	$(MEX) $< -outdir $(shell dirname $<) $(MEXEND)

fieldtrip/src/lmoutr.$(SUF): fieldtrip/src/lmoutr.c fieldtrip/src/geometry.c fieldtrip/src/geometry.h
	$(MEX) $< -outdir $(shell dirname $<) fieldtrip/src/geometry.c $(MEXEND)

fieldtrip/src/routlm.$(SUF): fieldtrip/src/routlm.c fieldtrip/src/geometry.c fieldtrip/src/geometry.h
	$(MEX) $< -outdir $(shell dirname $<) fieldtrip/src/geometry.c $(MEXEND)

fieldtrip/src/ptriproj.$(SUF): fieldtrip/src/ptriproj.c fieldtrip/src/geometry.c fieldtrip/src/geometry.h
	$(MEX) $< -outdir $(shell dirname $<) fieldtrip/src/geometry.c $(MEXEND)

fieldtrip/src/solid_angle.$(SUF): fieldtrip/src/solid_angle.c fieldtrip/src/geometry.c fieldtrip/src/geometry.h
	$(MEX) $< -outdir $(shell dirname $<) fieldtrip/src/geometry.c $(MEXEND)

fieldtrip/src/ltrisect.$(SUF): fieldtrip/src/ltrisect.c fieldtrip/src/geometry.c fieldtrip/src/geometry.h
	$(MEX) $< -outdir $(shell dirname $<) fieldtrip/src/geometry.c $(MEXEND)

fieldtrip/src/plinproj.$(SUF): fieldtrip/src/plinproj.c fieldtrip/src/geometry.c fieldtrip/src/geometry.h
	$(MEX) $< -outdir $(shell dirname $<) fieldtrip/src/geometry.c $(MEXEND)
