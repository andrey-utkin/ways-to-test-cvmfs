FROM quay.io/centos/centos:9

RUN dnf install epel-release -y
RUN dnf config-manager --set-enabled crb -y

RUN dnf install -y \
	acl \
	attr \
	autoconf \
	autofs \
	automake \
	bind-utils \
	bzip2 \
	ccache \
	clang \
	cmake \
	cpio \
	e2fsprogs \
	findutils \
	fuse \
	fuse-common \
	fuse-devel \
	fuse-libs \
	fuse3 \
	fuse3-devel \
	fuse3-libs \
	gcc-c++ \
	gdb \
	git \
	golang \
	gzip \
	httpd \
	inotify-tools \
	iproute \
	jemalloc \
	jemalloc-devel \
	jq \
	libacl-devel \
	libasan \
	libattr-devel \
	libcap-devel \
	libuuid-devel \
	make \
	openssl \
	openssl-devel \
	patch \
	procps-ng \
	psmisc \
	python3 \
	python3-devel \
	python3-mod_wsgi \
	python3-pip \
	python3-pylibacl \
	python3-requests \
	python3-setuptools \
	python3-xattr \
	rr \
	rsync \
	rsyslog \
	sqlite \
	strace \
	sudo \
	systemd \
	unzip \
	vim \
	wget \
	xfsprogs \
	zlib \
	zlib-devel \
	;
RUN pip3 install xattr

# Fix sudo failures:
# Weirdly, this is how it is by default as of 2025-07-19:
# [root@32969d5279d9 /]# ls -l /etc/shadow
# ---------- 1 root root 440 Jul 18 20:16 /etc/shadow
RUN chmod u+r /etc/shadow

RUN wget https://dl.min.io/server/minio/release/linux-amd64/minio.rpm && \
	dnf install -y minio.rpm && \
	wget https://dl.min.io/client/mc/release/linux-amd64/mc && \
	install mc /usr/local/bin/mc

RUN \
	PY_VER=3.9 \
	&& python3 -m site --user-site | grep -F /root/.local/lib/python$PY_VER/site-packages \
	&& mkdir -p /root/.local/lib/python$PY_VER/site-packages \
	&& git clone https://github.com/google/gtest-parallel /root/.local/lib/python$PY_VER/site-packages/gtest-parallel \
	&& mkdir -p /usr/local/bin \
	&& ln -sv /root/.local/lib/python$PY_VER/site-packages/gtest-parallel/gtest-parallel /usr/local/bin/

# Create the sftnight user
RUN useradd -m -s /bin/bash sftnight
RUN echo '%sftnight ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

RUN mkdir -p /etc/udev && echo children_max=1 >> /etc/udev/udev.conf

# We definitely don't need /tmp wiping mid-job
# Mask because "disable" fails.
RUN systemctl mask systemd-tmpfiles-clean.timer

# We don't need container fetching package repo updates mid-job
RUN systemctl disable dnf-makecache.timer
