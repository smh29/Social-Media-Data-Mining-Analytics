               SOCIAL MEDIA DATA MINING AND ANALYTICS
by Gabor Szabo, Gungor Polatkan, Oscar Boykin, and Antonios Chalkiopoulos

=========================================================================

You will find instructions, source files, data examples, and helper
scripts to the book in this repository.


Setting up the work environment
===============================

All sources have been tested under Ubuntu 18.04 LTS, which we recommend
using as well either natively or within a virtual machine.  The examples
in most cases assume that we are in the root folder of the book's
repository.  Exceptions to this are the examples for Chapter 5 in the
src/chapter5/scalding_examples and src/chapter5/approximations folders,
respectively.  Before running examples for this particular chapter,
please change the working directory to one of these folders.

Once the operating system is set up, to install all the required
dependencies initially, please run

  setup/setup.sh

This will install the system binaries, R libraries, and the necessary
Python modules.  Before running the Python examples from the book, it is
necessary to activate the Python virtual environment that was just set
up, by executing

  . venv/bin/activate


Downloading the example datasets
================================

Since the main point of this book is to work with datasets generated
by social media services, we make use of some publicly available data
collections as well.  To obtain these, please run

  data/download_all.sh

Note that the downloads require 50-60 GB of available disk space, mostly
due to the large size of one of the example datasets, the Wikipedia
revision data download.


About the source files
======================

We included the source code showcased in the book in this repository.
To find the appropriate source file discussed in any of the chapters,
please navigate to the src/ folder and then to the appropriate folder
corresponding to the chapter.  The source files are referenced by their
file names in the book, and this is where they will reside.

Due to the more complex project structure of the source examples found
in Chapter 5, the src/chapter5 folder contains further directories for
the Scala projects in the scalding_examples/ and approximations/
folders, respectively.  Please refer to the descriptions in the book,
in the Scala source files, and to the
src/chapter5/approximations/README.md file on how to run these examples.

Multiple times distinct source code listings in the book will be found
in the same source file in this repository, especially in the case of R
scripts.  This will also be obvious from the file name references
printed in the book.  In such cases, we left comments in the R scripts
about which listing/figure the appropriate part of the script is
relevant to.  Due to the nature of these R scripts, it is also not
advisable to run these scripts as one, and we recommend executing
only those logical parts of the scripts that are meant to be run while
following the examples in the book in the R IDE of the reader's choice.

In some cases, there are also source files or script snippets included
here that are not referred to in the book, but were used by us for some
calculations or to generate figures. Looking at these may also be
instructive.

We hope that the examples in this repository will make it
straightforward to follow the explanations in the book and allow for
easier experimentation!
