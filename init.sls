{% set config_dir = salt['environ.get']('CONFIG_DIR', '/tmp') %}

salt-master-state-tree:
  module.run:
    - name: file.copy
    - src: {{ config_dir }}/salt
    - dst: /srv/salt
    - recurse: true
    - onlyif:
      - test -d "{{ config_dir }}/salt"
      - test ! -d /srv/salt || test -z "$(ls -A /srv/salt)"

salt-master-pillar-tree:
  module.run:
    - name: file.copy
    - src: {{ config_dir }}/pillar
    - dst: /srv/pillar
    - recurse: true
    - onlyif:
      - test -d "{{ config_dir }}/pillar"
      - test ! -d /srv/pillar || test -z "$(ls -A /srv/pillar)"

salt-minion:
  service.running:
    - name: salt-minion
    - init_delay: 2

salt-minion-hostname:
  file.replace:
    - name: /etc/salt/minion
    - pattern: '^#?master:.*'
    - repl: 'master: {{ salt['pillar.get']('minion_hostname', '127.0.0.1') }}'
    - append_if_not_found: true
    - watch_in:
      - service: salt-minion

salt-master-accept-minion:
  module.run:
    - name: saltutil.wheel
    - _fun: key.accept
    - args:
      - {{ grains['id'] }}