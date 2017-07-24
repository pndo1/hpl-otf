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
mv $hplfolder $nodes/$scale
cd $hplfolder $nodes/$scale
mv $hplfolder $core
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
for core in $cores; do
 cd $hplbinpathvar
 touch hpl-$nodes-$scale-$core.sjob
 echo -e "#!/bin/bash\n#SBATCH -p pinnacle\n#SBATCH -t 12:00\n#SBATCH -N1 -n$core\n#SBATCH --profile=all" >> hpl-$nodes-$scale-$core.sjob
 echo "export MODULEPATH=$MODULEPATH:/soft/modules" >> hpl-$nodes-$scale-$core.sjob
 echo -e "module load compilers/intel\nmodule load blas/intel-mkl\nmodule load mpi/intel"
 echo "cd $hplbinpathvar/$nodes/$scale/$core"
 mpirun -n $core ./xhpl
done
fi
