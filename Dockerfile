# syntax=docker/dockerfile:1

ARG PYTHON_VERSION=3.12.3
FROM python:${PYTHON_VERSION}-slim-bookworm AS base

# Prevents Python from writing pyc files.
ENV PYTHONDONTWRITEBYTECODE=1

# Keeps Python from buffering stdout and stderr to avoid situations where
# the application crashes without emitting any logs due to buffering.
ENV PYTHONUNBUFFERED=1

WORKDIR /noteproject

# Download dependencies as a separate step to take advantage of Docker's caching.
# Leverage a cache mount to /root/.cache/pip to speed up subsequent builds.
# Leverage a bind mount to requirements.txt to avoid having to copy them into
# into this layer.
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    python -m pip install --upgrade pip -r requirements.txt

# Copy the source code into the container.
COPY /noteproject .

# Expose the port that the application listens on.
EXPOSE 8000

# runs the application
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "noteproject.wsgi:application"]