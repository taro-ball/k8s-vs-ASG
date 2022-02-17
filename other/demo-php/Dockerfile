FROM httpd:2.4.51-buster
ADD  ./test.php /var/www/html/test.php
RUN apt update
RUN apt install php7.3 -y
EXPOSE 80
CMD ["httpd-foreground"]