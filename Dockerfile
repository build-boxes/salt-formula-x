FROM quay.io/almalinuxorg/almalinux:8
RUN dnf -y install nano
RUN curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo | tee /etc/yum.repos.d/salt.repo
RUN dnf update -y 
RUN dnf -y install salt-master salt-minion
#
RUN dnf install -y epel-release
RUN dnf install -y gnupg2 dirmngr curl
RUN gpg2 --keyserver hkp://keyserver.ubuntu.com --recv-keys \
  409B6B1796C275462A1703113804BB82D39DC0E3 \
  7D2BAF1CF37B13E2069D6956105BD0E739499BDB
#
# Install RVM and Ruby 2.6+
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN usermod -aG rvm root
RUN /bin/bash -lc "source /etc/profile.d/rvm.sh && rvm requirements"
RUN /bin/bash -lc "rvm install 2.6.10 && rvm use 2.6.10 --default"
#
# Install serverspec gem
RUN /bin/bash -lc "gem install --no-document serverspec"
#
RUN dnf clean expire-cache
RUN dnf clean all
RUN systemctl enable salt-master
RUN systemctl enable salt-minion
ENTRYPOINT [ "/sbin/init" ]
#CMD [ "/bin/bash", "-c", "/usr/bin/tail -f /dev/null" ]

#--
FROM quay.io/almalinuxorg/almalinux:8

# Basic tools and SaltStack setup
RUN dnf -y install nano curl gnupg2 gcc make patch bzip2 autoconf automake libtool bison \
    readline-devel zlib-devel libffi-devel openssl-devel \
    epel-release

RUN curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo \
    | tee /etc/yum.repos.d/salt.repo

RUN dnf update -y
RUN dnf -y install salt-master salt-minion

# Install Ruby 2.6.10 from source
WORKDIR /tmp
RUN curl -O https://cache.ruby-lang.org/pub/ruby/2.6/ruby-2.6.10.tar.gz \
    && tar -xzf ruby-2.6.10.tar.gz \
    && cd ruby-2.6.10 \
    && ./configure --disable-install-doc \
    && make -j$(nproc) \
    && make install \
    && cd .. && rm -rf ruby-2.6.10 ruby-2.6.10.tar.gz

# Install serverspec gem
RUN gem install --no-document serverspec

# Cleanup
RUN dnf clean expire-cache && dnf clean all

# Enable Salt services
RUN systemctl enable salt-master
RUN systemctl enable salt-minion

ENTRYPOINT [ "/sbin/init" ]