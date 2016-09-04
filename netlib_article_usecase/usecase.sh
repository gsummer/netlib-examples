#!/bin/sh

netlib_primer=~/netlib/netlib-primer-1.0-jar-with-dependencies.jar
netlib_curator=~/netlib/netlib-curator-1.0-jar-with-dependencies.jar
netlib_edger=~/netlib/netlib-edger-1.0-jar-with-dependencies.jar
netlib_scribe=~/netlib/netlib-scribe-0.5-jar-with-dependencies.jar

usecase_dir=~/netlib/netlib_eccb2016_paper/usecase
usecase=$usecase_dir/graph.db

data_dir=$usecase_dir/data

dictionary=$data_dir/dictionary.txt

### BE CAREFUL with this one!
rm -rf $usecase

# import the gene nodes based on ensembl
java  -jar $netlib_primer -db $usecase -d $dictionary -no_array $data_dir/ensmusg.txt

java  -jar $netlib_primer -db $usecase -d $dictionary -no_new_nodes $data_dir/ensmusg_mgi.txt
java  -jar $netlib_primer -db $usecase -d $dictionary -no_new_nodes $data_dir/ensmusg_genename.txt
java  -jar $netlib_primer -db $usecase -d $dictionary -no_new_nodes $data_dir/ensmusg_entrez.txt
java  -jar $netlib_primer -db $usecase -d $dictionary -no_new_nodes $data_dir/ensmusg_ensmusp.txt

# import the refseq ids
java  -jar $netlib_primer -db $usecase -d $dictionary -no_new_nodes $data_dir/ensmusg_refseq.txt
java  -jar $netlib_primer -db $usecase -d $dictionary -no_new_nodes $data_dir/ensmusg_refseq_pred.txt
java  -jar $netlib_primer -db $usecase -d $dictionary -no_new_nodes $data_dir/ensmusg_refseq_ncrna.txt
java  -jar $netlib_primer -db $usecase -d $dictionary -no_new_nodes $data_dir/ensmusg_refseq_ncrna_pred.txt

java  -jar $netlib_primer -db $usecase -d $dictionary -no_index -label -no_new_nodes $data_dir/ensmusg_genetype.txt


#import miRNAs
java  -jar $netlib_primer -db $usecase -d $dictionary -t MIRBASE -x organism=mmu -no_array $data_dir/miRNA.dat
java  -jar $netlib_primer -db $usecase -d $dictionary -no_new_nodes -allow_multi -t MIRBASEALIAS $data_dir/aliases.txt

java -jar $netlib_scribe --db $usecase -qt cypher -ot tab -q "match (m) where has(m.mimat) set m:miRNA,m.type='miRNA'" dummy.csv

# add STRING mmu
java -jar $netlib_edger -db $usecase -x cutoff=399 -x -t STRING_Links $data_dir/10090.protein.links.detailed.v10.txt


# add miR targeting info
java -jar $netlib_edger -db $usecase -t TARGETSCAN -x family=$data_dir/miR_Family_Info.txt -x organism=10090 $data_dir/Predicted_Targets_Info.txt

java -jar $netlib_edger -db $usecase -t MIRTARBASE $data_dir/mmu_MTI.csv

java -jar $netlib_edger -db $usecase -x cutoff=80.0 -x organism=mmu -t MIRDB $data_dir/miRDB_v5.0_prediction_result.txt

java -jar $netlib_edger -db $usecase -x cutoff=0.7 -x organism=mmu -t MICROTCDS $data_dir/microT_CDS_data.csv


# miR targeting edge consolidation
java -jar $netlib_curator -db $usecase -t MIRC -x edgeType=mirna_targets -x mirlabel=miRNA -x name=miRc -x normfactor=4 -x weightname=score


# hypertrophy genes of interest
java -jar $netlib_primer -db $usecase -no_index -label -allow_multi -no_new_nodes $data_dir/genes_of_interest.txt



# mapping between mouse and human
java -jar $netlib_primer -db $usecase -d $dictionary -no_new_nodes -allow_multi $data_dir/ensmusg_ensg.txt
java -jar $netlib_primer -db $usecase -d $dictionary -no_new_nodes -allow_multi $data_dir/ensg_genename.txt


# add diseases from DisGeNet
java  -jar $netlib_primer -db $usecase -d $dictionary -t DGND $data_dir/all_gene_disease_associations.txt

java -jar $netlib_edger -db $usecase -t DGN $data_dir/all_gene_disease_associations.txt


java -jar $netlib_scribe -db $usecase -qt cypher -ot tab -q "match (m) where has(m.diseaseId) set m:Disease, m.type = 'disease'" dummy.csv





