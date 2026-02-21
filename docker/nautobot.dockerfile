# vim: set ft=dockerfile noet ts=4 sw=4 :

ARG NAUTOBOT_REGISTRY_URL=ghcr.io/nautobot
ARG NAUTOBOT_VERSION=2.4.27
ARG PYTHON_VERSION=3.12

# #############################################################################
# Stage: Base image
# #############################################################################
FROM ${NAUTOBOT_REGISTRY_URL}/nautobot:${NAUTOBOT_VERSION}-py${PYTHON_VERSION} AS nautobot-base

USER root

RUN <<-EOT
	apt-get update
	apt-get upgrade -y
	apt-get autoremove -y
	apt-get clean all
	rm -rf /var/lib/apt/lists/*
	pip --no-cache-dir install --upgrade pip wheel
EOT

# #############################################################################
# Stage: Builder
# #############################################################################
FROM ${NAUTOBOT_REGISTRY_URL}/nautobot-dev:${NAUTOBOT_VERSION}-py${PYTHON_VERSION} AS builder
ARG NAUTOBOT_VERSION
ARG PYTHON_SUPPORTED_RANGE

CMD ["nautobot-server", "runserver", "0.0.0.0:8080", "--insecure"]

RUN <<-EOT
	apt-get update
	apt-get install -y libldap2-dev libsasl2-dev libssl-dev
	apt-get autoremove -y
	apt-get clean
	rm -rf /var/lib/apt/lists/*
	pip --no-cache-dir install --upgrade pip wheel django-auth-ldap h11
EOT

# -----------------------------------------------------------------------------
# Configuration for development
# -----------------------------------------------------------------------------
WORKDIR /opt/nautobot
COPY  nautobot/ .

# -----------------------------------------------------------------------------
# Nautobot dev project
# -----------------------------------------------------------------------------
WORKDIR /source

RUN <<-EOT
	echo ------------------------------------------
	echo "Nautobot version: ${NAUTOBOT_VERSION}"
	python --version
	poetry --version
	echo PYTHON_SUPPORTED_RANGE ${PYTHON_SUPPORTED_RANGE}
	echo ------------------------------------------

	poetry init --no-interaction \
		--name="nautobot-docker-compose" \
		--author="Network to Code LLC" \
		--python="${PYTHON_SUPPORTED_RANGE}"
	cat pyproject.toml

	# Generate poetry.lock & install/update dependencies
	poetry add "nautobot==${NAUTOBOT_VERSION}"
	if [ -f "${PROJECT_NAME}.py" ] || [ -f "${PROJECT_NAME}/__init__.py" ]; then
		[ ! -f "README.md" ] && touch README.md
		poetry install --no-ansi --no-interaction
	else
		poetry install --no-root --no-ansi --no-interaction
	fi

	# Export requirements.txt
	poetry self add poetry-plugin-export
	mkdir /tmp/dist
	poetry export --without-hashes -o /tmp/dist/requirements.txt
EOT

# NOTES:
# - Seems that nothing happens with the exported requirements.txt file
# - Nautobot is already installed so there is no need to poetry add
# - Or as in the original code poetry install since only add invoke and toml
#   this two last are a requirement for the host seems not used on the container
# - Exporting the requirements.txt seems useless

# -----------------------------------------------------------------------------
# Plugins
# -----------------------------------------------------------------------------
WORKDIR /source
COPY ./source/ .

RUN <<-EOT
	for plugin in ./plugins/*; do
		cd $plugin
		poetry build;
		cp dist/*.whl /tmp/dist;
	done
EOT

# #############################################################################
# Final Image
# #############################################################################
FROM nautobot-base AS nautobot
ARG PYTHON_VERSION

COPY --from=builder /opt/nautobot /opt/nautobot

# Recover from base the required python libraries and binaries
COPY --from=builder /usr/local/lib/python${PYTHON_VERSION}/site-packages /usr/local/lib/python${PYTHON_VERSION}/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Recover *.whl generated and requirements.txt
COPY --from=builder /tmp/dist/*.whl /tmp/dist/requirements.txt /tmp/dist/
RUN <<-EOT
	grep -v /source/plugins /tmp/dist/requirements.txt > /tmp/dist/new_requirements.txt
	pip install -r /tmp/dist/new_requirements.txt
	pip install /tmp/dist/*.whl
	rm -rf /source /tmp/dist
	chown -R nautobot:nautobot /opt/nautobot
EOT

# Verify that pyuwsgi was installed correctly, i.e. with SSL support
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN pyuwsgi --cflags | sed 's/ /\n/g' | grep -e "^-DUWSGI_SSL$"

USER nautobot
WORKDIR /opt/nautobot
