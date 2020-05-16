#!/bin/bash

# Building dolfin on Fedora 32 with as many optional features as possible

################################################################################
# Packages from Fedora repo
################################################################################

FEDPACK=( boost-devel boost-filesystem boost-iostreams boost-timer \
	boost-program-options cmake cmake eigen3-devel \
	pkgconf-pkg-config python3-devel python3-six python3-numpy \
	python3-matplotlib pybind11-devel openmpi-devel \
	python3-mpi4py-openmpi hdf5-openmpi-devel zlib gcc gcc-c++ \
	gcc-gfortran openblas-devel make valgrind-devel gdb bison \
	flex mpfr-devel gmp-devel )

# Install all the Fedora packages
dnf install -y "${FEDPACK[@]}"

# Enable MPI
source /etc/profile.d/modules.sh
module load mpi/openmpi-x86_64

################################################################################
# Build PETSc with pip
################################################################################

EXT_PACKAGES=( hypre metis mumps parmetis ptscotch scalapack suitesparse )
for PACKAGE in "${EXT_PACKAGES[@]}"
do
	PETSC_CONFIGURE_OPTIONS="${PETSC_CONFIGURE_OPTIONS} --download-$PACKAGE"
done

export PETSC_ARCH="arch-linux-c-opt"
export PETSC_CONFIGURE_OPTIONS="${PETSC_CONFIGURE_OPTIONS} --with-debugging=0"

pip3 install petsc

PETSC_DIR=`find /usr -path "*petsc/include"`
PETSC_DIR="${PETSC_DIR%/include}"
export PETSC_DIR="$PETSC_DIR"

pip3 install petsc4py

################################################################################
# Get SLEPc
################################################################################

pip3 install slepc

SLEPC_DIR=`find /usr -path "*slepc/include"`
SLEPC_DIR="${SLEPC_DIR%/include}"
export SLEPC_DIR="$SLEPC_DIR"

pip3 install slepc4py

################################################################################
# Make Fenics components
################################################################################

pip3 install fenics-ffc

# Get dolfin and mshr from git ensuring version compatibility with FFC.
FFCVERSION=`python3 -c "import ffc; print(ffc.__version__)"`

if [[ ! -d dolfin ]]
then
	git clone --branch=$FFCVERSION https://bitbucket.org/fenics-project/dolfin
fi

if [[ ! -d mshr ]]
then
	git clone --branch=release https://bitbucket.org/fenics-project/mshr
fi

if [[ ! -d "ply" ]]
then
	git clone https://github.com/dabeaz/ply.git
fi

# Make and install dolfin and mshr
mkdir dolfin/build
cd dolfin/build && cmake .. && make -j4 install && cd ../..

mkdir mshr/build
cd mshr/build   && cmake .. && make -j4 install && cd ../..

cd dolfin/python && pip3 install . && cd ../..
cd mshr/python   && pip3 install . && cd ../..

# Set environment variables for mpi4py, dolfin and mshr
echo "" >> /etc/bashrc
echo "##### MPI4PY ENVIRONMENT VARIABLES #####" >> /etc/bashrc
echo "source /etc/profile.d/modules.sh" >> /etc/bashrc
echo "module load mpi/openmpi-x86_64" >> /etc/bashrc

echo "" >> /etc/bashrc
echo "##### DOLFIN ENVIRONMENT VARIABLES #####" >> /etc/bashrc
cat /usr/local/share/dolfin/dolfin.conf >> /etc/bashrc

echo "" >> /etc/bashrc
echo "##### MSHR ENVIRONMENT VARIABLES #####" >> /etc/bashrc
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib:" >> /etc/bashrc
