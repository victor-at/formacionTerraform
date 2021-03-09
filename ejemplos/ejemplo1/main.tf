terraform { 
    required_providers {
        docker = {
            source = "kreuzwerker/docker"
        }
    }
}

provider docker {
}

resource "docker_container" "contenedor_nginx"{ 
    name = "mi-contenedor-de-nginx"
    image = docker_image.imagen_nginx.latest
}

resource "docker_image" "imagen_nginx"{ 
    name = "nginx:latest"
}

