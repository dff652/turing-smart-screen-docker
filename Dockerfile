ARG PYTHON_IMAGE=python:3.10-slim-bookworm
ARG TURING_REF=3.10.0

FROM ${PYTHON_IMAGE} AS source
ARG TURING_REF
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl tar \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /opt
RUN curl -fsSL "https://github.com/mathoudebine/turing-smart-screen-python/archive/${TURING_REF}.tar.gz" -o /tmp/turing.tar.gz \
    && mkdir -p /opt/turing-smart-screen-python \
    && tar -xzf /tmp/turing.tar.gz -C /opt/turing-smart-screen-python --strip-components=1 \
    && cp /opt/turing-smart-screen-python/config.yaml /opt/turing-smart-screen-python/config.yaml.dist \
    && rm -f /tmp/turing.tar.gz

FROM ${PYTHON_IMAGE} AS builder
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential git libdrm-dev \
    && rm -rf /var/lib/apt/lists/*
COPY --from=source /opt/turing-smart-screen-python /opt/turing-smart-screen-python
RUN python -m venv /opt/venv \
    && /opt/venv/bin/pip install --no-cache-dir --upgrade pip setuptools wheel \
    && /opt/venv/bin/pip install --no-cache-dir -r /opt/turing-smart-screen-python/requirements.txt

FROM ${PYTHON_IMAGE}
ARG TURING_REF
LABEL org.opencontainers.image.title="turing-smart-screen-python for NAS" \
      org.opencontainers.image.description="Containerized runtime for mathoudebine/turing-smart-screen-python on FnOS/NAS" \
      org.opencontainers.image.source="https://github.com/mathoudebine/turing-smart-screen-python" \
      org.opencontainers.image.revision="${TURING_REF}"

ENV APP_DIR=/opt/turing-smart-screen-python \
    CONFIG_DIR=/config \
    PATH=/opt/venv/bin:$PATH \
    PYTHONUNBUFFERED=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        fonts-dejavu-core \
        iproute2 \
        libdrm2 \
        libusb-1.0-0 \
        lm-sensors \
        pciutils \
        procps \
        tzdata \
        usbutils \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv
COPY --from=source /opt/turing-smart-screen-python /opt/turing-smart-screen-python
COPY entrypoint.sh /usr/local/bin/turing-entrypoint

RUN chmod 755 /usr/local/bin/turing-entrypoint \
    && mkdir -p /config

WORKDIR /opt/turing-smart-screen-python
VOLUME ["/config"]
ENTRYPOINT ["turing-entrypoint"]
CMD ["python", "main.py"]
