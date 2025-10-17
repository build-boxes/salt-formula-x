FROM quay.io/almalinuxorg/almalinux:8
RUN dnf -y install nano
RUN curl -fsSL https://github.com/saltstack/salt-install-guide/releases/latest/download/salt.repo | tee /etc/yum.repos.d/salt.repo
RUN dnf update -y 
RUN dnf -y install salt-master salt-minion
RUN dnf -y install ruby
RUN dnf clean expire-cache
RUN dnf clean all
RUN systemctl enable salt-master
RUN systemctl enable salt-minion
RUN gem install --no-document serverspec
ENTRYPOINT [ "/sbin/init" ]
#CMD [ "/bin/bash", "-c", "/usr/bin/tail -f /dev/null" ]
