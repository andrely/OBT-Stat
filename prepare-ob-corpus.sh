#!/bin/bash

cor_full=$1
path=`dirname ${cor_full}`
cor_file=`basename ${cor_full}`
sent_file=${cor_file}.sent
train_file=${cor_file}.train
eval_file=${cor_file}.eval
eval_source_file=${eval_file}.source
eval_source_utf8_file=${eval_source_file}.utf8
hunpos_model_file=${cor_file}.hunpos_model
lemma_model_file=${cor_file}.lemma_model
eval_mtag_file=${eval_source_file}.mtag
eval_ob_file=${eval_source_file}.ob
eval_ob_latin1_file=${eval_ob_file}.latin1

foni_home=/hf/foni/home/andrely/
foni_dir=ob-disambiguation-prototype/
foni_url=andrely@foni.uio.no

foni_mtag_cmd=/usr/local/bin/mtag-linux
foni_ob_cmd="/usr/local/bin/vislcg3 -C latin1 --codepage-input utf-8 -g /hf/foni/home/kristiha/cg3/bm_morf.cg --no-pass-origin --codepage-output utf-8"

echo "Writing sentence file" ${sent_file} >&2
ruby cor-to-train.rb ${path}/${cor_file} > ${path}/${sent_file}

echo "Splitting corpus into folds" >&2
ruby create_folds.rb ${path}/${train_file} ${path}/${eval_file} < ${path}/${sent_file}

for i in 0 1 2 3 4 5 6 7 8 9; do
		echo "Creating eval source file" ${path}/${i}/${eval_source_file} "for fold" ${i} >&2
		awk '{print $1}' ${path}/${i}/${eval_file} > ${path}/${i}/${eval_source_file}

		echo "Creating HunPos model file"  ${path}/${i}/${hunpos_model_file} "for fold" ${i} >&2
		cat ${path}/${i}/${train_file} | \
		# iconv -f iso-8859-1 -t utf-8 | tr '[A-ZÆØÅ]' '[a-zæøå]' | iconv -f utf-8 -t iso-8859-1 | \
		iconv -f iso-8859-1 -t utf-8 | 	perl -p -e 'tr/[A-ZÆØÅ]/[a-zæøå]/' | iconv -f utf-8 -t iso-8859-1 | \

		hunpos-1.0-macosx/hunpos-train ${path}/${i}/${hunpos_model_file}

		echo "Creating Lemma model"
		ruby create_lemma_model.rb < ${path}/${cor_file} > ${path}/${i}/${lemma_model_file}
		
		iconv -f iso-8859-1 -t utf-8 <  ${path}/${i}/${eval_source_file} >  ${path}/${i}/${eval_source_utf8_file}

		scp  ${path}/${i}/${eval_source_utf8_file} ${foni_url}:${foni_home}${foni_dir}
		echo "Run mtag at foni"
		cat ${path}/${i}/${eval_source_utf8_file} | ruby vrt_to_line.rb | ssh ${foni_url} ${foni_mtag_cmd} > ${path}/${i}/${eval_mtag_file}
		
		echo "Run OB at foni"
		ssh ${foni_url} ${foni_ob_cmd} < ${path}/${i}/${eval_mtag_file} > ${path}/${i}/${eval_ob_file}

		iconv -f utf-8 -t iso-8859-1 < ${path}/${i}/${eval_ob_file} > ${path}/${i}/${eval_ob_latin1_file}
done
