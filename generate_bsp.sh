#!/bin/sh

echo "welcome!"

if [ -z "${SOPC_KIT_NIOS2}" ]; then
    echo "Please run the NIOS II Command Shell first!" && sleep 5 && exit 1
fi

QUARTUS_PROJECT_DIR=`realpath $(dirname "$0")`
SOFTWARE_BASE_DIR="${QUARTUS_PROJECT_DIR}/software"

SOFTWARE_PROJECT_NAME="SampleProject"

#test if bsp has been generated
if [ ! -d "${SOFTWARE_BASE_DIR}/${SOFTWARE_PROJECT_NAME}_bsp" ]; then
    # Somehow nios2-bsp doesnt work unless the bsp-dir is "."
    mkdir "${SOFTWARE_BASE_DIR}/${SOFTWARE_PROJECT_NAME}_bsp" && cd "${SOFTWARE_BASE_DIR}/${SOFTWARE_PROJECT_NAME}_bsp" && "${SOPC_KIT_NIOS2}/sdk2/bin/nios2-bsp" hal . "${QUARTUS_PROJECT_DIR}/nios2_subsystem.sopcinfo" --cpu-name nios2_gen2 && make && cd $OLDPWD
fi
