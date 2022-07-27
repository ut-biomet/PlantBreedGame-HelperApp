FROM rocker/shiny-verse
LABEL maintainer="Julien Diot <juliendiot@ut-biomet.org>"


RUN apt-get update && apt-get install -y \
  curl \
  libgsl-dev

ENV RENV_VERSION 0.14.0
RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"

# install packages dependencies
WORKDIR /breedGameHelpApp
COPY renv.lock renv.lock
COPY renv renv
COPY .Rprofile .Rprofile
RUN R -e 'renv::restore()'

# get app code from source directory
COPY . .

EXPOSE 3838

# run app on container start
CMD ["R", "-e", "shiny::runApp('/breedGameHelpApp', host = '0.0.0.0', port = 3838)"]
