This document describes the preprocessing steps for CAFA2 submissions
---------------------------------------------------------------------

1. Preparation
--------------
   The raw submissions are assumed to be organized in the following hierarchy:
   (a) each team has a folder seperated from others;
   (b) within the folder for each term, it is allowed to have up to 3 subfolders, and each of them corresponding to a model;
   (c) raw predictions must be plain text files (manually unzipped if necessary)
   (d) names of the folders and files don't matter, however name of the team folder and model folder will be used as part of the external ID, i.e. external ID: <team dir>#<model dir>;

       e.g.
       team folder: 101
       model folder: 2
       => external ID for the model: 101#2

   An example of raw submission folder
   - raw_submission/
     + team_1/
     - team_2/
       - model_1/
         file_1.txt
         file_2.dat
       ...
       + model_2/
     + team_3/
     ...

   NOTE
   ----
   Files must be (manually) unzipped and organized in the above hierarchy in order to be preprocessed in the next step.

   It is suggested to name each team folder as its team ID (on the website) and model names as 1, 2, 3.

2. Preprocess
-------------
   Run the Perl script (consolidate.pl) on the properly grouped submission folder.

   NOTE
   ----
   Before running the [normal] consolidating mode, run in the [check] mode with -c first to check submission headers. See consolidate.pl

   [INPUT]
   (a) a raw submission folder (organized as above)

   [OUTPUT]
   (a) a list of raw prediction files (one per model), each file will be named as its "internal ID"

       e.g.
       - preprocessed/
         s1
         s2
         s3
         ...

   (b) ID table, which matches the "external ID" to the "internal ID" for each model

   REMARKS
   -------
   (a) It checks the format of the header information. All files within the same model folder must have the same header lines:

       AUTHOR
       MODEL
       KEYWORDS
       ACCURACY (optional)

       Otherwise, an error will be generated for the model which will not be processed.

   (b) It checks the format of the prediction lines:
       
       (Regular expression)
       ^T[0-9]+\s+(GO|HP):[0-9]{7}\s+[01]\.[0-9]{2}$

       Lines that are filtered out will be put into a log file for manual check.

   (c) It stitches prediction lines from the same model into a single plain text file.

   (d) The final output would still follow the CAFA format.

3. Other stuff (optional)
-------------------------
   (a) Do linear mapping if necessary. It linearly maps score outside (0, 1] to this range.
   (b) Do rounding if necessary. It "rounds" the raw prediction scores to keep 2 digits after the decimal point.
