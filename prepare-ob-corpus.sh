#!/bin/bash

cor_file=$1
sent_file=${cor_file}.sent
train_file=${cor_file}.train
held_file=${cor_file}.held
held_source_file=${held_file}.source
eval_file=${cor_file}.eval
hunpos_model_file=${cor_file}.hunpos_model

echo "Writing sentence file" ${sent_file}
ruby cor-to-train.rb ${cor_file} > ${sent_file}

echo "Splitting corpus into " ${train_file} "," ${held_file} "and" ${eval_file}
ruby corpus-split.rb ${train_file} ${held_file} ${eval_file} < ${sent_file}

echo "Creating held source file" ${held_source_file}
awk '{print $1}' ${held_file} > ${held_source_file}

echo "Training HunPos model file" ${hunpos_model_file}
hunpos-1.0-macosx/hunpos-train ${hunpos_model_file} < ${train_file}