server {
  listen 80;
  root /usr/share/nginx/html;
  index index.html;

  gzip on;
  gzip_types text/css application/javascript application/json image/svg+xml;
{{#if mono}}

  # One origin for app and API: no CORS, first-party cookies.
  location /api/ {
    proxy_pass http://api:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
{{/if}}

  # Entry points and service worker files must always be revalidated; hashed assets are immutable.
  location ~ ^/(index\.html|ngsw\.json|ngsw-worker\.js|safety-worker\.js)$ {
    add_header Cache-Control "no-cache";
  }

  # nginx's default mime table does not know .webmanifest.
  location = /manifest.webmanifest {
    default_type application/manifest+json;
    add_header Cache-Control "no-cache";
  }

  location ~* \.(?:js|css|woff2?|png|jpg|svg|ico)$ {
    add_header Cache-Control "public, max-age=31536000, immutable";
    try_files $uri =404;
  }

  location / {
    try_files $uri $uri/ /index.html;
  }
}
