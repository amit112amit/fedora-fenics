# Install fenicproject.org's `dolfin` and `mshr` from source on Fedora 32

## Aim:
To build `dolfin` and `mshr` on Fedora 32 with as many optional dependencies as possible.

1. HDF5 (with MPI support)
2. MPI
3. ParMETIS
4. PETSc
5. SCOTCH and PT-SCOTCH
6. SLEPc
7. Suitesparse
8. ~~Trilinos~~ We will not include Trilinos
9. petsc4py
10. slepc4py


## Description:

The main challenge is to install PETSc from source. We cannot use the PETSc available from Fedora 32 repository because, SLEPc is not available in Fedora repositories and building SLEPc against the PETSc from the repositories requires a lot of patchwork. It is much easier to build SLEPc against a manually installed PETSc. PETSc installer can also install a bunch of other libraries for us -- HYPRE, METIS, MUMPS, PARMETIS, PTSCOTCH, SCALAPACK and SUITESPARSE. We will make an optimized build without debugging symbols.

There are two script files provided:

1. `build_from_git.sh`: We will clone the `git` repositories and checkout the latest released tags for `PETSc` and `SLEPc`. Then we will use `./configure`, `make` and `make check` to build and install `PETSc` and `SLEPc`. We will use `pip3` to install `petsc4py` and `slepc4py` against the built versions of `PETSc` and `SLEPc`.
2. `build_from_pip.sh`: `PETSc` and `SLEPc` are also available through PyPi. In fact, the build system for these packages are written in Python. So we will use `pip3` to install both `PETSc` and `SLEPc`. Rest of the steps are same as in the other script. When `pip` installs `petsc` it takes a long time (~30 minutes on my laptop) without significant progress markers. So please be patient.

## How to use these scripts?

I recommend using a `fedora-toolbox` container where we can freely mess up our root filesystem without risking our operating system.

```bash
sudo dnf install toolbox
toolbox create -c dolfin # Use whatever name you like instead of dolfin
toolbox enter -c dolfin

git clone https://github.com/amit112amit/fedora-fenics.git

cd fedora-fenics
chmod +x *.sh
sudo ./build_with_git.sh # Or ./build_with_pip.sh

# Finally change the ownerhship of the files in dolfin and mshr folder
sudo chown -R "$UID:${GROUPS[0]}" dolfin mshr
```

To use dolfin we will have to exit by `exit` and then re-enter the container by `toolbox enter -c dolfin`.
