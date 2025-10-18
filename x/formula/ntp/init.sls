{% set osfam = grains['os_family']|lower %}
{% set ntp_pkg = salt['pillar.get']('ntp:' ~ osfam ~ ':package', 'chrony') %}
{% set ntp_srv = salt['pillar.get']('ntp:' ~ osfam ~ ':service', 'chronyd') %}

ntp_package:
  pkg.installed:
    - name: {{ ntp_pkg }}

ntp_service:
  service.running:
    - name: {{ ntp_srv }}
    - enable: True