On building a BLAST predictor from scratch

1. Requirements.
  (1) "Training" data
      a. Sequence in FASTA format.
      b. GO annotation for each of these sequences (MFO for example) This data
         needs to be prepared ahead of time into the following format (splitted
         by TAB)
         [sequence ID] [GO term ID]
         where [sequence ID] would be of any system, as long as they are
         consistant with those used in the FASTA file.
  (2) NCBI BLAST tool (used 2.2.29+ for this document)
  (3) Query sequences in FASTA format.

2. Load annotations of training sequences.
   (in MATLAB) >> oa = pfp_oabuild(ont, [annotation_file]);
   where 'ont' is a MATLAB structure of ontology which can be built from
   pfp_ontbuild.m
   Note that a typical go.obo contains all three GO ontologies (i.e., MFO, BPO,
   and CCO), therefore, onts = pfp_ontbuild('go.obo') gives a cell of THREE
   ontology structures in 'onts'. By default, onts{1}: BPO, onts{2}: CCO,
   onts{3}: CCO, alphabetically.

3. Prepare blastp results.
   (1) Run BLAST on the query sequences against "training" sequences and keeps
       the output to be tabular as follows:
       -outfmt "6 qseqid sseqid evalue length pident nident"
   (2) Load the tabular output file into MATLAB:
       (in MATLAB) >> B = pfp_importblastp([tabular output]);

4. Put these together.
   (in MATLAB) pred = pfp_blast(qseqid, B, oa);
   where qseqid is a list of query sequences on which you need score. Note that
   it can be only a subset of all those you BLAST'ed. 'B' is from step 3, 'oa'
   is from step 2. Also, extra options can be specified as additional arguments
   to this function, see pfp_blast.m for more details.
   Thus, 'pred' will be the BLAST predictor in MATLAB for evaluation.
