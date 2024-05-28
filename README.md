# PlantBreedGame help tools


This repository contains an R shiny application helping playing the "PlantBreedGame".

For more information about this game, please visit: [PlantBreedGame gitHub repository](https://github.com/timflutre/PlantBreedGame) and:

> Flutre, T., Diot, J., and David, J. (2019). PlantBreedGame: A Serious Game that Puts Students in the Breeder’s Seat. Crop Science. DOI 10.2135/cropsci2019.03.0183le


# How to run

## With docker:

First get the latest docker image:

```
docker pull ghcr.io/ut-biomet/plantbreedgame-helperapp/plantbreedgamehelperapp:latest
```

Then you can run the docker image with for example:

```
docker run --rm -t --name plantbreedgamehelperapp -p 3838:3838 ghcr.io/ut-biomet/plantbreedgame-helperapp/plantbreedgamehelperapp:latest
```

To kill the image use `docker kill plantbreedgamehelperapp`.

You can then access the application at: 127.0.0.1:3838. 

> Note:  
> You can change the listening port by modigying the command with `-p <PORT>:3838`, where `<PORT>` is the port number to listen. You will then be able to access the application at 127.0.0.1:<PORT>.


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
  - For the population "G0", the number of offspring per couple will be set to 1 (this population is homozygote).
  - For the population "G1", only auto-fecundation will be proceeded.
1. Set the total number of offspring to generate.
1. Go to the "Plot" tab to visualize the mating on the `trait1` vs `trait2` graph.
1. Download the crossing table by clicking on the "Download" button.



## Requests 

This tool create the request files for the PlantBreedGame. Two file are created:
the "Plant material request" and "Genotyping request".

1. Select the new generation name (G1, G2 ...)
1. Upload the file downloaded at the "Mating" step
1. You can then download a zip file containing the request for PlantBreedGame.


# For Developpers:

## Development

You need to install ["Nix"](https://nixos.org/) in order to work on this project. 


<details><summary>Install Nix</summary>

For Linux and Windows Subsystem for Linux (WSL), you can use the Determinate Systems Nix installer:

```
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

It is also recommended to install ["direnv"](https://direnv.net/).

```
nix profile install nixpkgs#nix-direnv
mkdir -p $HOME/.config/direnv/
echo 'source $HOME/.nix-profile/share/nix-direnv/direnvrc' > $HOME/.config/direnv/direnvrc
```

You can then have a full developement environment by just doing `cd path/to/breedGame-HelpApp`. (the first time you will need to run `direnv allow`).

</details>

You can then start the application with: 

```
nix run
```

Some other arguments can be passed too for example:

```
nix run . -- --help
nix run . -- --port 3000 --host 0.0.0.0
```

## Maintainance

The [Makefile](./Makefile) contains usefull commands to run some maintainance tasks:
- Build and copy the docker image to the docker deamon : `make dockerImage`
- Build and **push** the docker image to the registry: `make pushImage`

