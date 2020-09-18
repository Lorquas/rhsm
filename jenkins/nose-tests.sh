# needs xorg-x11-server-Xvfb rpm installed
# needs python-rhsm

# "make jenkins" will install these via `pip install -r test-requirements.txt'
#  if it can
#  (either user pip config, or virtualenvs)
# needs python-nose installed
# needs polib installed, http://pypi.python.org/pypi/polib
# probably will need coverage tools installed
# needs mock  (easy_install mock)
# needs PyXML installed
# needs pyflakes insalled
# if we haven't installed/ran subsctiption-manager (or installed it)
#   we need to make /etc/pki/product and /etc/pki/entitlement

echo "sha1:" "${sha1}"

# Decide which package manager to use
which dnf
if [ $? -eq 0 ]; then
    PM=dnf
else
    PM=yum
fi

cd $WORKSPACE

sudo $PM clean expire-cache
sudo $PM builddep -y subscription-manager.spec  # ensure we install any missing rpm deps
virtualenv env --system-site-packages -p python2 || true
source env/bin/activate

make install-pip-requirements
pip install --user -r ./test-requirements.txt

# build/test python-rhsm
if [ -d $WORKSPACE/python-rhsm ]; then
  pushd $WORKSPACE/python-rhsm
fi
PYTHON_RHSM=$(pwd)

# build the c modules
python setup.py build
python setup.py build_ext --inplace

# not using "setup.py nosetests" yet
# since they need a running candlepin
# yeah, kind of ugly...
cp build/lib.linux-*/rhsm/_certificate.so src/rhsm/

pushd $WORKSPACE
export PYTHONPATH="$PYTHON_RHSM"/src

echo
echo "PYTHONPATH=$PYTHONPATH"
echo "PATH=$PATH"
echo

make build
make coverage
