{% set agent = pillar.zabbix.agent %}

{%- if agent.enabled %}

{% set version = agent.get('version', '2') %}

{%- if grains.os_family == "RedHat" %}

{% if version == '2' %}
{% set zabbix_package_present = 'zabbix20-agent' %}
{% set zabbix_packages_absent = ['zabbix-agent', 'zabbix'] %}
{% else %}
{% set zabbix_package_present = 'zabbix-agent' %}
{% set zabbix_packages_absent = ['zabbix20-agent', 'zabbix20'] %}
{% endif %}

zabbix_agent_absent_packages:
  pkg.removed:
  - names: {{ zabbix_packages_absent }}

zabbix_agent_packages:
  pkg.installed:
  - name: {{ zabbix_package_present }}

{%- endif %}

{%- if grains.os_family == "Debian" %}

{% if version == '2' %}

{% set zabbix_base_url = 'http://repo.zabbix.com/zabbix/2.0/ubuntu/pool/main/z/zabbix-release' %}
{% set zabbix_base_file = 'zabbix-release_2.0-1precise_all.deb' %}

zabbix_package_download:
  cmd.run:
  - name: wget {{ zabbix_base_url }}/{{ zabbix_base_file }}
  - unless: "[ -f /root/{{ zabbix_base_file }} ]"
  - cwd: /root

zabbix_agent_packages:
  pkg.installed:
  - sources:
    - zabbix-release: /root/{{ zabbix_base_file }}
  - require:
    - cmd: zabbix_package_download

{% else %}

zabbix_agent_packages:
  pkg.installed:
  - name: zabbix-agent

{% endif %}

{%- endif %}

zabbix_agent_config:
  file.managed:
  - name: /etc/zabbix_agentd.conf
  - source: salt://zabbix/conf/zabbix_agentd.conf
  - template: jinja
  - require:
    - pkg: zabbix_agent_packages

zabbix_agentd.conf.d:
  file.directory:
  - name: /etc/zabbix/zabbix_agentd.conf.d
  - makedirs: true
  - require:
    - pkg: zabbix_agent_packages

zabbix_user:
  user.present:
  - name: zabbix
  - system: True
  - home: /var/lib/zabbix

zabbix_log_dir:
  file.directory:
  - name: /var/log/zabbix
  - user: zabbix
  - makedirs: true
  - require:
    - user: zabbix_user

zabbix_agent_service:
  service.running:
  - name: zabbix-agent
  - enable: True
  - require:
    - file: zabbix_log_dir
  - watch:
    - file: zabbix_agent_config

{%- else %}

zabbix_agent_packages:
  pkg.removed:
  - names:
    - zabbix20-agent
    - zabbix20
    - zabbix-agent
    - zabbix

{%- endif %}