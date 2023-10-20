sudo apt update && sudo apt install -y apache2
sudo ufw allow 'Apache'
sudo systemctl start apache2
MYIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
echo "<h3>Hello world, I am the instance with IP: $(curl http://169.254.169.254/latest/meta-data/local-ipv4)</h3>" >> index.html
sudo mv -f index.html /var/www/html/