FROM postgres:18.7

RUN apt-get update \
 && apt-get install -y --no-install-recommends pgbackrest=2.60.1-1.pgdg13+1 \
 && rm -rf /var/lib/apt/lists/* \
 && install -d -o postgres -g postgres -m 750 /var/lib/pgbackrest /var/log/pgbackrest

COPY postgres/pgbackrest.conf /etc/pgbackrest/pgbackrest.conf
COPY backup/destino.sh /opt/crm/backup/destino.sh
COPY backup/pgbackrest.sh /usr/local/bin/crm-pgbackrest
RUN chmod 644 /etc/pgbackrest/pgbackrest.conf /opt/crm/backup/destino.sh \
 && chmod 755 /usr/local/bin/crm-pgbackrest
