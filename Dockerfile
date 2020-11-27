# Bruker et base image som inneholder tidyverse-pakkene
FROM rocker/tidyverse

# Installerer nødvendige pakker
RUN R -e "install.packages(c('plumber', 'bysykkel', 'tidymodels', 'lubridate'))"

# copy everything from the current directory into the container
# Kopier alt fra denne mappen til kontaineren
COPY ./ ./

# Åpne port 80 for trafikk
EXPOSE 80

# Kjør plumber.R når kontaineren starter
ENTRYPOINT ["Rscript", "entrypoint.R"]