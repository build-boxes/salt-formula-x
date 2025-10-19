FROM quay.io/almalinuxorg/8-minimal

LABEL maintainer="rauf.hammad@gmail.com"
LABEL description="Reusable Salt master base image with Ruby 3.2, serverspec, and custom /srv/salt layout"

# Install core tools and SaltStack
RUN microdnf -y install procps net-tools curl nano httpd openssh-server \
    && microdnf -y install gcc make patch bzip2 autoconf automake libtool bison \
       readline-devel zlib-devel libffi-devel openssl-devel tar \
    && curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo \
       | tee /etc/yum.repos.d/salt.repo \
    && microdnf update -y \
    && microdnf -y install salt-master salt-minion

# Build and install libyaml from source
WORKDIR /tmp
RUN curl -O https://pyyaml.org/download/libyaml/yaml-0.2.5.tar.gz \
    && tar -xzf yaml-0.2.5.tar.gz \
    && cd yaml-0.2.5 \
    && ./configure && make -j$(nproc) && make install \
    && cd .. && rm -rf yaml-0.2.5*

# Build and install Ruby 3.2.2 from source
RUN curl -O https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.2.tar.gz \
    && tar -xzf ruby-3.2.2.tar.gz \
    && cd ruby-3.2.2 \
    && export CPPFLAGS="-I/usr/local/include" \
    && export LDFLAGS="-L/usr/local/lib" \
    && ./configure --disable-install-doc \
    && make -j$(nproc) && make install \
    && cd .. && rm -rf ruby-3.2.2*

# Install serverspec gem
RUN gem install --no-document serverspec

# Configure Salt master to use /srv/salt layout
RUN mkdir -p /srv/salt /srv/salt/pillar /srv/salt/formula \
    && printf '%s\n' \
        'file_roots:' \
        '  base:' \
        '    - /srv/salt' \
        '    - /srv/salt/formula' \
        '' \
        'pillar_roots:' \
        '  base:' \
        '    - /srv/salt/pillar' \
        > /etc/salt/master.d/custom_roots.conf


# Pre-initialize serverspec configuration
RUN mkdir -p /opt/serverspec/init \
    && cd /opt/serverspec/init \
    && echo -e "2\nlocalhost" | serverspec-init \
    && mv spec/spec_helper.rb /opt/serverspec/spec_helper.rb \
    && rm -rf /opt/serverspec/init
# Copy wrapper script into persistent location
COPY run_all_tests.sh /opt/serverspec/run_all_tests.sh
# Make it executable
RUN chmod +x /opt/serverspec/run_all_tests.sh
# Add /opt/serverspec to root's PATH
RUN echo 'export PATH=$PATH:/opt/serverspec' >> /root/.bashrc

# Clean up
RUN microdnf clean all
WORKDIR /root

# Enable services
RUN systemctl enable httpd \
    && systemctl enable sshd \
    && systemctl enable salt-master \
    && systemctl enable salt-minion

# Configure Salt-Minion OS(Almalinux-minimal) Specific Providers
RUN printf '%s\n' \
        'providers:' \
        '  pkg: microdnf' \
        '  service: systemd' \
        >> /etc/salt/minion
# Configure Salt minion to point to local master
RUN echo "master: localhost" > /etc/salt/minion.d/master.conf \
    && echo "local-master" > /etc/salt/minion_id
# Accept Minion Keys automatically    
RUN echo "auto_accept: True" > /etc/salt/master.d/auto_accept.conf
# Copy bootstrap script into persistent location
COPY bootstrap_minion.sh /opt/salt/bootstrap_minion.sh
RUN chmod +x /opt/salt/bootstrap_minion.sh
RUN echo 'export PATH=$PATH:/opt/salt' >> /root/.bashrc

# Allow SSH key login for root
RUN mkdir -p /root/.ssh \
    && chmod 700 /root/.ssh \
    && touch /root/.ssh/authorized_keys \
    && chmod 600 /root/.ssh/authorized_keys \
    && sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PubkeyAuthentication .*/PubkeyAuthentication yes/' /etc/ssh/sshd_config

RUN [ -n "$SSH_PUB_KEY" ] && echo "$SSH_PUB_KEY" >> /root/.ssh/authorized_keys || echo "No SSH key provided"

# Set root password
RUN echo "root:podman!" | chpasswd

# Enable SSH password login
RUN sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Expose ports and volume
VOLUME [ "/srv/salt" ]
EXPOSE 22 80

ENTRYPOINT [ "/sbin/init" ]
#CMD ["/opt/serverspec/run_all_tests.sh"]
