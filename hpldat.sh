#!/bin/bash

echo "Ryan's fancy script to scale HPL.dat on the fly"

export scale=$(grep -Eowi 'weak|strong' <<< "$*")
export nodes=$(grep -Eowi 'single|many' <<< "$*")
export ns=$(grep -Eiw Ns=* <<< "$*")
export ns=$(echo $ns | sed 's/^\(Ns=\)*//')

if [[ "$nodes" == "many" ]]; then
  export core=$(grep -Ewi cores= <<< "$*")
  core=$(echo $core | sed 's/^\(cores=\)*//')
fi

echo "Please input HPL build folder or use variable [$HPLPATH]:"
read hplpathread
if [[ -z "$hplpathread" ]]; then
  export hplpathvar=$HPLPATH
elif [[ ! -z "$hplpathread" ]]; then
  export hplpathvar=$hplpathread
fi
echo "Please input folder to use for binaries or use variable [$HPLBINPATH]:"
read hplbinpathread
if [[ -z "$hplbinpathread" ]]; then
  export hplbinpathvar=$HPLBINPATH
elif [[ ! -z "$hplbinpathread" ]]; then
  export hplbinpathvar=$hplbinpathread
fi

cd $hplpathvar/..
hplfolder=$(ls | grep -i intel)
cp -r $hplfolder $hplbinpathvar
cd $hplbinpathvar/
if [[ ! -d "$nodes" ]]; then
  mkdir $nodes
fi
if [[ ! -d "$nodes/$scale" ]]; then
  mkdir $nodes/$scale
fi
if [[ ! -d "$nodes/$scale/$core" ]]; then
  mkdir $nodes/$scale/$core
fi
mv $hplfolder $nodes/$scale/$core
