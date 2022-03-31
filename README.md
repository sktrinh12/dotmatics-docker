# DOTMATICS DOKCERFILE

### Notes: 

- the `Dockerfile.al2` was an initial attempt to use Amazon Linux 2 as the base image. `CMake` required newer version to install openbabel, thus failed. 
- openbabel needs to be downloaded separately in order for cdxml to work in DM. Pick version and adjust the environment variable.
- the actual dotmatics zip file is required. Pick a version and adjust the environment variable. 
- ensure the `sed` commands are properly edited for the particular oracle database instance


