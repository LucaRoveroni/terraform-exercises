MYIP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
echo "<h3>Hello world, I am the instance with IP: $(curl http://169.254.169.254/latest/meta-data/local-ipv4)</h3>" >> index.html
nohup sudo python3 -m http.server 8080 &