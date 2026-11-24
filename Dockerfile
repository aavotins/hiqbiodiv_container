
# syntax=docker/dockerfile:1
# HiQBioDiv: amd64 R / geospatial / SDM / prioritisation environment
FROM rocker/geospatial:4.6.1

LABEL org.opencontainers.image.title="HiQBioDiv Container" \
      org.opencontainers.image.source="https://github.com/aavotins/hiqbiodiv_container" \
      org.opencontainers.image.description="Reproducible geospatial, SDM and conservation prioritisation environment"

# WhiteboxTools will be installed inside the image, not a user's home directory.
ENV DEBIAN_FRONTEND=noninteractive \
    CRAN=https://p3m.dev/cran/__linux__/noble/latest \
    R_WHITEBOX_EXE_PATH=/opt/whitebox/WBT/whitebox_tools

# Required Linux libraries, utilities, and certificates.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      libcurl4-openssl-dev libssl-dev libxml2-dev libgit2-dev \
      libgdal-dev libgeos-dev libproj-dev libudunits2-dev \
      libv8-dev libglpk-dev libxt-dev libharfbuzz-dev libfribidi-dev \
      libfontconfig1-dev libfreetype6-dev libpng-dev libtiff-dev \
      libjpeg-dev libopenblas-dev libabsl-dev libicu-dev libsqlite3-dev \
      libexpat1 libkeyutils1 libglib2.0-0 libgl1 \
      libsecret-1-0 libsecret-1-dev \
      unzip curl wget ca-certificates fonts-dejavu-core; \
    rm -rf /var/lib/apt/lists/*

# Install CRAN packages from Rocker's configured binary repository.
# --error fails the build on installation errors.
RUN Rscript -e "cat('CRAN repository:', getOption('repos')[['CRAN']], '\n')" && \
    install2.r --error --skipinstalled --deps NA --repos getOption \
      remotes sf terra raster fasterize exactextractr \
      whitebox landscapemetrics arrow sfarrow readxl openxlsx \
      patchwork usdm maps maxnet ecospat plotROC rasterVis \
      SDMtune ENMeval zeallot ggview scales ggthemes ggtext \
      httr ows4R doParallel foreach \
      tidyverse blockCV overlapping fastfocal \
    && rm -rf /tmp/downloaded_packages

# Test keyring's native library dependency, used indirectly by ows4R.
RUN Rscript -e "\
  library(keyring); \
  library(ows4R); \
  cat('keyring version:', as.character(packageVersion('keyring')), '\n'); \
  cat('ows4R version:', as.character(packageVersion('ows4R')), '\n'); \
  cat('keyring and ows4R: PASSED\n')"

# Install GitHub packages using a BuildKit secret supplied by GitHub Actions.
# The GITHUB_PAT value is available only to these RUN commands; it is not
# persisted as an ENV variable or included in the final image.
RUN --mount=type=secret,id=github_token,required=true \
    GITHUB_PAT="$(cat /run/secrets/github_token)" \
    Rscript -e "\
      remotes::install_github('8Ginette8/gbif.range', \
        dependencies = NA, upgrade = 'never', build_vignettes = FALSE); \
      stopifnot(requireNamespace('gbif.range', quietly = TRUE))"

RUN --mount=type=secret,id=github_token,required=true \
    GITHUB_PAT="$(cat /run/secrets/github_token)" \
    Rscript -e "\
      remotes::install_github('aavotins/egvtools@v0.1.0', \
        dependencies = TRUE, upgrade = 'never', build_vignettes = FALSE); \
      stopifnot(requireNamespace('egvtools', quietly = TRUE))"

RUN --mount=type=secret,id=github_token,required=true \
    GITHUB_PAT="$(cat /run/secrets/github_token)" \
    Rscript -e "\
      remotes::install_github('aavotins/sdmhelpers@v0.1.0', \
        dependencies = TRUE, upgrade = 'never', build_vignettes = FALSE); \
      stopifnot(requireNamespace('sdmhelpers', quietly = TRUE))"

# Install glmmTMB after the other R packages, then verify its namespace.
RUN install2.r --error --deps NA --repos getOption glmmTMB && \
    Rscript -e "library(glmmTMB); print(packageVersion('glmmTMB'))"

# Install the WhiteboxTools executable in a fixed, container-owned directory.
RUN mkdir -p /opt/whitebox && \
    Rscript -e "\
      whitebox::install_whitebox( \
        pkg_dir = '/opt/whitebox', platform = 'linux_amd64', force = TRUE); \
      p <- Sys.getenv('R_WHITEBOX_EXE_PATH'); \
      stopifnot(file.exists(p), file.access(p, 1L) == 0L); \
      stopifnot(isTRUE(whitebox::wbt_init(exe_path = p))); \
      v <- whitebox::wbt_version(); \
      stopifnot(length(v) > 0L); \
      print(v)" && \
    chmod -R a+rX /opt/whitebox

# Make WhiteboxTools discoverable on PATH even if Singularity does not pass
# R_WHITEBOX_EXE_PATH through to the container. No access to HOME is required.
# The wrapper keeps the binary and its associated resources in /opt/whitebox.
RUN printf '%s\n' \
      '#!/bin/sh' \
      'exec /opt/whitebox/WBT/whitebox_tools "$@"' \
      > /usr/local/bin/whitebox_tools && \
    chmod 755 /usr/local/bin/whitebox_tools && \
    test -x /opt/whitebox/WBT/whitebox_tools && \
    command -v whitebox_tools

# Verify the PATH-based fallback WITHOUT R_WHITEBOX_EXE_PATH.
# unname() avoids a false failure when wbt_exe_path() returns a named string.
RUN env -u R_WHITEBOX_EXE_PATH \
    Rscript --vanilla -e "\
      library(whitebox); \
      p <- unname(as.character(wbt_exe_path(shell_quote = FALSE))); \
      cat('WhiteboxTools executable:', p, '\n'); \
      stopifnot( \
        length(p) == 1L, \
        nzchar(p), \
        p == '/usr/local/bin/whitebox_tools', \
        file.exists(p), \
        file.access(p, 1L) == 0L \
      ); \
      v <- wbt_version(); \
      stopifnot(length(v) > 0L, any(grepl('WhiteboxTools', v))); \
      print(v); \
      cat('Container WhiteboxTools: PASS\n')"

# Extract Zonation 5 AppImage so Singularity can run it without FUSE.
ARG ZONATION_VERSION=2.4
RUN set -eux; \
    wget -q --tries=3 --timeout=60 \
      "https://github.com/zonationteam/Zonation5/releases/download/v${ZONATION_VERSION}/Zonation5_Linux.zip" \
      -O /tmp/Zonation5_Linux.zip; \
    unzip -tq /tmp/Zonation5_Linux.zip; \
    cd /tmp; \
    unzip -q Zonation5_Linux.zip; \
    chmod +x zonation5; \
    ./zonation5 --appimage-extract >/dev/null; \
    test -x squashfs-root/AppRun; \
    test -x squashfs-root/usr/bin/z5; \
    mv squashfs-root /opt/zonation5; \
    chmod -R a+rX /opt/zonation5; \
    printf '%s\n' '#!/bin/sh' 'exec /opt/zonation5/AppRun "$@"' > /usr/local/bin/zonation5; \
    chmod 755 /usr/local/bin/zonation5; \
    ln -s /usr/local/bin/zonation5 /usr/local/bin/z5; \
    command -v zonation5; \
    command -v z5; \
    rm -f /tmp/zonation5 /tmp/Zonation5_Linux.zip

# Verify explicitly requested R packages plus key supporting packages.
RUN Rscript -e "\
  required <- c( \
    'remotes','sf','terra','raster','fasterize','exactextractr', \
    'whitebox','landscapemetrics','arrow','sfarrow','readxl','openxlsx', \
    'patchwork','usdm','maps','maxnet','ecospat','plotROC','rasterVis', \
    'SDMtune','ENMeval','zeallot','ggview','scales','ggthemes','ggtext', \
    'httr','ows4R','doParallel','foreach','tidyverse','blockCV', \
    'overlapping','fastfocal','gbif.range','egvtools','sdmhelpers', \
    'glmmTMB','TMB','Matrix','RTMB','lme4','nloptr','pbkrtest', \
    'future','furrr'); \
  suggested <- c('covr','knitr','pkgdown','rmarkdown','testthat', \
                 'hms','viridis','ggplot2'); \
  all_pkgs <- unique(c(required, suggested)); \
  available <- vapply(all_pkgs, requireNamespace, logical(1), quietly = TRUE); \
  if (any(!available)) stop('Missing/unloadable R packages: ', \
    paste(names(available)[!available], collapse = ', ')); \
  stopifnot(as.character(getRversion()) == '4.6.1', \
    as.character(packageVersion('egvtools')) == '0.1.0', \
    as.character(packageVersion('sdmhelpers')) == '0.1.0'); \
  cat('Verified', length(all_pkgs), 'R packages\n'); \
  for (pkg in all_pkgs) cat(pkg, as.character(packageVersion(pkg)), '\n')"

# Functional glmmTMB smoke test, including its compiled TMB interface.
RUN Rscript -e "\
  options(warn = 2); \
  library(glmmTMB); \
  fit <- glmmTMB(count ~ mined, data = Salamanders, family = poisson()); \
  stopifnot(is.finite(as.numeric(logLik(fit)))); \
  cat('glmmTMB smoke test: PASSED\n')"

# Record installed versions and GitHub package commit identifiers in the image.
RUN mkdir -p /opt/hiqbiodiv && \
    Rscript -e "\
      ip <- installed.packages(); \
      write.csv(ip[, c('Package','Version','LibPath','Built'), drop = FALSE], \
        '/opt/hiqbiodiv/r-packages.csv', row.names = FALSE); \
      writeLines(capture.output(sessionInfo()), '/opt/hiqbiodiv/sessionInfo.txt'); \
      pkgs <- c('egvtools','sdmhelpers','gbif.range'); \
      d <- do.call(rbind, lapply(pkgs, function(pkg) { \
        x <- packageDescription(pkg); \
        data.frame(package = pkg, version = x[['Version']], \
          remote_ref = if (is.null(x[['RemoteRef']])) NA_character_ else x[['RemoteRef']], \
          remote_sha = if (is.null(x[['RemoteSha']])) NA_character_ else x[['RemoteSha']]) \
      })); \
      write.csv(d, '/opt/hiqbiodiv/github-packages.csv', row.names = FALSE)" && \
    printf 'Zonation 5 v%s\n' "$ZONATION_VERSION" > /opt/hiqbiodiv/zonation-version.txt

# Remove build-time temporary files after all installations have completed.
RUN rm -rf /tmp/* /var/tmp/* /root/.cache

CMD ["R"]
