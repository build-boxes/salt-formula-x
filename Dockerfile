FROM quay.io/almalinuxorg/almalinux:8
RUN dnf -y install nano
RUN curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo | tee /etc/yum.repos.d/salt.repo
RUN dnf update -y 
RUN dnf -y install salt-master salt-minion
#
# Install GPG (if not already installed)
RUN dnf install -y gnupg2
# Import RVM GPG keys
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
