#!/bin/bash
#
# This script computes the following facts for each ontology:
# (MFO, BPO, CCO, HPO)
# - number of benchmarks
# - species: (total counts) [species](per counts) ...
# - type1:
# - type2:


for tp in 1 2; do
  if [ ${tp} -eq 1 ]; then
    echo "**** TYPE-1 no-knowledge (NK) ****"
  elif [ ${tp} -eq 2 ]; then
    echo "**** TYPE-2 limited-knowledge (LK) ****"
  fi

  for ont in mfo bpo cco hpo; do
    echo "     ** [${ont}] **"
    ls ${ont}_*_type${tp}.txt | cut -d"_" -f2 | egrep "[^a-z]" > __tmp__
    echo "(`cat __tmp__ | wc -l`) species"
    for category in `cat __tmp__`; do
      echo "${category}  (`cat ${ont}_${category}_type${tp}.txt | wc -l`)"
    done
    rm __tmp__
  done
  echo ""
done

echo "**** BOTH TYPES ****"
for ont in mfo bpo cco hpo; do
  echo "     ** [${ont}] **"
  ls ${ont}_*_*.txt | cut -d"_" -f2 | egrep "[^a-z]" | sort -u > __tmp__
  echo "(`cat __tmp__ | wc -l`) species"
  for category in `cat __tmp__`; do
    echo "${category}  (`cat ${ont}_${category}_*.txt | sort -u | wc -l`)"
  done
  rm __tmp__
done
echo ""

bm_total=`cat *o_*_type*.txt | sort -u | egrep "^T[0-9]+" | wc -l`;
echo "total number of proteins: ${bm_total}"

ls *o_*_*.txt | cut -d"_" -f2 | egrep "[^a-z]" | sort -u > __tmp__
echo "(`cat __tmp__ | wc -l`) species"
for category in `cat __tmp__`; do
  echo "${category} (`cat *o_${category}_type*.txt | sort -u | wc -l`)";
done
rm __tmp__;

echo "MFO, NK: `cat mfo_*_type1.txt | sort -u | wc -l`, LK: `cat mfo_*_type2.txt | sort -u | wc -l`"
echo "BPO, NK: `cat bpo_*_type1.txt | sort -u | wc -l`, LK: `cat bpo_*_type2.txt | sort -u | wc -l`"
echo "CCO, NK: `cat cco_*_type1.txt | sort -u | wc -l`, LK: `cat cco_*_type2.txt | sort -u | wc -l`"
echo "HPO, NK: `cat hpo_*_type1.txt | sort -u | wc -l`"
