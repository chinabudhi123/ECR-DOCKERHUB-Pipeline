# Use official Apache HTTP Server image as base
FROM httpd:2.4

# Remove default Apache html files
RUN rm -rf /usr/local/apache2/htdocs/*

# Copy custom index.html into the container's web root
COPY index.html /usr/local/apache2/htdocs/index.html

# Expose port 80
EXPOSE 80

# Start Apache HTTP Server in foreground
CMD ["httpd-foreground"]

