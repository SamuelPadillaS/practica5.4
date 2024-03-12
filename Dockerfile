# Utiliza la última versión de Ubuntu como imagen base
FROM ubuntu:latest

# Actualiza el repositorio e instala git y nginx
RUN apt-get update && \
    apt-get install -y git nginx && \
    rm -rf /var/lib/apt/lists/*

# Elimina el contenido existente en /usr/share/nginx/html
RUN rm -rf /usr/share/nginx/html/*

# Clona el repositorio de GitHub en el directorio /usr/share/nginx/html/
RUN git clone https://github.com/josejuansanchez/2048.git /usr/share/nginx/html/

# Expone el puerto 80
EXPOSE 80

# Comando que se ejecutará al iniciar el contenedor
CMD ["nginx", "-g", "daemon off;"]
