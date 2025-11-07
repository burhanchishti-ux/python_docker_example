# syntax=docker/dockerfile:1

# Use a stable Python version that is fully supported by PyO3 and dependencies like Pydantic and Watchfiles.
ARG PYTHON_VERSION=3.13.0
FROM python:${PYTHON_VERSION}-slim as base

# Prevent Python from writing .pyc files and buffering stdout.
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory
WORKDIR /app

# Create a non-privileged user for security
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser

# Install required system dependencies for building Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    rustc \
    cargo \
    pkg-config \
    libffi-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip, setuptools, and wheel before installing dependencies
# Using cache mount for faster rebuilds when dependencies change
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=requirements.txt,target=requirements.txt \
    pip install --upgrade pip setuptools wheel \
    && python -m pip install -r requirements.txt

# Copy project files into the container
COPY . .

# Switch to the non-root user
USER appuser

# Expose the FastAPI default port
EXPOSE 8000

# Run the FastAPI app with Uvicorn
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8001"]
