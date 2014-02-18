Fran�ois le 16/02/2014
======================

- [x] V�rifier s'il n'y a pas un pb dans RBiips.R, ligne 340:
rw$d <<- sum(sapply(rw$dim, FUN=sum))
Il me semble que FUN devrait prendre le produit des dimensions plutot que la somme.
- [ ] biips renvoie une erreur lorsque l'on essaie d'ajouter une fonction qui existe d�j�. Ce serait bien de renvoyer juste un warning, et si possible de red�finir la fonction (la fonction matlab peut avoir changer) - pas urgent ajouter message indiquant qu'il faut fermer matlab dans biips_add_function pour pouvoir red�finir la fonction

Adrien le 11/02/2014 :
======================
- [ ] exemples avec publish matlab (avec ou sans le package de Peyr� ? plut�t sans...)
- [ ] trouver une solution similaire pour R (voir package knitr)
- [ ] am�liorer message d'erreur "Subset y[1] out of range [1:100] in Compiler::setConstantMask.
- [ ] �viter crash matlab
- [ ] v�rifier : si sample_data=false -> ne pas compiler bloc data
- [ ] tester octave sous linux, windows et mac
- [ ] Pb de headers avec octave et gcc 4.8
- [ ] regarder warning dans test_internals.m

Fran�ois le 11/02/2014 :
========================
J'ai une erreur lorsque j'essaye de rentrer les donn�es y dans la structure data dans hmm_1d_lin: (jusqu'� pr�sent je les �chantillonais)

L'erreur se produit dans inter_biips compile_model avec l'erreur suivante:
* Compiling data graph
  Declaring variables
  Resolving undeclared variables
  Allocating nodes
LOGIC ERROR: Subset y[1] out of range [1:100] in Compiler::setConstantMask.

Par ailleurs, cela crashe toujours matlab. Est-il possible d'�viter de fermer Matlab s'il y a un pb avec le fichier bugs?

EXEMPLE:
%%% Model parameters
t_max = 100;
mean_x_init = 0;
prec_x_init = 1;
prec_x = 1;
prec_y = 10;
y = randn(t_max, 1);
data = struct('y', y, 't_max', t_max, 'prec_x_init', prec_x_init,...
    'prec_x', prec_x,  'prec_y', prec_y, 'mean_x_init', mean_x_init);
%%% Start BiiPS console
biips_init;
%%% Compile BUGS model and sample data
model = 'hmm_1d_lin.bug'; % BUGS model filename
sample_data = true; % Boolean
[model_id, data] = biips_model(model, data, 'sample_data', sample_data); % Create biips model and sample data

Fran�ois le 09/02/2014 :
========================
A propos des conditionnelles pour le filtering:

Cela n'a pas l'air �vident de retrouver les conditionnelles du filtering 
avec biips_get_nodes. Serait-il possible que la sortie de 
'get_filter_monitors' renvoie cette information? Par exemple, pour la 
variable x, avoir un champs suppl�mentaire 'conditionals' qui est une 
cellule de m�me taille que x, avec pour chaque entr�e une cellule 
donnant les noms des variables stochastiques par rapport auuxquelles 
l'on conditionne.
Par exemple pour un x de longueur 3:
x.conditionals = { { 'y[1]' }, {'y[1]', 'y[2]'}, {'y[1]', 'y[2]', 'y[3]'} }

Cela te paraitrait faisable? Une autre facon de faire, serait de 
retraiter la sortie de biips_get_nodes, mais cela me semble moins rigoureux.

Si j'ai l'ordre des noeuds, et l'indice m'indiquant s'ils sont 
stochastiques et observ�s, la r�gle suivante est-elle valide dans tous 
les cas:
Pour un noeud stochastique non observ�, conditionner par rapport �
1. toutes les variables stochastiques observ�e le pr�c�dant
2. la premi�re variable stochastique observ�e suivante
3. ajouter les variables stochastiques observ�es suivantes, jusqu'� ce 
qu'apparaisse un noeud stochastique non observ�
Par exemple (x sto non observ�, y sto observ�, z d�terministe)
x[1], y[1], x[2], x[3], y[2], y[3], z[1], y[4], x[4]
x[2] est conditionn� � y[1], y[2], y[3], y[4]
si c'est aussi simple que cela, je peux le r�cup�rer � partir de 
biips_get_nodes

A faire :
- [ ] v�rifier que ces conditions sont remplies
- [ ] retourner les conditionnelles sous la forme pr�sent�e plus haut


Fran�ois le 07/02/2014 :
========================
Modification de parsevar pour inclure v�rification des types, et arguments admissibles pour les entr�es optionnelles.
D�but du codage des fonctions init_pmmh et biips_pmmh_update

ERREURS avec inter_biips: (lancer hmm_1d_lin_param.m)
1. 'change_data': quels sont les types des entr�es de cette fonction?. J'ai essay� 
inter_biips('change_data', console, pn_param(i).name, ...
            pn_param(i).lower, pn_param(i).upper, inits{i}, true)
o� pn_param est la sortie de parse_varname, mais j'ai un message m'indiquant que le deuxi�me argument doit etre 'cell'
2. 'sample_data': m�me question
samp = inter_biips('sample_data', console, pn_param(i).name,...
                pn_param(i).lower, pn_param(i).upper, inits_rng_seed)
me renvoit un message comme quoi le 3e et 4e arguments doivent etre double. Mais si les dimensions de la variable ne sont pas indiqu�e, parse_varname renvoit une cell vide.
* M�me en indiquant les indices de la variable, la fonction crashe, cette fois-ci sans message d'erreur.

Questions concernant inter_biips et biips:
* Lorsque l'on rentre dans la structure data les valeurs de x_true et y (pour hmm_1d_lin), on a une erreur � la compilation - ne peut-on pas �viter cela? 
* Message de inter_biips indiquant que seed doit etre double: ce n'est pas suppos� etre un entier? La classe uint32 ne serait pas plus appropri�e?
* Dans la fonction init_pmmh de Rbiips, pourquoi mettre la valeur latent_variables � false quand on les monitor?
* dans init.pmmh de rbiips, je ne comprends pas ce que fait object$.rw.init(sample)
* idem pour object$.rw.step(rw.step.values) et autres dans d'autres fonction pmmh


Adrien le 4/2/2014 :
====================
A faire dans Matbiips :
- [ ] modifier lecture des champs de structure : utiliser getfield
- [x] harmonisation des noms de variables
- [x] traitement des sorties MCMC dans biips_summary et biips_density
    Rq: si out.varname a les champs f, s ou b -> traitement SMC sur les sous-champs values et weights
    sinon -> traitement MCMC : pas de sous-champs values, les poids sont tous �gaux
- [ ] biips_pimh_samples : am�liorer stockage des �chantillons. cf. switch/case dans le code
    Rq: L'appel de squeeze modifie les dimensions
- [ ] cr�er exemple court et l'inclure dans matbiips
- [x] supprimer biips_load_module : l'int�grer dans biips_init
- [ ] v�rifier biips_get_nodes : peut-on conna�tre les conditionnelles ? renvoie-t-elle les samplers ?
- [ ] renommer make_progress_bar en progress_bar
- [x] mettre isoctave dans private
- [ ] revoir et ajouter tests matbiips et ne pas les int�grer dans l'archive
- [ ] ajouter un README.md
- [ ] commenter inter_biips en doxygen et g�n�rer pdf

Autres t�ches :
- [ ] tester l'install de RBiips sous linux
- [ ] copier binaires depuis CI sur un r�pertoire accessible (Dropbox ?)
- [ ] harmonisation Licence, auteurs : Fichiers COPYING et README � la racine + ent�tes de fichiers communes avec auteurs, Inria, date etc.


Fran�ois le 3/2/2014 :
======================
J'ai fini le PIMH et l'exemple hmm 1D lin�aire. J'ai modifi� les 
fonctions biips_density et biips_summary de fa�on a ce qu'elles prennent 
aussi en entree la sortie d'un algorithme MCMC. Dans l'id�al, il 
faudrait aussi faire la m�me chose pour la fonction biips_diagnosis, 
mais c'est moins evident de savoir quel critere utiliser pour le MCMC 
(en plus, plusieurs criteres utilisent les sorties de plusieurs 
chaines). Je pense que c'est ok de laisser comme cela.
Il faut encore rajouter des en-tetes � certaines fonctions, et quelques 
checks sur les entrees.
J'ai essay� d'harmoniser les notations au maximum.
Je ne pense pas pouvoir retravailler dessus cette semaine, j'attaquerai 
le PMMH la semaine prochaine.

A Faire:
- [ ] Commenter un peu inter_biips, au moins une description succincte des entrees/sorties et ce que fait chaque fonction (si le nom n'est pas assez explicite).

Marc le 3/2/2014 :
====================
> C'est tout de m�me g�nant que Matlab se ferme � la suite d'une exception.
> Marc, est-ce que tu penses que c'est normal ?

Je sais que Matlab a un systeme a lui pour gerer les exceptions (help
catch), mais je ne sais pas si il peut rattraper une exception issue d'un
mexfile. Ca peut etre genant que matlab ferme surtout si tu n'as pas de
message d'erreur, en effet. Apres definir quel doit etre le bon
conportement dans ce cas, n'est pas evidemment. Ce qui rassure au moins
c'est que le programme plante au lieu de faire n'importe quoi.
Apparement Adrien a pu localiser d'ou venait l'erreur, c'est donc que
les infos d'erreur etaient suffisantes pour regler le probleme.

Adrien le 30/1/2014 :
======================
> J'ai un soucis avec le calcul des quantiles dans matbiips. Il doit y 
> avoir un probl�me avec la function cpp, car
> inter_biips('weighted_quantiles', values, weights, probas) ne renvoit 
> pas les bonnes valeurs.

En fait, il faut juste multiplier les poids par N, c.f. stat.particles dans RBiips.
Je ne comprends plus pourquoi mais �a marche... s�rement un probl�me num�rique !?
Je suppose que l'algo renormalise tout seul. J'ai corrig� summary.m.

- [ ] Je vais voir s'il ne vaut pas mieux modifier dans Biips (c++)

Adrien le 27/01/2014 :
======================
A faire:
- [x] Changer les noms de fonctions dans Rbiips : 
	- update.pimh -> pimh.update
	- update.pmmh -> pmmh.update
- [x] Am�liorer l'install de RBiips:

    env BIIPS_INCLUDE=path/to/install/usr/include/biips/ BIIPS_LIB=/path/to/install/lib/ARCH R CMD INSTALL RBiips_0.8.1.tar.gz

ARCH directory depends on the machine where biips deb package was installed.

Note: the environment variables should not be needed if the biips deb package was installed as root.

...or type from R console:

    install.packages('path/to/RBiips_X.X.X.tar.gz')

FIXME: error when compiling RBiips

    g++: error: /usr/lib/libBiipsCompiler.a: Aucun fichier ou dossier de ce type
    g++: error: /usr/lib/libBiipsBase.a: Aucun fichier ou dossier de ce type
    g++: error: /usr/lib/libBiipsCore.a: Aucun fichier ou dossier de ce type

- [x] Can we change the Makevars.in so that the paths are correct, and you don't need to use the environment variables ?

Adrien, le 21/01/2014 :
=======================
* Fran�ois a commenc� l'article pour J. of Stat. Software
- [ ] On a converg� sur un PMMH adaptatif: � modifier dans R, puis � cr�er dans Matlab
- [x] Je suis en train de passer la doc de rbiips au format roxygen. Donc on va supprimer les fichiers Rd.
- [x] Marc tente de r�soudre un probl�me de taille de disque sur Windows CI pour installer Matlab
- [ ] RBiips sous Windows CI: commandes de build � ajouter (Marc)

Adrien, le 05/01/2014 :
=======================
Erreurs des demos corrig�es : les fichiers .bug utilisaient '_' au lieu de '.' donc j'ai corrig� les noms de variables dans les scripts R

A faire :
----------
- [ ] La comparaison avec Kalman dans demo(hmm_1d_lin) utilise un package obsol�te
    package 'sspir' is not available (for R version 3.0.2)

- [ ] Note : pimh et pmmh ont besoin du package rjags (sorties de type mcarray). Il faut trouver une alternative � cette d�pendance : r�implementer les op�rations sur mcarray dans RBiips ?

- [x] Corriger le formatage du warning:
    Unused variables in data:t.maxmean.x.initprec.x.initprec.xprec.y

- [ ] Am�liorer les r�sultats des exemples pmmh

Fran�ois, le 04/01/2014:
=======================
* Test de Rbiips, sous Windows 7 64 bits, avec R version 3.0.2.
Installation ok. 
Test des demos (je n'ai pas la version 3.0 de jags install�e et passe les comparaisons avec jags):
 - erreur en lan�ant demo(hmm_1d_lin)
------------

> biips <- biips.model(model, data=data, sample.data=!run.jags)
* Parsing model in: C:/Users/fcaron/Documents/R/win-library/3.0/RBiips/extdata/hmm_1d_lin.bug
* Compiling data graph
  Declaring variables
RUNTIME ERROR: Compilation error on line 1.
Unable to calculate dimensions of node y
Error in biips.model(model, data = data, sample.data = !run.jags) : 
  Failed to compile model.
In addition: Warning message:
In biips.model(model, data = data, sample.data = !run.jags) :
  Unused variables in data:t.maxmean.x.initprec.x.initprec.xprec.y

-------------
 - erreur en lan�ant demo(hmm_1d_lin)
------------------
> biips <- biips.model(model, data)
* Parsing model in: C:/Users/fcaron/Documents/R/win-library/3.0/RBiips/extdata/hmm_1d_nonlin.bug
* Compiling model graph
  Declaring variables
RUNTIME ERROR: Compilation error on line 1.
Unable to calculate dimensions of node x_true
Error in biips.model(model, data) : Failed to compile model.
In addition: Warning message:
In biips.model(model, data) :
  Unused variables in data:t.maxmean.x.initprec.x.initprec.xprec.y
------------------
 - demo(hmm_1d_lin_param) ok
 - erreur avec demo(hmm_1d_nonlin_param)  (toujours pb de dimension), etc...

* Test de matbiips sous windows 7 64 bit et Matlab R2013b
Utilisation ok des fonctions tuto hmm_4d_lin et hmm_4d_nonlin

Adrien, le 29/12/2013:
=======================
Ajouts dans new_release:
* matbiips: archive zip avec mexfiles pour Linux 64bit, Windows 64bit, Mac 64bit
* RBiips: packages binaires R pour Windows 64bit, Windows 32bit et Mac
A tester... Voir mise � jour de install.md

A faire:
- [ ] Configurer l'esclave CI Windows 7
- [ ] R�organiser les tests matbiips
- [ ] Permettre compilation multi-architecture de RBiips sous Windows

Adrien, le 17/12/2013:
=======================
J'ai peupl� le dossier new_release avec les �l�ments qu'on doit mettre � jour pour la nouvelle "lib�ration".
Je n'ai pas apport� de modifications pour l'instant. Je laisse la main.

doc :
-----
biips-spec, biips-technical-report et notePMMH sont l� pour �ventuellement �tre r�utilis�s dans une doc mieux rationalis�e. Un d�but est dans biips-user-manual qui s'inspire de la doc de JAGS.
Il y a �galement un bout de doc dans matbbips/doc qu'il faudra compl�ter ou int�grer quelque part.

examples :
----------
Il y a un dossier par mod�le. Les scripts R (initialement int�gr�s au package RBiips) sont � mettre � jour ainsi que les .bug pour qu'ils soient compatibles matbiips.

Il y a aussi un dossier partag� Rbiips (pas dans new_release) avec des exemples.

Pierrick, le 17/12/2013:
========================

priorit�s :
- [x] toutes plateformes version actuelle
- [ ] exemples sous R et Matlab (sauf pmmh pimh sous matlab)
- [ ] dossier exemples dans le dropbox. Sous dossier par mod�le (R,*.m, bug, *.pdf).
- [ ] RD = latex version R
- [ ] doc
- [ ] nettoyer
- [ ] refaire tests pimh et pmmh dans R


