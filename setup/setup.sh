# Install the system, R, and Python packages needed to run the examples.
# The operating system is assumed to be Ubuntu Linux 18.04 LTS (Bionic Beaver).

# System packages.
sudo apt install -y \
    curl libcurl4-openssl-dev libxml2-dev p7zip-full pigz make \
    python python-dev python-tk virtualenv \
    r-base \
    openjdk-8-jdk

# Install the R packages.
#
# This is needed for rPython, see https://cran.r-project.org/web/packages/rPython/INSTALL
export RPYTHON_PYTHON_VERSION=2.7
Rscript -e \
"install.packages(c('plyr', 'ggplot2', 'reshape2', 'scales', 'NMF', "\
"'glmnet', 'ROCR', 'tm', 'ggdendro', 'wordcloud', 'dendextend', 'lda', 'entropy', "\
"'robfilter', 'forecast', 'rPython', 'Matrix'))"

# Python: create a virtualenv for us to work in, and install the required
# modules.
virtualenv venv
. venv/bin/activate
pip install tweepy beautifulsoup4 nltk networkx matplotlib python-igraph \
    numpy scipy

python -c "import nltk; nltk.download('stopwords')"
