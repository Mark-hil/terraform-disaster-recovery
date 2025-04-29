version: '3.8'

services:
  frontend:
    image: ${frontend_image}
    ports:
      - "${frontend_port}:${frontend_port}"
    environment:
      - BACKEND_URL=http://backend:${backend_port}
    restart: always
    depends_on:
      - backend

  backend:
    image: ${backend_image}
    ports:
      - "${backend_port}:${backend_port}"
    environment:
      - DB_HOST=${DB_HOST}
      - DB_NAME=${DB_NAME}
      - DB_USER=${DB_USER}
      - DB_PASSWORD=${DB_PASSWORD}
    restart: always
