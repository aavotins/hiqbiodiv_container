# HiQBioDiv Container: Portable R Geospatial & Biodiversity Modelling Environment

[Reproducible container](https://hub.docker.com/r/aavotins/hiqbiodiv-container) 
for running EGV and SDM workflows used in project HiQBioDiv.

**The container is built from:**

Base image: `rocker/geospatial`

Docker repository: https://hub.docker.com/r/aavotins/hiqbiodiv-container

Source Dockerfile: https://github.com/aavotins/hiqbiodiv_container

It contains a **fully configured R geospatial ecosystem** including (non-exhaustive):

- `terra`, `sf`, `sfarrow`, `exactextractr`

- `whitebox` (`WhiteboxTools` pre-installed and initialised)

- `SDMtune`, `ENMeval`, `blockCV`

- `glmmTMB`

- `landscapemetrics`

- `future`, `furrr`, `doParallel`

**Custom R packages used in HiQBioDiv workflows:**

- `egvtools`

- `sdmhelpers`

Spatial prioritization software **Zonation5 (v2.4)**

Purpose

This container was developed within the HiQBioDiv project to ensure:

- Full reproducibility of species distribution modelling (SDM)

- Scalable multi-resolution environmental variable (EGV) extraction

- HPC-compatible geospatial workflows

- Transparent, versioned computational environments

- Long-term archival of modelling infrastructure

- The Singularity image enables execution on:

- HPC clusters (Singularity/Apptainer)

- Linux servers

- Institutional compute infrastructure without Docker

**Intended Use:**

The container supports workflows including:

- Multi-scale environmental variable extraction

- High-resolution raster processing (1 ha and finer)

- Species distribution modelling (MaxEnt, GLMM, GAM, etc.)

- Extended target-group aprouacg in species distribution modelling

- Spatial cross-validation

- Selection of desired proportion of both presence background/absence locations within previously user-defined folds

- Conservation prioritisation

- Reproducible R-based geospatial analysis pipelines

- Reproducibility

