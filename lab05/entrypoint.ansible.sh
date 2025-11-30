#!/usr/bin/env sh
set -eu

: "${JENKINS_ANSIBLE_AGENT_SSH_PUBKEY:?Env var required}"

install -d -m 700 -o jenkins -g jenkins /home/jenkins/.ssh
echo "${JENKINS_ANSIBLE_AGENT_SSH_PUBKEY}" > /home/jenkins/.ssh/authorized_keys
chown jenkins:jenkins /home/jenkins/.ssh/authorized_keys
chmod 600 /home/jenkins/.ssh/authorized_keys

# Приватный ключ для тест-сервера уже смонтирован (read-only) по пути:
# /home/jenkins/.ssh/test_server_ansible_key
chmod 600 /home/jenkins/.ssh/test_server_ansible_key || true
chown jenkins:jenkins /home/jenkins/.ssh/test_server_ansible_key || true

echo "Starting sshd..."
exec /usr/sbin/sshd -D -e