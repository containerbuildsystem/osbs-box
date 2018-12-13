FROM python:3.7

ADD https://raw.githubusercontent.com/fedora-infra/bodhi/develop/bodhi/server/scripts/skopeo_lite.py /skopeo_lite.py
RUN pip3 install click requests six

ENTRYPOINT ["python3", "/skopeo_lite.py"]
CMD []
