Biips
=============================================================================

- Version:       0.11.0
- Last modified: 2017-01-31
- Maintainer:    [Adrien Todeschini](http://adrien.tspace.fr) <adrien.todeschini@gmail.com>
- License:       GPL-3
- Website:       <https://biips.github.io>

Biips is a general software for Bayesian inference with interacting particle systems, a.k.a. sequential Monte Carlo (SMC) methods.
It aims at popularizing the use of these methods to non-statistician researchers and students, thanks to its automated "black box" inference engine.
It borrows from the BUGS/JAGS software, widely used in Bayesian statistics, the statistical modeling with graphical models and the language associated with their descriptions.

Context
-----------------------------------------------------------------------------
Bayesian inference consists in approximating an unknown parameter dependent 
conditional probability law given a set of observations. A large number of 
problems, _e.g._ non-supervised classification, filtering, _etc._, can be 
addressed having as basis the aforementioned formulation. The underlying 
probability law, while not calculable in analytical manner for the general case, 
can be approximated by using Monte Carlo Markov Chain (MCMC) methods. These 
methods are popular for bayesian inference thanks to BUGS software and the 
WinBUGS graphical interface.

Emerged as a result of recent research studies, interacting particle based 
algorithms – a.k.a. Sequential Monte Carlo (SMC) methods in which the most 
common implementation is the particle filter – proved to have superior 
performance when compared to classical MCMC approaches. What is more, 
interacting particle algorithms are well adapted for dynamic estimation problems 
as encountered, for example, in filtering, tracking or classification problems. 
They do not require burn in convergence time and include calculation of the 
normalizing constant.

Features
-----------------------------------------------------------------------------
- BUGS language compiler adapted from JAGS
- Black-box inference engine with:
    - SMC/particle algorithms for filtering and smoothing
    - Static parameter estimation using particle MCMC
    - Automatic choice of the proposal samplers
- Core developped in C++
- R interface: Rbiips
- Matlab/Octave interface: Matbiips
- Easy language extensions with custom R and Matlab functions
- Multi-platform: Linux, Windows, Mac OSX
- Free and open source (GPL)

Roadmap
-----------------------------------------------------------------------------
- Code optimization
- Parallelization
- Particle Gibbs algorithm

Contact
-----------------------------------------------------------------------------
To contact us with non-public matters, please write to <adrien.todeschini@gmail.com>.
Otherwise you can use the discusssion forum.

Getting Help
-----------------------------------------------------------------------------
The [GitHub issues](https://github.com/biips/biips/issues) can be used for any question or feedback 
about Biips.
This is the best place for getting help.

Development
-----------------------------------------------------------------------------
The core software libraries are written in C++.
The Rbiips R package allows running Biips from the R statistical software and 
provides posterior analysis and plotting functions.
The Matbiips toolbox provides similar capabilities for Matlab/Octave.

The Biips source code is hosted on [GitHub](https://github.com/biips/biips).

License
-----------------------------------------------------------------------------
Biips is licensed under the GPL-3 License. You may freely modify and 
redistribute it under certain conditions (see the file COPYING.txt for details).

The source code is hosted on [GitHub](https://github.com/biips/biips).

Authors
-----------------------------------------------------------------------------
Biips code is Copyright (C) Inria, 2012-2017.

Authors:

- [Adrien Todeschini](http://adrien.tspace.fr) (main developer)
- [Francois Caron](http://www.stats.ox.ac.uk/~caron/)
- Marc Fuentes

Biips code is adapted from:

- [JAGS](http://mcmc-jags.sourceforge.net/), Copyright (C) Martyn Plummer, 
2002-2010
- [SMCTC](http://www2.warwick.ac.uk/fac/sci/statistics/staff/academic-research/johansen/smctc/), 
Copyright (C) Adam M. Johansen, 2008-2009

Additional information regarding adapted open source software is included in the 
file `NOTICES.txt`.

Thanks
-----------------------------------------------------------------------------
- [ALEA project-team](http://alea.bordeaux.inria.fr) at 
[Inria Bordeaux](http://www.inria.fr/centre/bordeaux)
- [Pierre Del Moral](http://web.maths.unsw.edu.au/~peterdel-moral/)
- [Pierrick Legrand](http://www.sm.u-bordeaux2.fr/~legrand/)
- [Timothée Del Moral](http://rubis3.blogspot.fr/) (Biips logo design)

