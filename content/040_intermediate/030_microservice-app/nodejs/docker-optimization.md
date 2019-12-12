---
title: "Docker Optimization"
date: 2018-02-27T20:29:49Z
pre: "<i class='fa fa-question-circle'></i> "
draft: true
---


consider the following Dockerfile:
```
FROM ubuntu:14.04

ENV PRODUCT iridium

RUN apt-get -y update

RUN apt-get -y install \
  git \
  wget \
  python-dev \
  python-virtualenv \
  libffi-dev \
  libssl-dev

WORKDIR /root

RUN wget https://bootstrap.pypa.io/get-pip.py \
  && python get-pip.py

WORKDIR interstella

RUN virtualenv ${PRODUCT}

WORKDIR ${PRODUCT}

RUN bin/pip install --upgrade pip && \
    bin/pip install requests[security]

COPY ./requirements.txt .

RUN bin/pip install -r requirements.txt

COPY ./$PRODUCT.py .

EXPOSE 5000

ENTRYPOINT ["bin/python", "-v", "iridium.py"]
```

This is an example of someone copying the server build commands directly into a Dockerfile.
It certainly works, but it's not efficient.  How can we optimize it?

---

One easy change, and quick win is to swap to a different base image:

```
1 FROM ubuntu:14.04                                                                                  1 FROM debian:stretch-slim
2                                                                                                    2
3 ENV PRODUCT iridium                                                                                3 ENV PRODUCT iridium
4                                                                                                    4
5 RUN apt-get -y update                                                                              5 RUN apt-get -y update
6                                                                                                    6
```
This change reduces the image from 568MB to 388MB. That's a good savings for such a small effort.

But we can do better.

---

The python community provides an official image based in alpine linux. Let's swap to using that as our base:


```
1 FROM debian:stretch-slim                                                                           1 FROM python:2-alpine
2                                                                                                    2
3 ENV PRODUCT iridium                                                                                3 ENV PRODUCT iridium
4                                                                                                    4
5 RUN apt-get -y update                                                                              5 RUN apk -U upgrade
6                                                                                                    6
7 RUN apt-get -y install \                                                                           7 RUN apk add \
8   git \                                                                                            8   git \
9   wget \                                                                                           9   wget \
10   python-dev \                                                                                    10   libffi \
11   python-virtualenv \                                                                             11   py-idna \
                                                                                                    12   py-openssl \
                                                                                                    13   py-cryptography \
12   libffi-dev \                                                                                    14   libffi-dev \
13   libssl-dev                                                                                      15   openssl \
                                                                                                    16   openssl-dev \
                                                                                                    17   py-virtualenv \
                                                                                                    18   gcc
14                                                                                                   19
15 WORKDIR /root                                                                                     20 WORKDIR /root
16                                                                                                   21
17 RUN wget https://bootstrap.pypa.io/get-pip.py \                                                   22 RUN wget https://bootstrap.pypa.io/get-pip.py \
18   && python get-pip.py                                                                            23   && python get-pip.py
19                                                                                                   24
20 WORKDIR interstella                                                                               25 WORKDIR interstella
21                                                                                                   26
22 RUN virtualenv ${PRODUCT}                                                                         27 RUN virtualenv ${PRODUCT} --system-site-packages
23                                                                                                   28
24 WORKDIR ${PRODUCT}                                                                                29 WORKDIR ${PRODUCT}
25                                                                                                   30
26 RUN bin/pip install --upgrade pip && \                                                            31 RUN bin/pip install --upgrade pip && \
27     bin/pip install requests[security]                                                            32     bin/pip install requests
28                                                                                                   33
29 COPY ./requirements.txt .                                                                         34 COPY ./requirements.txt .
30                                                                                                   35
31 RUN bin/pip install -r requirements.txt                                                           36 RUN pip install -r requirements.txt
32                                                                                                   37
33 COPY ./$PRODUCT.py .                                                                              38 COPY ./$PRODUCT.py .
34                                                                                                   39
35 EXPOSE 5000                                                                                       40 EXPOSE 5000
36                                                                                                   41
37 ENTRYPOINT ["bin/python", "-v", "iridium.py"]                                                     42 ENTRYPOINT ["python", "-v", "iridium.py"]
                                                                                                    43

```
This image is down to 300MB.

---

We don't need to download and install pip. Let's just use the OS pip instead. Also,
we don't need to build a virtualenv, We are already containing our dependencies in a docker container.

