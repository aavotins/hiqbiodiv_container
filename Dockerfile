# Base image: includes geospatial R ecosystem
FROM rocker/geospatial:4.5.1

# Set environment
ENV DEBIAN_FRONTEND=noninteractive
ENV RENV_VERSION=1.0.0

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
    libabsl-dev \
    unzip \
    curl \
    wget \
    ca-certificates \
    fonts-dejavu-core && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install CRAN packages
RUN Rscript -e "install.packages(c( \
  'remotes', 'sf', 'terra', 'raster', 'fasterize', 'exactextractr', \
  'whitebox', 'landscapemetrics', 'arrow', 'sfarrow', 'readxl', 'openxlsx', \
  'patchwork', 'usdm', 'maps', 'maxnet', 'ecospat', 'plotROC', 'rasterVis', \
  'SDMtune', 'ENMeval', 'zeallot', 'ggview', 'scales', 'ggthemes', 'ggtext', \
  'httr', 'ows4R', 'doParallel', 'foreach' \
  'blockCV', 'overlapping' \
), repos = 'https://cloud.r-project.org', dependencies = TRUE)"

# Install whitebox tools binary inside the image
RUN Rscript -e "whitebox::install_whitebox(platform = 'linux_amd64', force = TRUE)"

# Test and cache Whitebox path
RUN Rscript -e "whitebox::wbt_init()"

# Install GitHub package: egvtools 2025-10-19
RUN Rscript -e "remotes::install_github('aavotins/egvtools')"
RUN Rscript -e "remotes::install_github('8Ginette8/gbif.range')"

# Clean up (optional)
RUN rm -rf /tmp/* /var/tmp/* /root/.cache

# Set default run behavior
CMD ["R"]
