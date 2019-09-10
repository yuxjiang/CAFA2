# CAFA2

[![](https://img.shields.io/badge/license-MIT-blue.svg)]()
[![DOI](https://zenodo.org/badge/39267609.svg)](https://zenodo.org/badge/latestdoi/39267609)


MATLAB evaluation codes used for the 2nd [CAFA
challenge](http://biofunctionprediction.org/cafa/). The CAFA2
[paper](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-016-1037-6)
is published in *Genome Biology*, and you can also find the latest *arXiv* version
[here](http://arxiv.org/abs/1601.00891).

## How to build baseline predictors

### *BLAST* predictor

#### Requirements
1. "Training" data

    * Sequences in **FASTA** format.

    * Annotations (MFO terms for exmaple) for each of these sequences. This data
      needs to be prepared ahead of time as a two-column **CSV** file (delimited
      by `TAB`)

      ```
      <sequence ID> <GO term ID>
      ```

      where `<sequence ID>` would be of any ID systems (e.g., UniProt accession
      number), as long as they are consistant with those used in the FASTA file.

  2. NCBI BLAST tool (used 2.2.29+ for this document)

  3. Query sequences in **FASTA** format.

#### Step-by-step
* ***STEP 1:*** Load annotations of training sequences.
    * Load ontology structure(s)

      Ontologies need to be load into a specific MATLAB structure which will be
      later used in evaluation. Here we provide two "adapters" for (i) OBO files or
      (ii) parsed plain-text files.

      1. Load OBO files

         ```matlab
         ont = pfp_ontbuild('ontology.obo');
         ```

         Note that a typical gene ontology OBO file contains all three GO
         ontologies (i.e., MFO, BPO, and CCO), therefore, `pfp_ontbuild` returns
         a cell of **THREE** ontology strcutures instead:

         ```matlab
         onts = pfp_ontbuild('go.obo');
         ```

         By default, they are ordered as BPO, CCO, MFO, alphabetically. You can
         also double check the `.ont_type` field of each returning structure.

      2. Load plain-text files

         If you have already parsed an ontology, you can also save its term
         description and structure into the following two files and then load them
         into the same MATLAB structure as if using `pfp_ontbuild`:

         ```matlab
         ont = pfp_loadont('terms.tsv', 'relationship.tsv');
         ```

         where `terms.tsv` is a two column file contains `<term ID>` and `<term
         description>`; `relationship.tsv` is a three column file contains `<term
         ID> <relationship> <term ID>`, (e.g., `GO:XXXXXXX is_a GO:YYYYYYY`). Both
         files are delimited by `TAB` and do not have header lines.

    * Load annotations onto the ontology structure(s)

      Once `ont` is created, you can load a list of sequence annotations using
      terms in this ontology.

      ```matlab
      oa = pfp_oabuild(ont, 'annotation.dat');
      ```

      where `annotation.dat` is a two column tab-delimited file having
      `<sequence ID> <term ID>` annotation pairs in each line.

* ***STEP 2:*** Prepare BLAST results
    * Run `blastp` on the query sequences against the "training" sequences by
      setting output format to be the following:

      ```bash
      blastp ... -outfmt "6 qseqid sseqid evalue length pident nident" -out blastp.out
      ```

    * Load the tabular output file (`blastp.out` as shown above) into MATLAB:

      ```matlab
      B = pfp_importblastp('blastp.out');
      ```

* ***STEP 3:*** Build the *BLAST* predictor

    Run the follow command in MATLAB to get a prediction structure:

    ```matlab
    blast = pfp_blast(qseqid, B, oa);
    ```

    where `qseqid` is a cell list of query sequences on which you need scores.
    Note that it can be just a subset of all those you BLAST'ed. `B` is the
    structure imported step 2, while `oa` is the ontology annotation structure
    loaded in step 1.

    Also, extra options can be specified as additional arguments so as to choose
    which feature you would like to use for creating BLAST predictions. By
    default, it used `sid`: sequence identity. See the documentation in
    `pfp_blast.m` for more details. Thus, `blast` will be the *BLAST* predictor in
    MATLAB for evaluation.

### *Naive* predictor

    To build a *naive* predictor, all you need is the ontology annotation
    structure `oa` that you have as in the step 1 of making a *BLAST* predictor.
    Then run the following in MATLAB:

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

      * Convert the `cm` structure to metrics of interest, here
        "precision-recall" `seq_pr.metric` would have 101 precision-recall pairs
        corresponding to 101 thresholds from `0.00` up to `1.00` with step size
        `0.01`.  You can use it to draw a PR curve.

        ```matlab
        seq_pr = pfp_convcmstruct(cm, 'pr');
        ```

## How to "replicate" CAFA2 evaluation experiment

### Caveat
    Due to CAFA rules, the organizers of CAFA cannot release the submitted
    predictions from participants. Therefore, it is technically not possible to
    replicate exact results (figures and tables) in the CAFA2 paper. Also, this
    repository is not originally designed to be a software that is reusable as a
    whole for protein function prediction tasks in general or even for future
    CAFA challenges. As a result, the pipeline is not fully automatized and
    manual input is necessary occasionally.

    Please also notice that this pipeline is only tested on Linux version of
    MATLAB (2016b), it is not guaranteed to work on other OS (code might have to
    be adapted accordingly). We also used Bioinformatics toolbox for topological
    ordering of ontology terms (`graphtopoorder`) in some Matlab functions.
    However, it should be fairly easy to implement your own version if this
    toolbox is not available.

    With that being said, we provide scripts along with a minialist guideline to
    assist researchers who would like to evaluate their own methods using CAFA2
    benchmarks (along with their annotations by the time stated in the paper) so
    as to compare their performances against CAFA2 baselines and possibly
    against other methods.  

### Step-by-step
1. Download this repository to your local filesystem, say `/path/to/cafa2_repo`,
   hereafter `<cafa2repo>`.

2. Prepare an empty folder that have write permission, say
   `/path/to/another/folder`, hereafter, `<mydir>`, for holding evaluation
    results.

3. In Matlab, change working directory to `<cafa2repo>/matlab` and setup
   `<mydir>`:

    ```matlab
    cd <cafa2repo>/matlab;
    cafa_setup('<cafa2repo>', '<mydir>');
    ```

    This command sets up empty folders inside `<mydir>` where intermediate/final
    results will sit.

4. Place your plain-text prediction file into `<mydir>`.

    Note that prediction files should be using CAFA format: `<target ID> <term
    ID> <score>` for each line but without HEADER (those lines start with
    `MODEL`, `AUTHOR`, `KEYWORDS` etc.) or FOOTER (the `END` line). Filename is
    suppose to be `M001` (`M` followed by three digits) and `M002`, `M003` so on
    so forth if you have more than one methods to be evaluated. Then copy/move
    them into `<mydir>/consolidated`.

5. Filter predictions. This step will filter out predictions on proteins that
   are not in any benchmarks, which could greatly reduce the size of
   intermediate files and processing speed. In Matlab

    ```matlab
    cafa_driver_filter('<mydir>/consolidated', '<mydir>/filtered', '<cafa2repo>/benchmark/lists/xxo_all_typex.txt');
    ```

6. Import plain-text predictions into Matlab structures, so that they can be
   reused for different evaluation tasks (e.g., different metrics, different
   benchmarks, etc.) Let's use MFO as an example:

    ```matlab
    load <cafa2repo>/ontology/MFO.mat;
    cafa_driver_import('<mydir>/filtered', '<mydir>/prediction/mfo', MFO);
    ```

    **Notice that up until now, these steps only need to be executed once. Each
    following particular evaluation tasks is specified using a single plain-text
    job configuration file**

7. Make a job configuration file according to your needs, please use the example
   file: `<cafa2repo>/config/example.job` as a template. Basically, you need to
   change <cafa2repo> and <mydir> accordingly; specify what metric you are
   using, which evaluation mode, etc. And save the modified configuration file
   at `/path/to/config.job>`, hereafter, `<config>`.

8. Pre-evaluation. This step is essential for sequence-centric evaluations so as
   to avoid repeated calculations. It evaluates/stores metrics (e.g.,
   precision/recall) for each protein to `<mydir>/seq-centric`.

   Note that if you have multiple benchark lists on which you want to evaluate,
   it is suggested to create a union of all those lists and to do a
   pre-evaluation on the union just once.

    ```matlab
    cafa_driver_preeval('<config>');
    ```

9. Evaluation. This step performs the actual evaluation, and the runtime depends
   on how many methods/metrics you specified in the configuration. If the number
   of methods exceeds 8, it will start in parallel mode. Note that all results will
   be saved into a subfolder under `<mydir>/evaluation/<subfolder>`, it will be
   named after `<ontology>_<category>_<type>_<mode>`, let's simply call it
   `<eval_res>`.

    ```matlab
    cafa_driver_eval('<config>');
    ```

10. Make a register table file according to your needs, please use the example
    file: `<cafa2repo>/config/register.tab` as a template. You can also look at
    the comments in `<cafa2repo>/matlab/cafa_parse_register.m` for reference. We
    would assume the modified file will be saved somewhere and be refered to as
    `<register>`.

11. Collect results. This step should output figures and tables in `<eval_res>`
    folder.

    ```matlab
    cafa_driver_result('<eval_res>', '<register>', 'BN4S', 'BB4S', 'all');
    ```

    **As a final note, please refer to the comments part in each Maltab function
    for detailed input/output descriptions. They can be accessed by typing `help
    <function name>` in Matlab console.**

# License

    The source code used in this CAFA2 evaluation package is licensed under the
    MIT license.
