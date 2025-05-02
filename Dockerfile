# FROM oraclelinux:9
# FROM oraclelinux@sha256:db7bef5906849304bf7a94ae73026c12425fa0c3d2a788166117d453198452c2
# FROM oraclelinux@sha256:b9b54175913fa45da8cf7c652ad57873608d5bd87288d9d6f1776c8073c66370
FROM oraclelinux@sha256:e6713cc3bd51b5f4a3edc2497be8aec1884afba8cfaee1f65ea4077535cda9f1

RUN yum update -y \
 && yum install -y \
    bzip2 \
    bzip2-devel \
    cmake \
    file \
    gcc \
    gcc-c++ \
    gcc-gfortran \
    git \
    make \
    patch \
    unzip \
    wget \
    which \
    zlib \
 && yum-config-manager --enable ol9_codeready_builder \
 && yum install -y \
    libstdc++-static \
    zlib-static \
    ninja-build \
 && yum install -y \
    rpmdevtools \
    rpm-build \
    rpm-sign \
 && dnf install -y \
    python3 \
    python3-devel \
    python3-pip \
    python3-numpy \
    python3-setuptools \
    python3-wheel \
 && dnf clean all \
 && pip3 install --upgrade pip \
 && pip3 install pybind11[global]==2.13.6

# RUN python3 -c "import pybind11; print(pybind11.get_cmake_dir())"

# BOOST 1.60
# DyNaMHoWebsocket uses SSC that relies on the following boost libraries: system thread random chrono
# libbz2 is required for Boost compilation
RUN wget http://sourceforge.net/projects/boost/files/boost/1.60.0/boost_1_60_0.tar.gz -O boost_src.tar.gz \
 && mkdir -p boost_src \
 && tar -xzf boost_src.tar.gz --strip 1 -C boost_src \
 && rm -rf boost_src.tar.gz \
 && cd boost_src \
 && ./bootstrap.sh \
 && ./b2 cxxflags=-fPIC --without-mpi --without-python link=static threading=single threading=multi --layout=tagged --prefix=/opt/boost install \
 && cd .. \
 && rm -rf boost_src

# BOOST Geometry extension
RUN git clone https://github.com/boostorg/geometry \
 && cd geometry \
 && git checkout 4aa61e59a72b44fb3c7761066d478479d2dd63a0 \
 && cp -rf include/boost/geometry/extensions /opt/boost/include/boost/geometry/. \
 && cd .. \
 && rm -rf geometry

RUN wget https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.tar.gz -O eigen.tgz \
 && mkdir -p /opt/eigen \
 && tar -xzf eigen.tgz --strip 1 -C /opt/eigen \
 && rm -rf eigen.tgz

# Install eigen3 from previously installed source, (so that mathtoolbox finds Eigen3)
RUN cd /opt \
 && mkdir /opt/eigen3_built \
 && cd /opt/eigen3_built \
 && cmake ../eigen \
 && make install \
 && rm -rf /opt/eigen3_built

RUN wget https://github.com/jbeder/yaml-cpp/archive/refs/tags/0.8.0.tar.gz -O yaml_cpp.tgz \
 && mkdir -p /opt/yaml_cpp \
 && tar -xzf yaml_cpp.tgz --strip 1 -C /opt/yaml_cpp \
 && rm -rf yaml_cpp.tgz

RUN wget https://github.com/google/googletest/archive/release-1.8.1.tar.gz -O googletest.tgz \
 && mkdir -p /opt/googletest \
 && tar -xzf googletest.tgz --strip 1 -C /opt/googletest \
 && rm -rf googletest.tgz

RUN wget https://github.com/zaphoyd/websocketpp/archive/0.7.0.tar.gz -O websocketpp.tgz \
 && mkdir -p /opt/websocketpp \
 && tar -xzf websocketpp.tgz --strip 1 -C /opt/websocketpp \
 && rm -rf websocketpp.tgz

RUN mkdir -p /opt/libf2c \
 && cd /opt/libf2c \
 && wget http://www.netlib.org/f2c/libf2c.zip -O libf2c.zip \
 && unzip libf2c.zip \
 && rm -rf libf2c.zip

RUN wget https://sourceforge.net/projects/geographiclib/files/distrib/GeographicLib-1.30.tar.gz/download -O geographiclib.tgz \
 && mkdir -p /opt/geographiclib \
 && tar -xzf geographiclib.tgz --strip 1 -C /opt/geographiclib \
 && rm -rf geographiclib.tgz

ENV HDF5_INSTALL=/usr/local/hdf5
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.8/hdf5-1.8.12/src/hdf5-1.8.12.tar.gz -O hdf5_source.tar.gz \
 && mkdir -p HDF5_SRC \
 && tar -xf hdf5_source.tar.gz --strip 1 -C HDF5_SRC \
 && mkdir -p HDF5_build \
 && cd HDF5_build \
 && cmake -G"Unix Makefiles" \
         -D CMAKE_BUILD_TYPE:STRING=Release \
         -D CMAKE_INSTALL_PREFIX:PATH=${HDF5_INSTALL} \
         -D BUILD_SHARED_LIBS:BOOL=OFF \
         -D BUILD_TESTING:BOOL=OFF \
         -D HDF5_BUILD_TOOLS:BOOL=OFF \
         -D HDF5_BUILD_EXAMPLES:BOOL=OFF \
         -D HDF5_BUILD_HL_LIB:BOOL=ON \
         -D HDF5_BUILD_CPP_LIB:BOOL=ON \
         -D HDF5_BUILD_FORTRAN:BOOL=OFF \
         -D CMAKE_C_FLAGS="-fPIC" \
         -D CMAKE_CXX_FLAGS="-fPIC" \
         ../HDF5_SRC \
 && make install \
 && cd .. \
 && rm -rf hdf5_source.tar.gz HDF5_SRC HDF5_build

