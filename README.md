# CAFA2

[![](https://img.shields.io/badge/license-MIT-blue.svg)]()

MATLAB evaluation codes used for the 2nd [CAFA
challenge](http://biofunctionprediction.org/cafa/). Manuscript has been accepted
by *Genome Biology*, and you can find the latest *arXiv* version
[here](http://arxiv.org/abs/1601.00891).

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

## How to evaluate your own predictions on CAFA2 benchmarks

   Evaluation codes are provided mainly for reproducing results in CAFA2
   experiments. However, one may also use a subset of codes under `matlab/` to
   evaluate their own protein function predictors.

### Prerequisites

* Represent protein sequences using CAFA2 target ID systems (e.g.,
  `T96060000019`). Please check `benchmark/` folders for lists of benchmark
  proteins that needs to be covered.

* Save predictions in CAFA2 submission format according to [CAFA
  rule](https://www.synapse.org/#!Synapse:syn5840147/wiki/402192). Although,
  headers (including `AUTHOR`, `MODEL`, `KEYWORDS` and `ACCURACY`) and footer
  (`END`) are optional. (See `cafa_import.m` for details)

### Quick guide

1. Load ontologies into MATLAB structures.

    * You can use pre-built MATLAB structure for the same ontologies used in
    CAFA2 evaluation, which are located as `*.mat` files under `ontology/`
    folder.

    * We also provide functions for loading user specified ontologies, see
    `pfp_ontbuild.m`. Note that it is suggested to use pre-built ontologies in
    order to compare results against published methods.

2. Prepare ground-truth annotations.

    * Similarly, ground-truth annotations for CAFA2 `3681` benchmark proteins
      are pre-built and saved as `*.mat*` files under `benchmark/groundtruth/`.

    * User specified annotations can be built using `pfp_oabuild.m`, note that
      proteins have to use the same ID system as used for predictions. Also, see
      the comments for input arguments in `pfp_oabuild.m` for details.

      ```matlab
      oa = pfp_oabuild(ont, <annotation file>);
      ```

3. Load predictions into MATLAB structures.

    This can be done by execute the following command in MATALB:

    ```matlab
    pred = cafa_import(<prediction file>, ont, false);
    ```

    with the 2nd argument `ont` as the ontology structure built in the first
    step. We specify the 3rd argument to be `false` indicating our `<prediction
    file>` don't contain headers and footer.

4. Load benchmark protein IDs.

    * Protein IDs must be loaded as a `cell` array. You can use the following
      function:

      ```matlab
      benchmark = pfp_loaditem(<benchmark list file>, 'char');
      ```

    * Various CAFA2 benchmark protein lists are prepared under
      `benchmark/lists/`, load any one that meets your requirement.

5. Evaluation. (sequence-centered)

    * The easiest way to get an performance evaluation is to use the following
      function (in the case of **F-max**):

      ```matlab
      fmax = pfp_seqmetric(benchmark, pred, oa, 'fmax');
      ```

      See `pfp_seqmetric.m` for other metrics.

    * Alternatively, you can compute confusion matrix so as to expose
      intermediate variables:

       * Make a confusion matrix structure

         ```matlab
         cm = pfp_seqcm(benchmark, pred, oa);
         ```

       * Convert the `cm` structure to metrics of interest, here "precision-recall"
         `seq_pr.metric` would have 101 precision-recall pairs corresponding to 101
         thresholds from `0.00` up to `1.00` with step size `0.01`. You can use it
         to draw a PR curve.

         ```matlab
         seq_pr = pfp_convcmstruct(cm, 'pr');
         ```

# License
  The source code used in this CAFA2 evaluation package is licensed under the MIT
  license.
