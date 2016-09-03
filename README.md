# CAFA2
MATLAB evaluation codes used for the [2nd CAFA](http://arxiv.org/abs/1601.00891) experiment.

## How to build baseline predictors

### *BLAST* predictor

#### Requirements
  - "Training" data
    - Sequences in **FASTA** format.
    - Annotations (MFO terms for exmaple) for each of these sequences. This data
      needs to be prepared ahead of time as a two-column **CSV** file (delimited
      by TAB)

      ```
      [sequence ID]\t[GO term ID]
      ```

      where `[sequence ID]` would be of any system (e.g., UniProt accession
      number), as long as they are consistant with those used in the FASTA file.
  - NCBI BLAST tool (used 2.2.29+ for this document)
  - Query sequences in **FASTA** format.

#### Step-by-step

* ***STEP 1:*** Load annotations of training sequences.

```matlab
oa = pfp_oabuild(ont, 'annotation.dat');
```

where `ont` is a MATLAB structure of ontology which can be built from and OBO
file (say, 'ontology.obo') as

```matlab
ont = pfp_ontbuild('ontology.obo');
```

Note that a typical gene ontology OBO file contains all three GO ontologies
(i.e., MFO, BPO, and CCO), therefore, `pfp_ontbuild` returns a cell
of **THREE** ontology strcutures instead:

```matlab
onts = pfp_ontbuild('go.obo')
```

By default, they are ordered as BPO, CCO, MFO, alphabetically. You can also
double check the `.ont_type` field of each returning structure.

* ***STEP 2:*** Prepare BLAST results
  - Run `blastp` on the query sequences against the "training" sequences
    by setting output format to be the following:

    ```bash
    blastp ... -outfmt "6 qseqid sseqid evalue length pident nident" -out blastp.out
    ```

  - Load the tabular output file (`blastp.out` as shown above) into MATLAB:

    ```matlab
    B = pfp_importblastp('blastp.out');
    ```

* ***STEP 3:*** Build the *BLAST* predictor

  ```matlab
  blast = pfp_blast(qseqid, B, oa);
  ```

  where `qseqid` is a cell list of query sequences on which you need scores.
  Note that it can be just a subset of all those you BLAST'ed. `B` is the
  structure imported step 2, while `oa` is the ontology annotation structure
  loaded in step 1.

  Also, extra options can be specified as additional arguments to this function.
  See the documentation of `pfp_blast.m` for more details. Thus, `blast` will be
  the *BLAST* predictor in MATLAB for evaluation.

### *Naive* predictor

To build a *naive* predictor, all you need is the ontology annotation structure
`oa` that you have as in the step 1 of making a *BLAST* predictor. Then run the
following in MATLAB:

```matlab
naive = pfp_naive(qseqid, oa);
```

# License
  The source code used in this CAFA2 evaluation package is licensed under the MIT
  license.
