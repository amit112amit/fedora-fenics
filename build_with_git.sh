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

################################################################################
# Build PETSc
################################################################################

# Get PETSc
if [[ ! -d "petsc" ]]
then
	git clone -b maint https://gitlab.com/petsc/petsc.git petsc
fi

source /etc/profile.d/modules.sh
module load mpi/openmpi-x86_64

export PETSC_DIR="`pwd`/petsc"
export PETSC_ARCH="arch-linux-c-opt"

cd petsc
./configure --download-ptscotch --download-suitesparse --download-metis \
	--download-mumps --download-hypre --download-parmetis \
	--download-scalapack --with-debugging=0

make PETSC_DIR="$PETSC_DIR" PETSC_ARCH="$PETSC_ARCH" all

# Run PETSc check
export OMPI_ALLOW_RUN_AS_ROOT=1
export OMPI_ALLOW_RUN_AS_ROOT_CONFIRM=1

make PETSC_DIR="$PETSC_DIR" PETSC_ARCH="$PETSC_ARCH" check

# Get PETSc version
PETSC_VERSION_MAJOR=`grep "PETSC_VERSION_MAJOR" make.log | grep -oP "[0-3]+"`
PETSC_VERSION_MINOR=`grep "PETSC_VERSION_MINOR" make.log | grep -oP "[0-3]+"`
PETSC_VERSION="$PETSC_VERSION_MAJOR.$PETSC_VERSION_MINOR"

cd ../

# Make petsc4py
pip3 install petsc4py

################################################################################
# Get SLEPc
################################################################################
if [[ ! -d slepc ]]
then
	git clone https://gitlab.com/slepc/slepc.git
fi

cd slepc
SLEPCTAG=`git tag | grep "v$PETSC_VERSION" | tail -n 1`
git checkout tags/"$SLEPCTAG"

export SLEPC_DIR="`pwd`"
./configure
make
make check

# Make slepc4py
pip3 install slepc4py

cd ../

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
if [[ ! -d dolfin/build ]]
then
	mkdir dolfin/build
fi
if [[ ! -d mshr/build ]]
then
	mkdir mshr/build
fi
cd dolfin/build && cmake .. && make -j4 install && cd ../..
cd mshr/build   && cmake .. && make -j4 install && cd ../..

cd dolfin/python && pip3 install . && cd ../..
cd mshr/python   && pip3 install . && cd ../..

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
