FROM debian:bookworm

# Install vsftpd and openssl
RUN apt-get update && \
    apt-get install -y vsftpd openssl && \
    rm -rf /var/lib/apt/lists/*

# Pre-create directories needed at runtime
RUN mkdir -p /var/www/html /var/run/vsftpd/empty

# Expose FTP ports
EXPOSE 20 21
EXPOSE 21000-21010

# Copy the entrypoint script
COPY ./tools/vsftpd_entrypoint.sh /usr/local/bin/vsftpd_entrypoint.sh
RUN chmod +x /usr/local/bin/vsftpd_entrypoint.sh

ENTRYPOINT ["/usr/local/bin/vsftpd_entrypoint.sh"]
CMD []
