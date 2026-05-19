FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/usr/lib/postgresql/16/bin:${PATH}"

# Install tooling, both Python runtimes, and PostgreSQL 16
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    build-essential \
    && add-apt-repository ppa:deadsnakes/ppa -y \
    && install -d /usr/share/postgresql-common/pgdg \
    && curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc \
    && echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    python3.8 \
    python3.8-venv \
    python3.8-dev \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    postgresql-16 \
    postgresql-client-16 \
    postgresql-server-dev-16 \
    && rm -rf /var/lib/apt/lists/*

# Create the initial Python 3.8 virtual environment with Patroni + dependencies
RUN mkdir -p /opt/patroni /opt/venv312 /etc/patroni /var/lib/postgresql/16/data /var/run/postgresql \
    && python3.8 -m venv /opt/venv38 \
    && /opt/venv38/bin/pip install --no-cache-dir --upgrade pip \
    && /opt/venv38/bin/pip install --no-cache-dir "patroni[etcd]" psycopg2-binary \
    && ln -s /opt/venv38 /opt/patroni/venv \
    && chown -R postgres:postgres /opt/patroni /opt/venv38 /opt/venv312 /var/lib/postgresql /var/run/postgresql

COPY patroni.yml /etc/patroni/patroni.yml
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

USER postgres

EXPOSE 5432 8008

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
