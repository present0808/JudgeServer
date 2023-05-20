FROM ubuntu:22.04

COPY build/java_policy /etc

ENV DEBIAN_FRONTEND=noninteractive
ENV BACKEND_URL=http://localhost:8000/api/judge_server_heartbeat/
ENV SERVICE_URL=http://localhost:8080
ENV TOKEN=YOUR_TOKEN_HERE
ENV DISABLE_HEARTBEAT=


COPY requirements.txt .
RUN buildDeps='software-properties-common git libtool make cmake python3-dev python3-pip libseccomp-dev gpg-agent curl' && \
    apt-get update && apt-get install -y python3 python-pkg-resources python3-pkg-resources $buildDeps && \
    add-apt-repository ppa:openjdk-r/ppa && add-apt-repository ppa:longsleep/golang-backports && \
    add-apt-repository ppa:ubuntu-toolchain-r/test && \
    add-apt-repository ppa:ondrej/php && \
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get update && apt-get install -y golang-go openjdk-11-jdk php-cli nodejs gcc-11 g++-11 && \
    update-alternatives --install  /usr/bin/gcc gcc /usr/bin/gcc-11 40 && \
    update-alternatives --install  /usr/bin/g++ g++ /usr/bin/g++-11 40 && \
    pip3 install --no-cache-dir -r requirements.txt && \	
    cd /tmp && git clone -b newnew --depth 1 https://github.com/present0808/Judger && cd Judger && \
    mkdir build && cd build && cmake .. && make && make install && cd ../bindings/Python && python3 setup.py install && \
    apt-get purge -y --auto-remove $buildDeps && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /code && \
    useradd -u 12001 compiler && useradd -u 12002 code && useradd -u 12003 spj && usermod -a -G code spj

# The php directory needs to follow up the version. As of May 18, 2023, the last version of php is 8.2.
RUN phpJitOption='opcache.enable=1\nopcache.enable_cli=1\nopcache.jit=1205\nopcache.jit_buffer_size=64M' && \
    echo $phpJitOption > /etc/php/8.2/cli/conf.d/10-opcache-jit.ini

HEALTHCHECK --interval=5s --retries=3 CMD python3 /code/service.py
ADD server /code
WORKDIR /code
RUN gcc -shared -fPIC -o unbuffer.so unbuffer.c
EXPOSE 8080
ENTRYPOINT /code/entrypoint.sh
