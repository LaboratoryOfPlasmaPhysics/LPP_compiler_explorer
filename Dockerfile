ARG JOBS=4
FROM fedora:34


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

RUN  dnf install -y --nodocs --setopt install_weak_deps=False nodejs /usr/bin/node /usr/bin/npm git make wget which python3.5.x86_64 python3.6.x86_64 nasm \
  python3.7.x86_64 python3.8.x86_64 g++ clang gcc-gfortran /usr/bin/gnat /usr/bin/javac \
  gcc-gdc ghc llvm /usr/bin/ocamlopt /usr/bin/fpc /usr/bin/rustc /usr/bin/rustfilt \
  swift-lang arm-none-eabi-gcc-cs arm-none-eabi-gcc-cs-c++ arm-none-eabi-binutils-cs \
  binutils-riscv64-linux-gnu gcc-c++-riscv64-linux-gnu gcc-riscv64-linux-gnu arm-none-eabi-newlib \
  ccache \
  && ln -s /usr/bin/ccache /usr/lib64/ccache/arm-none-eabi-g++ \
  && git clone https://github.com/compiler-explorer/compiler-explorer.git /compiler-explorer \
  && cd /compiler-explorer \
  && npm i @sentry/node \
  && make webpack \
  && rm -f /compiler-explorer/etc/config/*.properties \
  && dnf clean all -y

ADD config/* /compiler-explorer/etc/config/

WORKDIR /compiler-explorer

ENTRYPOINT [ "make" ]

CMD ["run"]