RUN cd /opt \
 && git clone https://github.com/garrison/eigen3-hdf5 \
 && cd eigen3-hdf5 \
 && git checkout 2c782414251e75a2de9b0441c349f5f18fe929a2

# Ipopt
# http://www.coin-or.org/Ipopt/documentation/node10.html
RUN gfortran --version \
 && wget https://github.com/coin-or/Ipopt/archive/refs/tags/releases/3.14.16.tar.gz -O ipopt_src.tgz \
 && wget https://github.com/coin-or-tools/ThirdParty-Blas/archive/refs/tags/releases/1.4.9.tar.gz -O blas_src.tgz \
 && wget https://github.com/coin-or-tools/ThirdParty-Lapack/archive/refs/tags/releases/1.6.3.tar.gz -O lapack_src.tgz \
 && wget https://github.com/coin-or-tools/ThirdParty-Mumps/archive/refs/tags/releases/3.0.8.tar.gz -O mumps_src.tgz \
 && echo "Blas" \
 && mkdir -p blas_src \
 && tar -xf blas_src.tgz --strip 1 -C blas_src \
 && rm -rf blas_src.tgz \
 && cd blas_src \
 && ./get.Blas \
 && ./configure --help \
 && ./configure --with-pic --disable-shared --prefix=/opt/CoinIpopt \
 && make \
 && make test \
 && make install \
 && cd .. \
 && rm -rf blas_src \
 && echo "Lapack" \
 && mkdir -p lapack_src \
 && tar -xf lapack_src.tgz --strip 1 -C lapack_src \
 && rm -rf lapack_src.tgz \
 && cd lapack_src \
 && ./get.Lapack \
 && ./configure --with-pic --disable-shared --prefix=/opt/CoinIpopt \
 && make \
 && make test \
 && make install \
 && cd .. \
 && rm -rf lapack_src \
 && cp /opt/CoinIpopt/lib/pkgconfig/coinblas.pc /opt/CoinIpopt/lib/pkgconfig/blas.pc \
 && cp /opt/CoinIpopt/lib/pkgconfig/coinlapack.pc /opt/CoinIpopt/lib/pkgconfig/lapack.pc \
 && echo "Mumps" \
 && mkdir -p mumps_src \
 && tar -xf mumps_src.tgz --strip 1 -C mumps_src \
 && rm -rf mumps_src.tgz \
 && cd mumps_src \
 && ./get.Mumps \
 && ./configure --with-pic --disable-shared --prefix=/opt/CoinIpopt \
 && make \
 && make test \
 && make install \
 && cd .. \
 && rm -rf mumps_src \
 && echo "Ipopt" \
 && mkdir -p ipopt_src \
 && tar -xf ipopt_src.tgz --strip 1 -C ipopt_src \
 && rm -rf ipopt_src.tgz \
 && cd ipopt_src \
 && ./configure --with-pic --disable-shared --prefix=/opt/CoinIpopt \
 && make \
 && make test \
 && make install \
 && cd .. \
 && rm -rf ipopt_src

# ARG GIT_GRPC_TAG=v1.30.2
# ARG GIT_GRPC_TAG=v1.42.0
ARG GIT_GRPC_TAG=v1.50.1
RUN git clone --recurse-submodules -b ${GIT_GRPC_TAG} https://github.com/grpc/grpc grpc_src \
 && cd grpc_src \
 && mkdir -p cmake/build \
 && cd cmake/build \
 && cmake \
    -D gRPC_INSTALL:BOOL=ON \
    -D CMAKE_INSTALL_PREFIX=/opt/grpc \
    -D CMAKE_BUILD_TYPE=Release \
    -D gRPC_BUILD_TESTS:BOOL=OFF \
    -D BUILD_SHARED_LIBS:BOOL=OFF \
    -D CMAKE_POSITION_INDEPENDENT_CODE:BOOL=ON \
    -D CMAKE_C_FLAGS="-fPIC" \
    -D CMAKE_CXX_FLAGS="-fPIC" \
    -D CMAKE_VERBOSE_MAKEFILE:BOOL=OFF \
    ../.. \
 && make install \
 && cd ../../.. \
 && rm -rf grpc_src \
 && cp /opt/grpc/lib64/*.a /opt/grpc/lib/.

ENV MATHTOOLBOX_INSTALL=/usr/local/mathtoolbox
RUN git clone --recursive https://github.com/yuki-koyama/mathtoolbox \
 && cd mathtoolbox \
 && git checkout edc26c9680750e022fd41cdee5ae942784a5aff4 \
 && cd ..  && mkdir -p mathtoolbox_build \
 && cd mathtoolbox_build \
 && cmake -G "Unix Makefiles" \
        -D CMAKE_BUILD_TYPE:STRING=Release \
        -D CMAKE_INSTALL_PREFIX:PATH=${MATHTOOLBOX_INSTALL} \
        -D BUILD_SHARED_LIBS:BOOL=OFF \
        -D BUILD_TESTING:BOOL=OFF \
        -D CMAKE_C_FLAGS="-fPIC" \
        -D CMAKE_CXX_FLAGS="-fPIC" \
        ../mathtoolbox \
 && make install \
 && cd ..  \
 && rm -rf mathtoolbox mathtoolbox_build

RUN wget https://www.vtk.org/files/release/9.4/VTK-9.4.2.tar.gz -O /vtk_9_4_2.tar.gz
