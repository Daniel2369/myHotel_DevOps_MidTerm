FROM python:3.9.23

# Set working directory
WORKDIR /app

# Copy project files
COPY . /app

# Install dependencies
RUN pip install fastapi[standard] uvicorn jinja2 python-multipart requests pytest

# Run tests with pytest
RUN pytest

# Expose port (optional but recommended)
EXPOSE 8000

# Run the app
CMD ["uvicorn", "backend:app", "--reload", "--host", "0.0.0.0", "--port", "8000"]
