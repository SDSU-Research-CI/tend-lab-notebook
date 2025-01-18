ARG BASE_IMAGE=quay.io/jupyter/r-notebook:2024-07-29
FROM ${BASE_IMAGE}

USER root
WORKDIR /opt

# Install VS Code
RUN curl -fsSL https://code-server.dev/install.sh | sh

# Install Rclone
RUN curl -fsSL  https://rclone.org/install.sh | bash

# Install Jupyter Desktop Dependencies
RUN apt-get -y update \
 && apt-get -y install \
    dbus-x11 \
    xfce4 \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xorg \
    xubuntu-icon-theme \
    tigervnc-standalone-server \
    tigervnc-xorg-extension \
 && apt clean \
 && rm -rf /var/lib/apt/lists/* \
 && fix-permissions "${CONDA_DIR}" \
 && fix-permissions "/home/${NB_USER}"

# Install AFNI dependencies
RUN apt-get -y update \
 && apt-get -y install software-properties-common \
 && add-apt-repository universe

RUN apt-get -y update \
 && apt-get -y install \
    tcsh xfonts-base libssl-dev       \
    python-is-python3                 \
    python3-matplotlib python3-numpy  \
    python3-flask python3-flask-cors  \
    python3-pil                       \
    gsl-bin netpbm gnome-tweaks       \
    libjpeg62 xvfb xterm vim curl     \
    gedit evince eog                  \
    libglu1-mesa-dev libglw1-mesa     \
    libxm4 build-essential            \
    libcurl4-openssl-dev libxml2-dev  \
    libgfortran-11-dev libgomp1       \
    gnome-terminal nautilus           \
    firefox xfonts-100dpi             \
    r-base-dev cmake bc git           \
    libgdal-dev libopenblas-dev       \
    libnode-dev libudunits2-dev \
 && apt clean \
 && rm -rf /var/lib/apt/lists/* \
 && fix-permissions "${CONDA_DIR}" \
 && fix-permissions "/home/${NB_USER}"

RUN ln -s /usr/lib/x86_64-linux-gnu/libgsl.so.27 /usr/lib/x86_64-linux-gnu/libgsl.so.19

# Grant NB_USER passwordless sudo
RUN echo "${NB_USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/added-by-start-script

USER ${NB_USER}
WORKDIR /home/${NB_USER}

# Download AFNI install scripts
RUN curl -O https://raw.githubusercontent.com/afni/afni/master/src/other_builds/OS_notes.linux_ubuntu_22_64_a_admin.txt \
 && curl -O https://raw.githubusercontent.com/afni/afni/master/src/other_builds/OS_notes.linux_ubuntu_22_64_b_user.tcsh \
 && curl -O https://raw.githubusercontent.com/afni/afni/master/src/other_builds/OS_notes.linux_ubuntu_22_64_c_nice.tcsh

# Run install scripts
RUN sudo bash OS_notes.linux_ubuntu_22_64_a_admin.txt 2>&1 | tee o.ubuntu_22_a.txt \
 && tcsh OS_notes.linux_ubuntu_22_64_b_user.tcsh 2>&1 | tee o.ubuntu_22_b.txt \
 && tcsh OS_notes.linux_ubuntu_22_64_c_nice.tcsh 2>&1 | tee o.ubuntu_22_c.txt

# Clean up after AFNI quick install, need everything out of /home/jovyan for persistence
RUN sudo mv ~/abin /opt/abin \
 && sudo mv ~/R /opt/R \
 && sudo mv ~/\@update.afni.binaries /opt/ \
 && rm -rf ~/AFNI_* \
 && rm -rf ~/afni_* \
 && rm -rf ~/CD* \
 && rm -rf ~/suma_* \
 && rm -rf OS_* \
 && rm -rf o.*.txt \
 && rm -rf std_meshes

ENV PATH=/opt/abin:$PATH
ENV R_LIBS=/opt/R

# Create the conda environment from the requirements file
COPY environment.yaml environment.yaml
RUN mamba env update --file environment.yaml --prune\
 && rm environment.yaml

# Install conda kernels to register additional env
RUN mamba install -y \
   nb_conda_kernels

# Add websockify for desktop
RUN mamba install -y -c manics \
   websockify

# Install proxies for desktop and codeserver and matplotlib (for AFNI)
RUN pip install \
   jupyter-remote-desktop-proxy \
   jupyter-codeserver-proxy \
   matplotlib
