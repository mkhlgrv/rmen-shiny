FROM rocker/shiny:4.2.0
LABEL maintainer="mkhlgrv@gmail.com"
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    && rm -rf /var/lib/apt/lists/* \
    && sudo apt-get update -y \
    && sudo apt-get install -y r-cran-xml
RUN R -e 'install.packages("shiny")'
RUN R -e 'install.packages("ggplot2")'
RUN R -e 'install.packages("devtools")'
RUN R -e 'install.packages("DT")'
RUN R -e "devtools::install_github(c('mkhlgrv/rmedb'))"
RUN R -e "devtools::install_github(c('mkhlgrv/rmen'))"


ENV _R_SHLIB_STRIP_=true
ENV SHINY_LOG_STDERR=1

COPY ./app/* /srv/shiny-server/
USER shiny
EXPOSE 3838
CMD ["/usr/bin/shiny-server"]
