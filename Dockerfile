ARG JOBS=4
FROM fedora:36


EXPOSE 10240


# LFR stuff 
RUN dnf install -y --nodocs --setopt install_weak_deps=False git cppcheck bzip2 hg automake autoconf gcc glibc.i686 /lib/ld-linux.so.2 zlib.i686 ncurses-compat-libs.i686 cmake gcc-c++ tcl /bin/find xz \
	&& dnf clean all -y

# uses LPP mirror since it is way faster replace https://hephaistos.lpp.polytechnique.fr/data/mirrors/gaisler/ by http://www.gaisler.com/anonftp/
ADD https://hephaistos.lpp.polytechnique.fr/data/mirrors/gaisler/rcc/bin/linux/sparc-rtems-4.10-gcc-4.4.6-1.2.25-linux.tar.bz2 /opt/
ADD https://hephaistos.lpp.polytechnique.fr/data/mirrors/gaisler/rcc/src/rtems-4.10-1.2.25-src.tar.bz2 /opt/
ADD https://hephaistos.lpp.polytechnique.fr/data/mirrors/gaisler/rcc/bin/linux/sparc-rtems-4.8-gcc-4.2.4-1.1.2-linux.tar.bz2 /opt/
ADD https://hephaistos.lpp.polytechnique.fr/data/mirrors/gaisler/rcc/bin/linux/sparc-rtems-5-gcc-10.2.0-1.3.0-linux.txz /opt/
ADD https://hephaistos.lpp.polytechnique.fr/data/mirrors/gaisler/rcc/bin/linux/sparc-rtems-5-llvm-8.0.0-1.3.0-linux.txz /opt/
ADD https://hephaistos.lpp.polytechnique.fr/data/mirrors/gaisler/bcc2/bin/bcc-2.2.0-llvm-linux64.tar.xz /opt/
ADD https://hephaistos.lpp.polytechnique.fr/data/mirrors/gaisler/bcc2/bin/bcc-2.2.0-gcc-linux64.tar.xz /opt/

ADD https://www.mjr19.org.uk/sw/inode64.so /usr/lib/

RUN g++ -shared -Wl,-soname -o  /usr/lib64/inode64.so && ldconfig -v 

ENV LD_PRELOAD=inode64.so


RUN cd /opt && \
    tar -xf /opt/sparc-rtems-4.10-gcc-4.4.6-1.2.25-linux.tar.bz2 && \
    tar -xf /opt/sparc-rtems-4.8-gcc-4.2.4-1.1.2-linux.tar.bz2 && \
    tar -xf /opt/sparc-rtems-5-gcc-10.2.0-1.3.0-linux.txz && \
    tar -xf /opt/sparc-rtems-5-llvm-8.0.0-1.3.0-linux.txz && \
    tar -xf /opt/bcc-2.2.0-llvm-linux64.tar.xz && \
    tar -xf /opt/bcc-2.2.0-gcc-linux64.tar.xz && \
    ln -s /usr/lib64/libtinfo.so.6 /usr/lib64/libtinfo.so.5 && \
    cp -r /opt/rtems-4.10 /opt/rtems-4.10-unmodified && \
    cd /opt/rtems-4.10/src && tar -xf /opt/rtems-4.10-1.2.25-src.tar.bz2 && \
    sed -i '0,/grspw_hw_reset(pDev);/s/grspw_hw_reset(pDev);/\/\/grspw_hw_reset(pDev);/' /opt/rtems-4.10/src/rtems-4.10/c/src/lib/libbsp/sparc/shared/spw/grspw.c && \
    make -j $JOBS bootstrap && \
    make -j $JOBS bootstrap_sparc && \
    make -j $JOBS configure-drvmgr && \
    make -j $JOBS compile-drvmgr && \
    make -j $JOBS install-drvmgr && \
    rm -f /opt/{*.bz2,*.txz,*.xz} && \
    mv /opt/rtems-4.10 /opt/rtems-4.10-LFR && \
    mv /opt/rtems-4.10-unmodified /opt/rtems-4.10

RUN  dnf install -y --nodocs --setopt install_weak_deps=False nodejs /usr/bin/node /usr/bin/npm git make wget which python3.6.x86_64 nasm \
  python3.7.x86_64 python3.8.x86_64 python3.9.x86_64 python3.11.x86_64 g++ clang gcc-gfortran /usr/bin/gnat /usr/bin/javac \
  gcc-gdc ghc llvm /usr/bin/ocamlopt /usr/bin/fpc /usr/bin/rustc /usr/bin/rustfilt rustfmt /usr/bin/clang-format /usr/bin/gofmt \
  swift-lang arm-none-eabi-gcc-cs arm-none-eabi-gcc-cs-c++ arm-none-eabi-binutils-cs dub \
  binutils-riscv64-linux-gnu gcc-c++-riscv64-linux-gnu gcc-riscv64-linux-gnu arm-none-eabi-newlib \
  ccache fmt-devel.x86_64 range-v3-devel.x86_64 catch-devel.x86_64 google-cpu_features-devel.x86_64 \
  google-benchmark-devel.x86_64 unittest-cpp.x86_64 netcdf-cxx-devel.x86_64 netcdf-cxx4-devel.x86_64 log4cxx-devel.x86_64 kokkos.x86_64 \
  jsoncpp.x86_64 json11.x86_64 gtest.x86_64 cppzmq-devel.x86_64 boost-devel.x86_64 abseil-cpp.x86_64 \
  xeus-devel.x86_64 xsimd-devel.x86_64 xtensor-devel.x86_64 \
  && dnf update -y \
  && ln -s /usr/bin/ccache /usr/lib64/ccache/arm-none-eabi-g++ \
  && dnf clean all -y \
  && cd  && git clone https://github.com/dlang/tools && cd tools \
  && dub build :ddemangle && mv ./rdmd.d /usr/bin/rdmd && mv ./ddemangle.d /usr/bin/ddemangle \
  && cd .. && rm -rf tools
  
RUN useradd -ms /bin/bash compiler-explorer

USER compiler-explorer


RUN git clone https://github.com/compiler-explorer/compiler-explorer.git  /home/compiler-explorer/compiler-explorer \
  && cd  /home/compiler-explorer/compiler-explorer \
  && curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash \
  && source ~/.bashrc && nvm install v17 \
  && make prereqs || make prereqs \
  && rm -f  /home/compiler-explorer/compiler-explorer/etc/config/*.properties 


ADD config/*  /home/compiler-explorer/compiler-explorer/etc/config/

WORKDIR /home/compiler-explorer/compiler-explorer

CMD ["make"]
