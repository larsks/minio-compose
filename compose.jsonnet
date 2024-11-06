function()
  local node(number) = {
    hostname: 'node%s' % number,
    image: 'docker.io/minio/minio',
    volumes: [
      'minio_data%s:/data' % number,
    ],
    command: [
      'server',
      '--console-address',
      ':9001',
      'http://node{0...3}/data',
    ],
    environment: {
      MINIO_ROOT_USER: '${MINIO_ROOT_USER}',
      MINIO_ROOT_PASSWORD: '${MINIO_ROOT_PASSWORD}',
    },
    ports: [
      '%s:9001' % (10000 + number),
    ],
    healthcheck: {
      test: ['CMD', 'curl', '-sf', 'http://localhost:9000/minio/health/live'],
      interval: '5s',
      retries: 3,
    },
    labels: [
      'traefik.enable=true',
      'traefik.http.routers.minio.rule=Host(`minio.internal`)',
      'traefik.http.services.minio.loadbalancer.server.port=9000',
    ],
  };

  {
    volumes: { ['minio_data%d' % number]: null for number in std.range(0, 3) },
    services: { ['node%s' % number]: node(number) for number in std.range(0, 3) } + {
      frontend: {
        image: 'docker.io/traefik:v3.2',
        command: [
          '--api.insecure=true',
          '--api.dashboard=true',
          '--providers.docker',
          '--providers.docker.exposedbydefault=false',
        ],
        ports: [
          '9000:80',
          '127.0.0.1:12080:8080',
        ],
        volumes: [
          '/run/docker.sock:/run/docker.sock:ro',
        ],
      },
    },
  }
