FROM python:latest
WORKDIR /app
ADD requirements.txt /app
ADD app.py /app
RUN pip install -r requirements.txt
ENTRYPOINT ["python"]
CMD ["app.py"]
EXPOSE 8080