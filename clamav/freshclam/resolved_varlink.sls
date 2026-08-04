# salt://apparmor/resolved_varlink.sls
#
# Fixes:
#   apparmor="DENIED" operation="connect" profile="/usr/bin/freshclam"
#   name="/run/systemd/resolve/io.systemd.Resolve" requested_mask="wr"
#
# systemd >= 255 ships nss-resolve, which prefers the Varlink socket
# /run/systemd/resolve/io.systemd.Resolve over the older D-Bus path.
# AppArmor abstractions shipped before that change don't allow it, so any
# confined binary doing a DNS lookup trips a denial.
#
# Default strategy: drop a rule into abstractions/nameservice.d/, which fixes
# every profile that includes <abstractions/nameservice> at once. This relies
# on `include if exists <abstractions/nameservice.d>` (AppArmor 3.0+, i.e.
# Ubuntu 22.04 / Debian 12 and newer).
#
# On AppArmor 2.x, set the pillar below to patch named profiles individually:
#
#   apparmor:
#     use_local_overrides: true
#     varlink_profiles:
#       - usr.bin.freshclam
#       - usr.sbin.clamd

{%- set rule = '/run/systemd/resolve/io.systemd.Resolve rw,' %}
{%- set use_local = salt['pillar.get']('apparmor:use_local_overrides', False) %}
{%- set profiles = salt['pillar.get']('apparmor:varlink_profiles', ['usr.bin.freshclam']) %}

apparmor_pkg:
  pkg.installed:
    - name: apparmor

{%- if not use_local %}

apparmor_nameservice_d:
  file.directory:
    - name: /etc/apparmor.d/abstractions/nameservice.d
    - user: root
    - group: root
    - mode: '0755'
    - makedirs: True
    - require:
      - pkg: apparmor_pkg

resolved_varlink_abstraction:
  file.managed:
    - name: /etc/apparmor.d/abstractions/nameservice.d/systemd-resolve-varlink
    - user: root
    - group: root
    - mode: '0644'
    - contents: |
        # Managed by Salt. systemd >= 255 nss-resolve uses the Varlink socket.
        {{ rule }}
    - require:
      - file: apparmor_nameservice_d
    - watch_in:
      - service: apparmor_service

apparmor_service:
  service.running:
    - name: apparmor
    - enable: True
    - reload: True
    - require:
      - pkg: apparmor_pkg

{%- else %}

{%- for profile in profiles %}

local_dir_{{ profile }}:
  file.directory:
    - name: /etc/apparmor.d/local
    - user: root
    - group: root
    - mode: '0755'
    - require:
      - pkg: apparmor_pkg

local_override_{{ profile }}:
  file.append:
    - name: /etc/apparmor.d/local/{{ profile }}
    - text: '{{ rule }}'
    - require:
      - file: local_dir_{{ profile }}

reload_profile_{{ profile }}:
  cmd.run:
    - name: apparmor_parser -r /etc/apparmor.d/{{ profile }}
    - onchanges:
      - file: local_override_{{ profile }}

{%- endfor %}
{%- endif %}
