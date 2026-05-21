FROM ubuntu:24.04

RUN apt update

RUN apt install -y \
	acl \
	apache2 \
	attr \
	autoconf \
	autofs \
	automake \
	bc \
	bzip2 \
	ccache \
	clang \
	clang-tools \
	cmake \
	cpio \
	curl \
	delve \
	devscripts \
	dnsutils \
	e2fsprogs \
	equivs \
	findutils \
	fuse3 \
	g++ \
	gawk \
	gdb \
	git \
	golang \
	gzip \
	init \
	inotify-tools \
	iproute2 \
	jq \
	libacl1 \
	libacl1-dev \
	libapache2-mod-wsgi-py3 \
	libasan8 \
	libattr1 \
	libattr1-dev \
	libcap-dev \
	libcap2-bin \
	libcap2-dev \
	libfuse-dev \
	libfuse2t64 \
	libfuse3-dev \
	libgtest-dev \
	libjemalloc-dev \
	libjemalloc2 \
	libsqlite3-dev \
	libssl-dev \
	libuuid1 \
	make \
	net-tools \
	ngrep \
	openssl \
	parallel \
	patch \
	procps \
	psmisc \
	python3 \
	python3-dev \
	python3-pip \
	python3-pylibacl \
	python3-requests \
	python3-setuptools \
	python3-xattr \
	rr \
	rsync \
	rsyslog \
	s3cmd \
	sqlite3 \
	strace \
	sudo \
	unzip \
	uuid-dev \
	valgrind \
	varnish \
	vim \
	wget \
	xfsprogs \
	zlib1g \
	zlib1g-dev \
	;

RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio.deb && \
	dpkg -i minio.deb && \
	wget https://dl.min.io/client/mc/release/linux-amd64/mc && \
	install mc /usr/local/bin/mc

RUN \
	PY_VER=3.12 \
	&& python3 -m site --user-site | grep -F /root/.local/lib/python$PY_VER/site-packages \
	&& mkdir -p /root/.local/lib/python$PY_VER/site-packages \
	&& git clone https://github.com/google/gtest-parallel /root/.local/lib/python$PY_VER/site-packages/gtest-parallel \
	&& mkdir -p /usr/local/bin \
	&& ln -sv /root/.local/lib/python$PY_VER/site-packages/gtest-parallel/gtest-parallel /usr/local/bin/

# igprof-navigator is python 2 and I gave up on it
#RUN \
#	apt install -y \
#	libatomic-ops-dev \
#	libunwind8 \
#	libunwind-dev \
#	;
#RUN \
#	cd /usr/local/src \
#	&& wget https://github.com/igprof/igprof/archive/refs/tags/v5.9.18.tar.gz \
#	&& tar -xaf v5.9.18.tar.gz \
#	&& cd igprof-5.9.18 \
#	&& cmake -D UNWIND_INCLUDE_DIR=/usr/include/x86_64-linux-gnu  . \
#	&& make install \
#	;



# Create the sftnight user
RUN useradd -m -s /bin/bash sftnight
RUN echo '%sftnight ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir -p /etc/udev && echo children_max=1 >> /etc/udev/udev.conf

# We definitely don't need /tmp wiping mid-job
# Mask because "disable" fails.
RUN systemctl mask systemd-tmpfiles-clean.timer

RUN systemctl disable apt-daily.timer
RUN systemctl disable apt-daily-upgrade.timer
