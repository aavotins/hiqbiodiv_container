mkdir -p /home/vpp-hiqbiodiv-allocation/$USER/build_tmp
mkdir -p /home/vpp-hiqbiodiv-allocation/$USER/appt_cache

export SINGULARITY_TMPDIR=/home/vpp-hiqbiodiv-allocation/$USER/build_tmp
export SINGULARITY_CACHEDIR=/home/vpp-hiqbiodiv-allocation/$USER/appt_cache

export TMPDIR=/home/vpp-hiqbiodiv-allocation/$USER/build_tmp

singularity pull --name hiqbiodiv-container_20260926.sif \
  docker://aavotins/hiqbiodiv-container:latest