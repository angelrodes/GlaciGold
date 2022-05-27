# GLACIGOLD

The GLACIGOLD script simulates the accumulation of cosmogneic isotopes in gold grains in placer deposits in glaciated areas.

*Ángel Rodés, 2022*\
[angelrodes.com](http://www.angelrodes.com/)

## Description of the model

The GLACIGOLD model generates series of apparent exposure ages corresponding to different gold exhumation ages based on given parameter values (water depth, ice depth, and local deglaciation ages). 

The model assumes that the gold is located under a layer of water (river bed) during interglacials and under ice during glaciations. 

Local deglaciation ages are used to calculate glacial and interglacial stages based on the variations of the Oxygen-isotope curve.

![Screenshot at 2022-05-27 10-46-28](https://user-images.githubusercontent.com/53089531/170665070-cb782032-575d-4f74-987c-e3d7f5348f0e.png)


## Input parameters

Input parameters and Apparent Surface Exposure Ages (ASEA) can be changed at the "Input parameters" section in the main script ```GlaciGold_v1.m```.

Just run ```GlaciGold_v1``` in MATLAB or Octave to get the graphical and numerical outputs.

## Climatic references and production rate systematics

The GLACIGOLD model uses the same oxygen-isotope curves, production rate calculations, and accumulation simulations as the NUNAIT model, that is described in Rodés (2021).

**Rodés, Á.** (2021) "The NUNAtak Ice Thinning (NUNAIT) Calculator for Cosmonuclide Elevation Profiles" [*Geosciences* 11, no. 9: 362.](https://www.mdpi.com/2076-3263/11/9/362) doi: 10.3390/geosciences11090362
