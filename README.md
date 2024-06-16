# «Dockerizar» una web estática y publicarla en Docker Hub

En esta práctica tendremos que crear un archivo Dockerfile para crear una imagen Docker que contenga una aplicación web estática. Posteriormente deberá publicar la imagen en Docker Hub y realizar la implantación del sitio web en Amazon Web Services (AWS) haciendo uso de contenedores Docker y de la herramienta Docker Compose.

### Tareas a realizar

A continuación se describen muy brevemente algunas de las tareas que tendrá que realizar.

- Crea un archivo Dockerfile para crear una imagen que contenga el servicio de Nginx con la siguiente aplicación web estática:

https://github.com/josejuansanchez/2048

- Publica la imagen en Docker Hub.

- Crea una máquina virtual Amazon EC2.

- Instala y configura Docker y Docker compose en la máquina virtual.

- Crea un archivo docker-compose.yml para poder desplegar la aplicación web estática en la máquina virtual de AWS.

- Busque cuál es la dirección IP pública de su instancia y compruebe que puede acceder a la aplicación web desde un navegador web.

### Requisitos del archivo Dockerfile

Tendrá que crear un archivo Dockerfile con los siguientes requisitos:

- Como imagen base deberá utilizar la última versión de ubuntu.

- Instala el software necesario para poder clonar el repositorio de GitHub donde se encuentra la aplicación web estática.

- Clona el repositorio de GitHub donde se encuentra la aplicación web estática en el directorio /usr/share/nginx/html/, que es el directorio que utiliza Nginx, por defecto, para servir el contenido.

- El puerto que usará la imagen para ejecutar el servicio de Nginx será el puerto 80.

- El comando que se ejecutará al iniciar el contenedor será el comando nginx -g   'daemon off;'.

### Creación de la imagen Docker a partir del archivo Dockerfile

Para crear la imagen de Docker a partir del archivo Dockerfile deberá ejecutar el siguiente comando.

~~~
docker build -t nginx-2048 
~~~

Para comprobar que la imagen se ha creado correctamente podemos ejecutar el comando:

~~~
docker images
~~~

Para publicar la imagen en Docker Hub es necesario que en el nombre de la imagen aparezca nuestro nombre de usuario de Docker Hub. Por ejemplo, si mi nombre de usuario es josejuansanchez la imagen debería llamarse josejuansanchez/nginx-2048.

También es una buena práctica asignarle una etiqueta a la imagen. Por ejemplo, en este caso vamos a asignarle las etiquetas 1.0 y latest.

~~~
docker tag nginx-2048 josejuansanchez/nginx-2048:1.0
docker tag nginx-2048 josejuansanchez/nginx-2048:latest
~~~

Comprobamos que la imagen tiene el nombre y las etiquetas correctas:

~~~
docker images
~~~

### Publicar la imagen en Docker Hub

Una vez que le hemos asignado un nombre correcto a la imagen y le hemos añadido las etiquetas, podemos publicarla en Docker Hub.

En primer lugar, tendremos que iniciar la sesión en Docker Hub con el comando:

~~~
docker login
~~~

Una vez iniciada la sesión, podemos publicar la imagen con el comando docker push. Tenemos que publicar la imagen con las dos etiquetas que hemos creado.

~~~
docker push josejuansanchez/nginx-2048:1.0
docker push josejuansanchez/nginx-2048:latest
~~~

### Publicar la imagen automáticamente en Docker Hub con GitHub Actions

En este apartado vamos a aprender cómo podemos configurar GitHub Actions para publicar una imagen automáticamente en un Registry como Docker Hub, cada vez que se realice un push al repositorio de GitHub.

Se recomienda la lectura del apartado «Publicación de imágenes de Docker» de la documentación oficial de GitHub Actions.

Puede encontrar un ejemplo de cómo se puede configurar GitHub Actions para publicar una imagen de Docker en el siguiente repositorio de GitHub:

https://github.com/josejuansanchez/2048-github-actions

Para utilizar este ejemplo, deberá crear dos secrets en su repositorio para las acciones de GitHub Actions. Estos secrets almacenarán los siguientes valores:

- DOCKERHUB_USERNAME: Nombre de usuario en Docker Hub.
- DOCKERHUB_TOKEN: Token de acceso a Docker Hub, que tendrá que crear en la sección de Security de su cuenta de Docker Hub.

Lo primero de todo sera enseñar el contenido de cada uno de los archivos dentro de nuestro repositorio

## Dockerfile
~~~
FROM nginx:latest

WORKDIR /usr/share/nginx/html/

