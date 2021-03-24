FROM fedora:34


EXPOSE 10240


# LFR stuff 
RUN dnf install -y git cppcheck bzip2 hg automake autoconf gcc glibc.i686 zlib.i686 ncurses-compat-libs.i686 cmake gcc-c++ tcl /bin/find

ADD http://www.gaisler.com/anonftp/rcc/bin/linux/sparc-rtems-4.10-gcc-4.4.6-1.2.25-linux.tar.bz2 /opt/
ADD http://www.gaisler.com/anonftp/rcc/src/rtems-4.10-1.2.25-src.tar.bz2 /opt/

RUN cd /opt && tar -xf /opt/sparc-rtems-4.10-gcc-4.4.6-1.2.25-linux.tar.bz2 && \
    cd /opt/rtems-4.10/src && tar -xf /opt/rtems-4.10-1.2.25-src.tar.bz2 && \
     sed -i '0,/grspw_hw_reset(pDev);/s/grspw_hw_reset(pDev);/\/\/grspw_hw_reset(pDev);/' /opt/rtems-4.10/src/rtems-4.10/c/src/lib/libbsp/sparc/shared/spw/grspw.c && \
    make -j bootstrap && \
    make -j bootstrap_sparc && \
    make -j configure-drvmgr && \
    make -j compile-drvmgr && \
    make -j install-drvmgr && \
    rm -f /opt/sparc-rtems-4.10-gcc-4.4.6-1.2.25-linux.tar.bz2 /opt/rtems-4.10-1.2.25-src.tar.bz2

RUN  dnf install -y  nodejs git make wget which python3.5.x86_64 python3.6.x86_64 \
  python3.7.x86_64 python3.8.x86_64 g++ clang gcc-gfortran /usr/bin/gnat /usr/bin/javac \
  gcc-gdc ghc llvm /usr/bin/ocamlopt /usr/bin/fpc /usr/bin/rustc /usr/bin/rustfilt\
  swift-lang \
  && git clone https://github.com/compiler-explorer/compiler-explorer.git /compiler-explorer \
  && cd /compiler-explorer \
  && npm i @sentry/node \
  && make webpack \
  && rm -f /compiler-explorer/etc/config/*.properties

ADD config/* /compiler-explorer/etc/config/

WORKDIR /compiler-explorer

ENTRYPOINT [ "make" ]

CMD ["run"]
