FROM jenkins/ssh-agent

# Установим php-cli
RUN apt-get update && \
    apt-get install -y --no-install-recommends php-cli git && \
    rm -rf /var/lib/apt/lists/*