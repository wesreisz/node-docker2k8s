FROM node:15-stretch
COPY index.js index.js
CMD ["node", "index.js"]
