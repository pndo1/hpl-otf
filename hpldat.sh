#!/bin/bash

echo "Ryan's fancy script to scale HPL.dat on the fly"

create_hpl () {
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
}

export scale=$(grep -Eowi 'weak|strong' <<< "$*")
export nodes=$(grep -Eowi 'single|many' <<< "$*")
export ns=$(grep -Eiw Ns=* <<< "$*")
export ns=$(echo $ns | sed 's/^\(Ns=\)*//')

if [[ "$nodes" == "many" ]]; then
  export coreset=$(grep -Ewi cores= <<< "$*")
  coreset=$(echo $core | sed 's/^\(cores=\)*//')
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

if [[ "$nodes" == "single" ]]; then
  export cores='1 2 4 6 12 24 48'
fi
for core in $cores; do
  create_hpl
  cd $nodes/$scale/$core
  if [[ "$core" == "1" ]]; then
    sed -i '9s/.*/1/' HPL.dat
    sed -i '10s/.*/1/' HPL.dat
  elif [[ "$core" == "2" ]]; then
    sed -i '9s/.*/2/' HPL.dat
    sed -i '10s/.*/1/' HPL.dat
  elif [[ "$core" == "4" ]]; then
    sed -i '9s/.*/2/' HPL.dat
    sed -i '10s/.*/2/' HPL.dat
  elif [[ "$core" == "6" ]]; then
    sed -i '9s/.*/3/' HPL.dat
    sed -i '10s/.*/2/' HPL.dat
  elif [[ "$core" == "12" ]]; then
    sed -i '9s/.*/4/' HPL.dat
    sed -i '10s/.*/3/' HPL.dat
  elif [[ "$core" == "24" ]]; then
    sed -i '9s/.*/6/' HPL.dat
    sed -i '10s/.*/4/' HPL.dat
  elif [[ "$core" == "48" ]]; then
    sed -i '9s/.*/8/' HPL.dat
    sed -i '10s/.*/6/' HPL.dat
  fi
done
