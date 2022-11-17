# PlantBreedGame help tools


This repository contains an R shiny application helping playing the "PlantBreedGame".

For more information about this game, please visit: [PlantBreedGame gitHub repository](https://github.com/timflutre/PlantBreedGame) and:

> Flutre, T., Diot, J., and David, J. (2019). PlantBreedGame: A Serious Game that Puts Students in the Breeder’s Seat. Crop Science. DOI 10.2135/cropsci2019.03.0183le

# Installation on a Shiny-server

```sh
# get source code of the app
git clone https://github.com/ut-biomet/PlantBreedGame-HelperApp.git

# install R packages dependencies
cd PlantBreedGame-HelperApp
R -e 'renv::restore()'
# because of R-Shiny, we need to isolate the renv libraries, see: https://community.rstudio.com/t/shiny-server-renv/71879/2
R -e 'renv::isolate()'

# copy the application in Shiny-server's directory
cd ~
cp PlantBreedGame-HelperApp /srv/shiny-server/PlantBreedGame-HelperApp

# # [optional] instead of copying the app in /srv/shiny-server, one can create
# # symbolic links. By this way, the server can have several instances of the app:
# ln -s /home/<user>/PlantBreedGame-HelperApp /srv/shiny-server/PlantBreedGame-HelperApp-1
# ln -s /home/<user>/PlantBreedGame-HelperApp /srv/shiny-server/PlantBreedGame-HelperApp-2
# ln -s /home/<user>/PlantBreedGame-HelperApp /srv/shiny-server/PlantBreedGame-HelperApp-3
```


# App documentation:

## Marker effect estimation menu

This menu allow to estimate the markers effect for the phenotypic traits.

1. Upload the genotypic and phenotypic data created from the game.
1. Select the method to use to estimate the markers effects:
  a. GBLUP method: see [`mixed.solve` documentation](https://www.rdocumentation.org/packages/rrBLUP/versions/4.6.1/topics/mixed.solve)
  a. glmnet (ridge, lasso, elastic-net): see [`cv.glmnet` documentation](https://www.rdocumentation.org/packages/glmnet/versions/4.0-2/topics/cv.glmnet)
  The marker estimation process will first estimate the genetic values of the individuals using a linear mixed model with the individuals as random variable and `year` and `trait3` as fixed effects.
  Then the marker effect estimation for `trait1` and `trait2` will be done with the selected method. Finally the marker effect estimation for `trait3` will be done by a lasso regression.
1. Have a look on the results. You can sort table according to the columns values.
1. Download the markers effects as `.csv` file by clicking on the `Download` button below the table. This file will be necessary to use the other menus.




## Data-visualisation menu

1. Upload the genotypic data created from the game.
1. Upload the the file downloaded at the "Marker effect estimation menu"
1. You can visualize the phenotypic estimation for trait 1 and 2 on the left plot colored by the estimated value of the trait 3. 
1. You can visualize the same results as a table on the right.



## Selection and mating menu

1. Upload the genotypic data created from the game.
1. Upload the the file downloaded at the "Marker effect estimation menu"

### Parent selection tab

There are several way to select the parents. All of these method can be used at the same time.

In order to clear your selection (remove all individuals from your selection), you can click on the `Clear` button. 

> Optional:  
> Once you you have selected all your individual, you can download this list by clicking on the `Download` button.

#### Manual selection:

1. In "Table" tab: Click on the line of the table corresponding to the individual you want to select in order to select them.
1. Go to the "Plot " tab to visualise the selected individuals on a `est_trait1` vs `est_trait2` plot.


#### Automatic selection:

The tool can also select automatically some individuals by clicking on the 
`Select Individuals` button:

First you can define you selection criterion: 
  - `trait1`: estimated value for trait 1
  - `trait2`: estimated value for trait 2
  - `trait3`: estimated value for trait 3
  - `trait1 x trait2`: product of the estimated value for trait 1 by trait 2


The tool will **create `N cluster` groups of individuals** using their genetic
values and select from the **`nTop`** overall best individuals (individuals with the 
highest values for the selection criterion) **`nTopEach`** individuals from each 
of the **`Top Cluster`** best clusters.

This selection will be added to the previous one. By this way you can select 
some individuals good according to different selection criterion at the same time.

For example selection the 5 best individuals for `trait1` togethers with 
the 5 best individuals for `trait2`.


### Mating tab

Once you have selected some individuals, you can automatically mate them.

1. Select the method to use:
  a. `round-robin`: each individual will be mate with the next one in the table 
  in the "Parent Selection tab". This method will generate "number of selected individuals" couples.
  a. `max-distance`: calculate the genetic distance between all the selected individuals. Then mate the two individuals that have the highest genetic distance, and replete without considering the already mated individuals until all individuals are mated.
  a. `all-combinations`: mated all the individuals together.
1. You can select `Remove D x D` to avoid crossing non resistant individuals together.
1. Select the allocation method:
  a. `equal`: all the couple will generate the same number of offspring (if possible, if not some couple will generate one more offspring)
  a. `weighted`: some couples will generate more offspring according to their mean predicted value for `Trait`.
1. Specify the current population.
  - For the population "F0", the number of offspring per couple will be set to 1 (this population is homozygote).
  - For the population "F1", only auto-fecundation will be proceeded.
1. Set the total number of offspring to generate.
1. Go to the "Plot" tab to visualize the mating on the `trait1` vs `trait2` graph.
1. Download the crossing table by clicking on the "Download" button.



## Requests 

This tool create the request files for the PlantBreedGame. Two file are created:
the "Plant material request" and "Genotyping request".

1. Select the new generation name (F1, F2 ...)
1. Upload the file downloaded at the "Mating" step
1. You can then download a zip file containing the request for PlantBreedGame.
