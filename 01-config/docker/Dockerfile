# Imagem base para agentes Makan72
FROM python:3.11-slim

# Ferramentas essenciais
RUN apt-get update && apt-get install -y \
    bash \
    jq \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Directório de trabalho
WORKDIR /workspace

# Copiar apenas o necessário (memória + config)
COPY 00-global/ /makan72/00-global/
COPY 01-config/ /makan72/01-config/

# Utilizador não-root (segurança)
RUN useradd -m agent
USER agent

# Entry point
ENTRYPOINT ["/bin/bash"]
