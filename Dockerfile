# Usa la imagen base de NGINX
FROM nginx:latest

# Establece el directorio de trabajo
WORKDIR /usr/share/nginx/html

# Instala git
RUN apt-get update && apt-get install -y git

# Clona el repositorio 2048
RUN git clone https://github.com/josejuansanchez/2048.git /tmp \
    && cp -R /tmp/* /usr/share/nginx/html \
    && rm -rf /tmp

# Exponer el puerto 80
EXPOSE 80

# Comando para iniciar NGINX al iniciar el contenedor
CMD ["nginx", "-g", "daemon off;"]



