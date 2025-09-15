FROM rocker/geospatial:4.5.1

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/local/bin/whitebox_tools:$PATH"
ENV R_ENVIRON_USER=/etc/R/Renviron.site

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libgdal-dev \
    libgeos-dev \
    libproj-dev \
    libudunits2-dev \
    libv8-dev \
    libglpk-dev \
    libxt-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libopenblas-dev \
    unzip \
    wget \
    curl \
    ca-certificates \
    fonts-dejavu-core && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install WhiteboxTools binary
RUN mkdir -p /usr/local/bin/whitebox_tools && \
    wget https://github.com/jblindsay/whitebox-tools/releases/download/v2.3.0/whitebox_tools_linux_amd64.zip -O /tmp/wbt.zip && \
    unzip /tmp/wbt.zip -d /usr/local/bin/whitebox_tools && \
    chmod +x /usr/local/bin/whitebox_tools/whitebox_tools && \
    ln -s /usr/local/bin/whitebox_tools/whitebox_tools /usr/local/bin/wbt && \
    rm -rf /tmp/*

# Install R packages from CRAN
RUN Rscript -e "install.packages('remotes', repos='https://cloud.r-project.org')" && \
    Rscript -e "install.packages(c(\
      'sf', 'tidyverse', 'arrow', 'sfarrow', 'terra', 'readxl', 'openxlsx',\
      'patchwork', 'usdm', 'maps', 'maxnet', 'ecospat', 'plotROC', 'rasterVis',\
      'SDMtune', 'ENMeval', 'zeallot', 'ggview', 'scales', 'ggthemes', 'ggtext',\
      'raster', 'fasterize', 'gdalUtilities', 'exactextractr', 'whitebox',\
      'landscapemetrics', 'httr', 'ows4R', 'doParallel', 'foreach'\
    ), dependencies = TRUE, repos = 'https://cloud.r-project.org')"

# Install GitHub R package
RUN Rscript -e "remotes::install_github('aavotins/egvtools')"

# Optional WhiteboxTools R wrapper init (pre-cache path)
RUN Rscript -e "whitebox::wbt_init(exe_path = '/usr/local/bin/whitebox_tools/whitebox_tools')"

CMD ["R"]
