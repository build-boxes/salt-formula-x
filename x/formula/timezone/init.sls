{% set tz = salt['pillar.get']('timezone', 'UTC') %}

timezone_symlink:
  file.symlink:
    - name: /etc/localtime
    - target: /usr/share/zoneinfo/{{ tz }}
    - force: True

timezone_cmd:
  cmd.run:
    - name: timedatectl set-timezone {{ tz }}
    - unless: "timedatectl | grep 'Time zone: {{ tz }}'"
