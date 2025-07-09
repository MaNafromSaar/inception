FROM debian:bullseye

# Declare build arguments
ARG FTP_USER
ARG FTP_PASS

# Install vsftpd and openssl
RUN apt-get update && \
    apt-get install -y vsftpd openssl && \
    rm -rf /var/lib/apt/lists/*

# Create a user for FTP
RUN mkdir -p /var/www/html && \
    useradd -m -s /bin/bash ${FTP_USER} && \
    echo "${FTP_USER}:${FTP_PASS}" | chpasswd && \
    chown -R ${FTP_USER}:${FTP_USER} /var/www/html

# Expose FTP ports
EXPOSE 20 21
EXPOSE 21000-21010

# Copy the entrypoint script
COPY ./tools/vsftpd_entrypoint.sh /usr/local/bin/vsftpd_entrypoint.sh
RUN chmod +x /usr/local/bin/vsftpd_entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/vsftpd_entrypoint.sh"]

# Default command, can be overridden
CMD []
