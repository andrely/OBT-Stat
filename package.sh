#!/bin/bash

VERSION=0.9.1-test
(cd ..; tar zcvf obt_stat/obt-stat-${VERSION}.tgz \
  obt_stat/bin/*.rb \
  obt_stat/lib/*.rb obt_stat/hunpos/* \
  obt_stat/models/nowac07_z10k-lemma-frq-noprop.lst \
  obt_stat/models/trening-u-flert-d.cor.hunpos_model \
	obt_stat/models/trening-u-flert-d.lemma_model \
	obt_stat/models/nowac07_z10k-lemma-frq-noprop.lst.utf8 \
  obt_stat/models/trening-u-flert-d.cor.hunpos_model.utf8 \
	obt_stat/models/trening-u-flert-d.lemma_model.utf8 \
	obt_stat/LICENCE.txt \
	obt_stat/gpl.txt )
	
