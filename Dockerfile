# Use the biobakery base image
FROM quay.io/biocontainers/humann2:0.11.1--py27_1

# install dependencies first
RUN apt-get update  && apt-get install -y \
    build-essential \
    gcc-multilib \
    zlib1g-dev \
    curl \
    wget \
    cmake \
    python \
    python-pip \
    python-dev \
    python2.7-dev \
    python-numpy \
    python-matplotlib \
    hdf5-tools \
    libhdf5-dev \
    hdf5-helpers \
    libhdf5-serial-dev \
    libssh2-1-dev \
    libcurl4-openssl-dev \
    icu-devtools \
    libssl-dev \
    libxml2-dev \
    r-bioc-biobase \
    git \
    apt-utils \
    pigz

# Install some prerequisites
RUN pip install boto3==1.4.7 awscli==1.11.146 argparse

# Install the SRA toolkit
RUN cd /usr/local/bin && \
	wget ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sdk/2.8.2/sratoolkit.2.8.2-ubuntu64.tar.gz && \
	gunzip sratoolkit.2.8.2-ubuntu64.tar.gz && \
	tar xvf sratoolkit.2.8.2-ubuntu64.tar && \
	ln -s /usr/local/bin/sratoolkit.2.8.2-ubuntu64/bin/* /usr/local/bin/ && \
	rm sratoolkit.2.8.2-ubuntu64.tar

# Test the installation
RUN humann2_test --run-functional-tests-tools

# Use /share as the working directory
RUN mkdir /share
WORKDIR /share

# Set the default langage to C
ENV LC_ALL C

# Add the run script to the PATH
ADD run.py /usr/local/bin/

# Install Tini - A tiny but valid init for containers
RUN TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` && \
    curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb && \
    dpkg -i tini.deb && \
    rm tini.deb

# Cleanup
RUN apt-get clean && \
    apt-get purge && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Create user docker with password docker
RUN groupadd fuse && \
    useradd --create-home --shell /bin/bash --user-group --uid 1000 --groups sudo,fuse docker && \
    echo `echo "docker\ndocker\n" | passwd docker` && \
    mkdir /data /config ${REF_DIR} && \
    chown docker:docker /data /config ${REF_DIR} && \
    chmod -R 755 /data /config ${REF_DIR}

# Change user (CLI: su - docker)
USER docker

# Update environment variables
ENV PATH=$PATH:/home/docker/bin
ENV HOME=/home/docker
WORKDIR /home/docker

CMD ["/bin/bash"]
