# Compressed swap (zram|zswap|none) and the kdump crash-kernel reservation.
# Pillar (defaults shown):
#   ram:
#     swap_mode: zram      # none | zram | zswap
#     kdump: disable       # enable | disable
# The scripts are idempotent and their 'check' sub-command is used as the
# 'unless' guard, so a highstate reports no change once a host is configured.
{% set swap_mode = salt['pillar.get']('ram:swap_mode', 'zram') %}
{% set kdump = salt['pillar.get']('ram:kdump', 'disable') %}

{% for script in ['ramsetup', 'kdumpsetup'] %}
/usr/local/sbin/{{ script }}:
  file.managed:
    - source: salt://ram/files/{{ script }}
    - user: root
    - group: root
    - mode: '0755'
{% endfor %}

ramsetup-{{ swap_mode }}:
  cmd.run:
    - name: /usr/local/sbin/ramsetup {{ swap_mode }}
    - unless: /usr/local/sbin/ramsetup check {{ swap_mode }}
    - require:
      - file: /usr/local/sbin/ramsetup

kdumpsetup-{{ kdump }}:
  cmd.run:
    - name: /usr/local/sbin/kdumpsetup {{ kdump }}
    - unless: /usr/local/sbin/kdumpsetup check {{ kdump }}
    - require:
      - file: /usr/local/sbin/kdumpsetup
