#!/bin/sh

for i in 0 1 2 3 4 5 6 7 8 9
do
  ruby disamb-proto.rb -l log -v -a data-test/${i}/trening-u-flert-d.cor.lemma_model \
	-m data-test/${i}/trening-u-flert-d.cor.hunpos_model \
	-e data-test/${i}/trening-u-flert-d.cor.eval \
	< data-test/${i}/trening-u-flert-d.cor.eval.source.ob.latin1
done
