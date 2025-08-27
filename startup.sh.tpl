#!/bin/bash

# Add a retry loop to apt-get update to handle network initialization delays.
for i in {1..5}; do
  apt-get update -o Acquire::ForceIPv4=true && break
  echo "apt-get update failed, retrying in 10 seconds..."
  sleep 10
done

# Install Apache, forcing IPv4 for network connections
apt-get install -y apache2 -o Acquire::ForceIPv4=true
a2enmod ssl
mkdir -p /etc/apache2/ssl

# Generate a self-signed certificate using the FQDN variable from Terraform
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/apache2/ssl/apache.key \
    -out /etc/apache2/ssl/apache.crt \
    -subj "/CN=${fqdn}" \
    -addext "subjectAltName = DNS:${fqdn}"

# Create an SSL configuration for the default site
cat > /etc/apache2/sites-available/default-ssl.conf <<'EOF'
<IfModule mod_ssl.c>
    <VirtualHost _default_:443>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html
        ErrorLog $${APACHE_LOG_DIR}/error.log
        CustomLog $${APACHE_LOG_DIR}/access.log combined
        SSLEngine on
        SSLCertificateFile      /etc/apache2/ssl/apache.crt
        SSLCertificateKeyFile   /etc/apache2/ssl/apache.key
        <FilesMatch "\.(cgi|shtml|phtml|php)$">
            SSLOptions +StdEnvVars
        </FilesMatch>
        <Directory /usr/lib/cgi-bin>
            SSLOptions +StdEnvVars
        </Directory>
    </VirtualHost>
</IfModule>
EOF


# Remove the default Apache index.html file
rm /var/www/html/index.html

# Create the new index.html file
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Private Webapp</title>
    <link rel="stylesheet" href="style.css">
    <link href="https://fonts.googleapis.com/css2?family=Montserrat:wght@700&display=swap" rel="stylesheet">
</head>
<body>
    <div class="scene">
        <div class="spinner">
            This is a private webapp on Google Cloud
        </div>
    </div>
</body>
</html>
EOF

# Create the style.css file
cat > /var/www/html/style.css <<'EOF'
body, html {
    margin: 0;
    padding: 0;
    width: 100%;
    height: 100%;
    overflow: hidden;
    font-family: 'Montserrat', sans-serif;
}

body {
    display: flex;
    justify-content: center;
    align-items: center;
    background: linear-gradient(45deg, #0f0c29, #302b63, #24243e, #00d9ff, #00aaff);
    background-size: 400% 400%;
    animation: gradientBG 15s ease infinite;
}

@keyframes gradientBG {
    0% { background-position: 0% 50%; }
    50% { background-position: 100% 50%; }
    100% { background-position: 0% 50%; }
}

.scene {
    perspective: 900px;
    width: 80vw;
    text-align: center;
}

.spinner {
    font-size: 5vw;
    color: white;
    text-shadow:
        0 0 5px #fff,
        0 0 10px #fff,
        0 0 20px #00aaff,
        0 0 30px #00aaff,
        0 0 40px #00aaff;
    transform-style: preserve-3d;
    animation: spin 12s infinite linear;
}

@keyframes spin {
    from { transform: rotateY(0deg); }
    to { transform: rotateY(360deg); }
}
EOF


# Enable the new SSL site and restart Apache
a2ensite default-ssl.conf
systemctl restart apache2
