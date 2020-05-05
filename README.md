# Various configurations and scripts for the most optimal<sup>TM</sup> working environment.
### Vim stuff
- Contains a `.vimrc` and a `.vim/` folder. Copy to `~/`. Bask in vim's glory.

### GBDX
- Contains `.gbdx-config`, and `set_gbdx_credentials.py`. Add the correct GBDX password to `.gbdx-config` and copy both of these files to `~/`. Run `set_gbdx_credentials.py`.

### rnd.ml.common
- Contains the `requirements.txt` file (probably out of date... update this next time you create an AWS instance). 
- Make sure you first do:
```
pip install setuptools-scm; pip install numpy
```
- Then, clone and install the ml common repo:
```
git clone https://gitscm.mda.ca/rnd/lib/ml/common.git; cd common; git branch ddobre-develop; pip install .; cd ..

```

