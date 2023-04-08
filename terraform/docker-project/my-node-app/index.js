const express = require('express');
const app = express();

app.get('/', (req, res) => {
  res.send(`Welcome to my Dockerized Node.js app!

This is a sample application that demonstrates how to containerize a Node.js application using Docker. With this application, you can learn how to:

- Create a new Node.js project using npm
- Write a Dockerfile to build a Docker image for your Node.js application
- Build a Docker image using the Docker CLI
- Run a Docker container from the Docker image
- Expose a port from the Docker container to the host machine
- Customize the startup behavior of the Docker container using environment variables

If you're new to Docker and containerization, this application is a great starting point to learn the basics. You can follow along with the step-by-step instructions to build and run the Docker container, and experiment with different configurations to see how it affects the behavior of the container.

Thank you for using my Dockerized Node.js app!`);
});

const port = process.env.PORT || 3000;

app.listen(port, () => {
  console.log(`Server listening on port ${port}.`);
});