RUN apt-get update \
    && apt-get install -y git \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/josejuansanchez/2048.git /app \
    && cp -R /app/* /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
~~~

## /.github/workflows/publish-to-docker-hub.yml

~~~
name: Publish image to Docker Hub

# This workflow uses actions that are not certified by GitHub.
# They are provided by a third-party and are governed by
# separate terms of service, privacy policy, and support
# documentation.

on:
  push:
    branches: [ "main" ]
    # Publish semver tags as releases.
    tags: [ 'v*.*.*' ]
  workflow_dispatch:

env:
  # Use docker.io for Docker Hub if empty
  REGISTRY: docker.io
  # github.repository as <account>/<repo>
  #IMAGE_NAME: ${{ github.repository }}
  IMAGE_NAME: 2048
  IMAGE_TAG: latest

jobs:
  build:

    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      # Set up BuildKit Docker container builder to be able to build
      # multi-platform images and export cache
      # https://github.com/docker/setup-buildx-action
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@f95db51fddba0c2d1ec667646a06c2ce06100226 # v3.0.0

      # Login against a Docker registry except on PR
      # https://github.com/docker/login-action
      - name: Log into registry ${{ env.REGISTRY }}
        uses: docker/login-action@343f7c4344506bcbf9b4de18042ae17996df046d # v3.0.0
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ secrets.DOCKERHUB_USERNAME }}
          password: ${{ secrets.DOCKERHUB_TOKEN }}

      # This action can be used to check the content of the variables
      - name: Debug
        run: |
          echo "github.repository: ${{ github.repository }}"
          echo "env.REGISTRY: ${{ env.REGISTRY }}"
          echo "github.sha: ${{ github.sha }}"
          echo "env.IMAGE_NAME: ${{ env.IMAGE_NAME }}"

      # Build and push Docker image with Buildx (don't push on PR)
      # https://github.com/docker/build-push-action
      - name: Build and push Docker image
        id: build-and-push
        uses: docker/build-push-action@0565240e2d4ab88bba5387d719585280857ece09 # v5.0.0
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ env.REGISTRY }}/${{ secrets.DOCKERHUB_USERNAME }}/${{ env.IMAGE_NAME }}:${{ env.IMAGE_TAG }}
          cache-from: type=gha
          cache-to: type=gha,mode=max   
~~~

## .github/workflows/publish-to-github-registry.yml

~~~
name: Publish image to GitHub Container Registry

# This workflow uses actions that are not certified by GitHub.
# They are provided by a third-party and are governed by
# separate terms of service, privacy policy, and support
# documentation.

on:
  schedule:
    - cron: '32 16 * * *'
  push:
    branches: [ "main" ]
    # Publish semver tags as releases.
    tags: [ 'v*.*.*' ]
  pull_request:
    branches: [ "main" ]

env:
  # Use docker.io for Docker Hub if empty
  REGISTRY: ghcr.io
  # github.repository as <account>/<repo>
  IMAGE_NAME: ${{ github.repository }}


jobs:
  build:

    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      # This is used to complete the identity challenge
      # with sigstore/fulcio when running outside of PRs.
      id-token: write

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      # Install the cosign tool except on PR
      # https://github.com/sigstore/cosign-installer
      - name: Install cosign
        if: github.event_name != 'pull_request'
        uses: sigstore/cosign-installer@6e04d228eb30da1757ee4e1dd75a0ec73a653e06 #v3.1.1
        with:
          cosign-release: 'v2.1.1'

      # Set up BuildKit Docker container builder to be able to build
      # multi-platform images and export cache
      # https://github.com/docker/setup-buildx-action
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@f95db51fddba0c2d1ec667646a06c2ce06100226 # v3.0.0

      # Login against a Docker registry except on PR
      # https://github.com/docker/login-action
      - name: Log into registry ${{ env.REGISTRY }}
        if: github.event_name != 'pull_request'
        uses: docker/login-action@343f7c4344506bcbf9b4de18042ae17996df046d # v3.0.0
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      # Extract metadata (tags, labels) for Docker
      # https://github.com/docker/metadata-action
      - name: Extract Docker metadata
        id: meta
        uses: docker/metadata-action@96383f45573cb7f253c731d3b3ab81c87ef81934 # v5.0.0
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}

      # Build and push Docker image with Buildx (don't push on PR)
      # https://github.com/docker/build-push-action
      - name: Build and push Docker image
        id: build-and-push
        uses: docker/build-push-action@0565240e2d4ab88bba5387d719585280857ece09 # v5.0.0
        with:
          context: .
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

      # Sign the resulting Docker image digest except on PRs.
      # This will only write to the public Rekor transparency log when the Docker
      # repository is public to avoid leaking data.  If you would like to publish
      # transparency data even for private images, pass --force to cosign below.
      # https://github.com/sigstore/cosign
      - name: Sign the published Docker image
        if: ${{ github.event_name != 'pull_request' }}
        env:
          # https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#using-an-intermediate-environment-variable
          TAGS: ${{ steps.meta.outputs.tags }}
          DIGEST: ${{ steps.build-and-push.outputs.digest }}
        # This step uses the identity token to provision an ephemeral certificate
        # against the sigstore community Fulcio instance.
        run: echo "${TAGS}" | xargs -I {} cosign sign --yes {}@${DIGEST}
~~~

Ya sabiendo el contenido de cada uno de los repositorios de este practica tambien necesitaremos crear un par de claves secretas para su debido funcionamiento ya que hay ciertas variables dentro de los yml que los solicitan.

![Screenshot 2024-03-13 000013](https://github.com/SamuelPadillaS/practica5.4/assets/114667075/b10ff737-071a-46a8-88b7-cdcc0a2e0b46)

Esto se encontraria dentro del archivo de configuración de nuestro repositorio

Algo tambien realmente importante seria darle permisos de lectura y escritura a nuestro workflow

![Screenshot 2024-03-13 000312](https://github.com/SamuelPadillaS/practica5.4/assets/114667075/1c20ccd2-a8aa-40c9-b3d7-3619fe6aca05)

Esta sección se encuentra en "Settings > Actions > General"

Ya con todo funcionando y subiendose toda imagen creada a nuestro repositorio de **DockerHub**, solo nos quedaria ejecutar nuestro contenedor a traves del puerto 80:

~~~
docker run -d -p 80:80 nombre_imagen
~~~

![280e5dc2-26f1-11e5-9f1f-5891c3ca8b26](https://github.com/SamuelPadillaS/practica5.4/assets/114667075/fe1796f2-2ec6-4553-9d40-1b151d69f206)

Ya con esto debería funcionarte.



