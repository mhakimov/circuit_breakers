FROM python:3.11-slim

# Install dependencies
RUN pip install flask gunicorn

# Copy app code
WORKDIR /app
COPY flaky_service.py /app

# Run with gunicorn for production
CMD ["gunicorn", "-b", "0.0.0.0:5000", "app:app"]
