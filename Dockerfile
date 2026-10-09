# ------ COMPILER - STAGE ------------
FROM quay.io/almalinuxorg/10-minimal AS compiler

# Install core tools and SaltStack
RUN echo " Update OS repos"  && \
    microdnf update -y && \
    microdnf upgrade -y && \
    echo "Cleanup OS Packages" && \
    rm -rf /var/cache/dnf* && \
    rm -rf /usr/share/doc* && \
    microdnf clean all
# Install Compilation tools
RUN microdnf -y install gcc make patch bzip2 gzip autoconf automake libtool \
             bison readline-devel zlib-devel libffi-devel openssl-devel tar \
             && microdnf clean all

# --- READY TO START BUILDS -----

# Build and install libyaml from source
WORKDIR /tmp
RUN curl -O https://pyyaml.org/download/libyaml/yaml-0.2.5.tar.gz \
    && tar -xzf yaml-0.2.5.tar.gz \
    && cd yaml-0.2.5 \
    && ./configure --prefix=/opt/libyaml && make -j$(nproc) && make install \
    && cd .. && rm -rf yaml-0.2.5*

# Build and install Ruby 4.0 from source
RUN curl -O https://cache.ruby-lang.org/pub/ruby/4.0/ruby-4.0.7.tar.gz \
    && tar -xzf ruby-4.0.7.tar.gz \
    && cd ruby-4.0.7 \
    && export CPPFLAGS="-I/opt/libyaml/include" \
    && export LDFLAGS="-L/opt/libyaml/lib" \
    && ./configure --prefix=/opt/ruby --disable-install-doc \
    && make -j$(nproc) && make install \
    && cd .. && rm -rf ruby-4.0.7*

# Install serverspec gem
RUN PATH="/opt/ruby/bin:$PATH" gem install --no-document serverspec

# Pre-initialize serverspec configuration
RUN mkdir -p /opt/serverspec/init \
    && cd /opt/serverspec/init \
    && PATH="/opt/ruby/bin:$PATH" bash -c 'echo -e "2\nlocalhost" | serverspec-init' \
    && mv spec/spec_helper.rb /opt/serverspec/spec_helper.rb \
    && rm -rf /opt/serverspec/init

# ------ Runtime - Stage ----
FROM quay.io/almalinuxorg/10-minimal

LABEL maintainer="rauf.hammad@gmail.com"
LABEL description="Reusable Salt master base image with Ruby 4.0.7, serverspec, and custom /srv/salt layout"

# Update OS Image
RUN echo " Update OS repos"  && \
    microdnf update -y && \
    microdnf upgrade -y && \
    echo "Cleanup OS Packages" && \
    rm -rf /var/cache/dnf* && \
    rm -rf /usr/share/doc* && \
    microdnf clean all

# Install basic tools and SaltStack, and libs Ruby links against at runtime
RUN microdnf -y install procps net-tools curl nano httpd openssh-server \
              zlib libffi openssl-libs readline \
    && curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo \
       | tee /etc/yum.repos.d/salt.repo \
    && microdnf update -y \
    && microdnf -y install salt-master salt-minion cronie \
    && microdnf clean all \
    && rm -rf /var/cache/dnf* /usr/share/doc*

# Copy Over Compiled artifacts from previuos Layer, and set them up.
COPY --from=compiler /opt/libyaml /usr/local
RUN ldconfig
COPY --from=compiler /opt/ruby /opt/ruby
COPY --from=compiler /opt/serverspec/spec_helper.rb /opt/serverspec/spec_helper.rb
ENV PATH="/opt/ruby/bin:/opt/serverspec:${PATH}"

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

# Copy wrapper script into persistent location
COPY run_all_tests.sh /opt/serverspec/run_all_tests.sh
# Make it executable
RUN chmod +x /opt/serverspec/run_all_tests.sh

WORKDIR /root

# Enable services
RUN systemctl enable httpd \
    && systemctl enable sshd \
    && systemctl enable salt-master \
    && systemctl enable salt-minion

# Configure Salt-Minion OS(Almalinux-minimal) Specific Providers
RUN printf '%s\n' \
        'providers:' \
        '  pkg: dnf' \
        '  service: systemd' \
        >> /etc/salt/minion
# Configure Salt minion to point to local master
RUN echo "master: localhost" > /etc/salt/minion.d/master.conf \
    && echo "local-master" > /etc/salt/minion_id

# # Accept Minion Keys automatically    
# RUN echo "auto_accept: True" > /etc/salt/master.d/auto_accept.conf

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
EXPOSE 22 80 4505 4506

ENTRYPOINT [ "/sbin/init" ]
#CMD ["/opt/serverspec/run_all_tests.sh"]
