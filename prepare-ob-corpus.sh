#!/bin/bash

cor_file=$1
sent_file=${cor_file}.sent
train_file=${cor_file}.train
held_file=${cor_file}.held
held_source_file=${held_file}.source
held_source_utf8_file=${held_source_file}.utf8
held_mtag_file=${held_source_file}.mtag
held_ob_file=${held_source_file}.ob
held_ob_latin1_file=${held_ob_file}.latin1
eval_file=${cor_file}.eval
hunpos_model_file=${cor_file}.hunpos_model

echo "Writing sentence file" ${sent_file} >&2
ruby cor-to-train.rb ${cor_file} > ${sent_file}

echo "Splitting corpus into " ${train_file} "," ${held_file} "and" ${eval_file} >&2
ruby corpus-split.rb ${train_file} ${held_file} ${eval_file} < ${sent_file}

echo "Creating held source file" ${held_source_file} >&2
awk '{print $1}' ${held_file} > ${held_source_file}

echo "Training HunPos model file" ${hunpos_model_file} >&2
cat  ${train_file} | iconv -f iso-8859-1 -t utf-8 | tr '[A-ZÆØÅ]' '[a-zæøå]' | iconv -f utf-8 -t iso-8859-1 | hunpos-1.0-macosx/hunpos-train ${hunpos_model_file}

# convert source file to utf-8
iconv -f iso-8859-1 -t utf-8 < ${held_source_file} > ${held_source_utf8_file}

foni_home=/hf/foni/home/andrely/
foni_dir=ob-disambiguation-prototype/
foni_url=andrely@foni.uio.no

foni_mtag_cmd=/usr/local/bin/mtag-linux
foni_ob_cmd="/usr/local/bin/vislcg3 -C latin1 --codepage-input utf-8 -g /hf/foni/home/kristiha/cg3/bm_morf.cg --no-pass-origin --codepage-output utf-8"

# copy source file to foni
# scp ${held_source_utf8_file} ${foni_url}:${foni_home}${foni_dir}

echo "Run mtag at foni"
# run mtag at foni
cat ${held_source_utf8_file} | ruby vrt_to_line.rb | ssh ${foni_url} ${foni_mtag_cmd} > ${held_mtag_file}

echo "Run OB at foni"
# run OB at foni
ssh ${foni_url} ${foni_ob_cmd} < ${held_mtag_file} > ${held_ob_file}

# convert ob output to latin1
iconv -f utf-8 -t iso-8859-1 < ${held_ob_file} > ${held_ob_latin1_file}

# echo "Running disambiguator" >&2
# ruby disamb-proto.rb -i ${held_source_file}.ob -e ${held_file} -m ${hunpos_model_file}