```
15   openssl \                                                                                       15   openssl \
16   openssl-dev \                                                                                   16   openssl-dev \
17   py-virtualenv \                                                                                 17   py-virtualenv \
18   gcc                                                                                             18   gcc
19                                                                                                   19
20 WORKDIR /root
21
22 RUN wget https://bootstrap.pypa.io/get-pip.py \
23   && python get-pip.py
24
25 WORKDIR interstella
26
27 RUN virtualenv ${PRODUCT} --system-site-packages
28
29 WORKDIR ${PRODUCT}                                                                                20 WORKDIR ${PRODUCT}
30
31 RUN bin/pip install --upgrade pip && \
32     bin/pip install requests
33                                                                                                   21
34 COPY ./requirements.txt .                                                                         22 COPY ./requirements.txt .
35                                                                                                   23
36 RUN pip install -r requirements.txt                                                               24 RUN pip install --no-cache-dir -r requirements.txt
37                                                                                                   25
38 COPY ./$PRODUCT.py .                                                                              26 COPY ./$PRODUCT.py .
39                                                                                                   27
40 EXPOSE 5000                                                                                       28 EXPOSE 5000
41                                                                                                   29
```
By removing those unneeded commands, we have reduced our image to 275MB.

---

Next, let's combine our RUN statements as much as possible, and delete packages once they are no longer needed.
```
1 FROM python:2-alpine                                                                               1 FROM python:2-alpine
2                                                                                                    2
3 ENV PRODUCT iridium                                                                                3 ENV PRODUCT iridium
4
5 RUN apk -U upgrade
6
7 RUN apk add \
8   git \
9   wget \
10   libffi \
11   py-idna \
12   py-openssl \
13   py-cryptography \
14   libffi-dev \
15   openssl \
16   openssl-dev \
17   py-virtualenv \
18   gcc
19                                                                                                    4
20 WORKDIR ${PRODUCT}                                                                                 5 WORKDIR ${PRODUCT}
21                                                                                                    6
22 COPY ./requirements.txt .                                                                          7 COPY ./requirements.txt .
23                                                                                                    8
                                                                                                     9 RUN apk -U --no-cache upgrade && \
                                                                                                    10     apk --no-cache add \
                                                                                                    11     git \
                                                                                                    12     wget \
                                                                                                    13     libffi \
                                                                                                    14     py-idna \
                                                                                                    15     py-openssl \
                                                                                                    16     py-cryptography \
                                                                                                    17     libffi-dev \
                                                                                                    18     openssl \
                                                                                                    19     openssl-dev \
                                                                                                    20     py-virtualenv \
                                                                                                    21     gcc && \
24 RUN pip install --no-cache-dir -r requirements.txt                                                22     pip install --no-cache-dir -r requirements.txt && \
                                                                                                    23     apk --no-cache del \
                                                                                                    24     wget \
                                                                                                    25     git \
                                                                                                    26     libffi-dev \
                                                                                                    27     openssl-dev \
                                                                                                    28     py-virtualenv \
                                                                                                    29     py-pip \
                                                                                                    30     gcc
25                                                                                                   31
26 COPY ./$PRODUCT.py .                                                                              32 COPY ./$PRODUCT.py .
27                                                                                                   33
28 EXPOSE 5000                                                                                       34 EXPOSE 5000
29                                                                                                   35
```
With this, we are down to 162MB

---

What if we swap base images again, this time to stock alpine, rather than the python image?
```
FROM python:2-alpine                                                                                 FROM alpine:3.7

ENV PRODUCT iridium                                                                                  ENV PRODUCT iridium

WORKDIR ${PRODUCT}                                                                                   WORKDIR ${PRODUCT}

COPY ./requirements.txt .                                                                            COPY ./requirements.txt .

RUN apk -U --no-cache upgrade && \                                                                   RUN apk -U upgrade && \
    apk --no-cache add \                                                                                 apk add \
    git \                                                                                                git \
    wget \                                                                                               wget \
    libffi \                                                                                             python2 \
                                                                                                         py-pip \
    py-idna \                                                                                            py-idna \
    py-openssl \                                                                                         py-openssl \
    py-cryptography \                                                                                    py-cryptography \
    libffi-dev \                                                                                         libffi-dev \
    openssl \
    openssl-dev \                                                                                        openssl-dev \
    py-virtualenv \                                                                                      py-virtualenv \
    gcc && \                                                                                             gcc && \
    pip install --no-cache-dir -r requirements.txt && \                                                  pip install --no-cache-dir -r requirements.txt && \
    apk --no-cache del \                                                                                 apk del \
    wget \                                                                                               wget \
    git \                                                                                                git \
    libffi-dev \                                                                                         libffi-dev \
    openssl-dev \                                                                                        openssl-dev \
    py-virtualenv \                                                                                      py-virtualenv \
    py-pip \                                                                                             py-pip \
    gcc                                                                                                  gcc && \
                                                                                                         rm -rvf /var/cache/apk/* && \
                                                                                                         find /usr/ -name *.pyc -exec rm -vf {} \;

COPY ./$PRODUCT.py .                                                                                 COPY ./$PRODUCT.py .

EXPOSE 5000                                                                                          EXPOSE 5000
```
With this change, we are down to 72.8MB -- a huge improvement over our original image size of 568MB!
