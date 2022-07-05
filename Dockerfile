FROM ubuntu:20.04

ARG user
ARG group
ARG uid
ARG gid
ARG DEBIAN_FRONTEND=nointeractive

RUN useradd --uid "${uid}" --shell /bin/bash --create-home "${user}" && \
    adduser "${user}" sudo && passwd -d "${user}"

WORKDIR /tmp

# Packages
RUN apt update && apt upgrade -y && \
    apt install -y wget gcc-10 g++-10 gcc g++ make libunwind-dev lzma-dev curl gnupg \
    git zlib1g-dev vim doxygen clang-format libtbb-dev libcurl4-gnutls-dev libssl-dev sudo

# Encoding
ENV LANG=en_US.UTF-8
RUN apt-get install -y locales && \
    sed -i -e "s/# $LANG.*/$LANG UTF-8/" /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=$LANG

# Bazel
RUN apt install -y apt-transport-https && \
    curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel.gpg && \
    mv bazel.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" \
    | tee /etc/apt/sources.list.d/bazel.list && \
    apt update -y && apt install -y bazel

# CMake
RUN wget https://github.com/Kitware/CMake/releases/download/v3.23.0-rc1/cmake-3.23.0-rc1.tar.gz && \
    tar xvf cmake-3.23.0-rc1.tar.gz --no-same-owner && cd cmake-3.23.0-rc1 && \
    ./configure && make -j $(nproc) && make install

# Boost 1.76
RUN wget https://boostorg.jfrog.io/artifactory/main/release/1.76.0/source/boost_1_76_0.tar.gz && \
    tar xf boost_1_76_0.tar.gz --no-same-owner && cd boost_1_76_0 && \
    ./bootstrap.sh && ./b2 install

# GLog
RUN git clone https://github.com/google/glog.git && \
    cd glog && \
    cmake -S . -B build -G "Unix Makefiles" && \
    cmake --build build && \
    cmake --build build --target install

# Protobuf
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v3.14.0/protobuf-all-3.14.0.tar.gz && \
    tar xvf protobuf-all-3.14.0.tar.gz --no-same-owner && cd protobuf-3.14.0 && \
    ./configure && make -j $(nproc) && make install && ldconfig

# Google benchmark
RUN git clone https://github.com/google/benchmark.git && \
    cd benchmark && \
    cmake -E make_directory "build" && \
    cmake -E chdir "build" cmake -DBENCHMARK_DOWNLOAD_DEPENDENCIES=on -DCMAKE_BUILD_TYPE=Release ../ && \
    cmake --build "build" --config Release && \
    cmake --build "build" --config Release --target install

# Heaptrack
RUN git clone https://github.com/KDE/heaptrack.git &&\
    cd heaptrack && mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && make -j $(nproc) && \
    make install

# Perf
RUN apt-get install -y flex bison libelf-dev libbfd-dev libcap-dev libnuma-dev libperl-dev \
    python3-dev libunwind-dev libz-dev liblzma-dev libzstd-dev libdw-dev && \
    git clone --depth 1 https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git && \
    cd linux/tools/perf && make -j $(nproc) && cp perf /usr/bin

WORKDIR /home

COPY configs/.bashrc /home/${user}/.bashrc

ENV TERM=xterm-256color

USER ${user}

WORKDIR /home/${user}
