# Intentionally using python:3.8-slim (EOL) to demonstrate Trivy catching CVEs.
# Fix: bump to python:3.12-slim to clear the scan and unblock the pipeline.
FROM python:3.8-slim

WORKDIR /app
COPY . .

CMD ["python", "main.py"]
