#!/bin/bash

echo "Ryan's fancy script to scale HPL.dat on the fly"
create_hpl () {
cd $hplpathvar/..
hplfolder=$(ls | grep -i intel)
if [[ ! -d "$hplbinpathvar/$nodes" ]]; then
  mkdir $hplbinpathvar/$nodes
fi
if [[ ! -d "$hplbinpathvar/$nodes/$scale" ]]; then
  mkdir $hplbinpathvar/$nodes/$scale
fi
cp -r $hplfolder $hplbinpathvar/$nodes/$scale
cd $hplbinpathvar/$nodes/$scale
echo $(pwd)
echo $hplfolder $core
mv $hplfolder $core
cd $core
}
edit_hpldat () {
  corex=$1
  if [[ -n "$ns" ]]; then
    sed -i '6s/.*/'$ns'/' HPL.dat
  fi
  if [[ "$corex" == "1" ]]; then
    sed -i '11s/.*/1/' HPL.dat
    sed -i '12s/.*/1/' HPL.dat
  elif [[ "$corex" == "2" ]]; then
    sed -i '11s/.*/2/' HPL.dat
    sed -i '12s/.*/1/' HPL.dat
  elif [[ "$corex" == "4" ]]; then
    sed -i '11s/.*/2/' HPL.dat
    sed -i '12s/.*/2/' HPL.dat
  elif [[ "$corex" == "6" ]]; then
    sed -i '11s/.*/3/' HPL.dat
    sed -i '12s/.*/2/' HPL.dat
  elif [[ "$corex" == "12" ]]; then
    sed -i '11s/.*/4/' HPL.dat
    sed -i '12s/.*/3/' HPL.dat
  elif [[ "$corex" == "24" ]]; then
    sed -i '11s/.*/6/' HPL.dat
    sed -i '12s/.*/4/' HPL.dat
  elif [[ "$corex" == "36" ]]; then
    sed -i '11s/.*/6/' HPL.dat
    sed -i '12s/.*/6/' HPL.dat
  elif [[ "$corex" == "48" ]]; then
    sed -i '11s/.*/6/' HPL.dat
    sed -i '12s/.*/8/' HPL.dat
  fi
}
create_sjob () {
  cd $hplbinpathvar
  if [[ ! -d "scripts" ]]; then
    mkdir scripts
  fi
  if [[ ! -d "scripts/$nodes" ]]; then
    mkdir scripts/$nodes
  fi
  if [[ ! -d "scripts/$nodes/$scale" ]]; then
    mkdir scripts/$nodes/$scale
  fi
  if [[ ! -d "results" ]]; then
    mkdir results
  fi
  if [[ ! -d "results/$nodes" ]]; then
    mkdir results/$nodes
  fi
  if [[ ! -d "results/$nodes/$scale" ]]; then
    mkdir results/$nodes/$scale
  fi
  cd scripts/$nodes/$scale
  touch hpl-$core.sjob
  echo -e "#!/bin/bash\n#SBATCH -p pinnacle\n#SBATCH -t 12:00\n#SBATCH -N$1 -n$core\n#SBATCH --profile=all" >> hpl-$core.sjob
  echo "#SBATCH -o $hplbinpathvar/results/$nodes/$scale/hpl-$core-'$SLURM_JOB_ID'.out" >> hpl-$core.sjob
  echo "export MODULEPATH=$MODULEPATH:/soft/modules" >> hpl-$core.sjob
  echo -e "module load compilers/intel\nmodule load blas/intel-mkl\nmodule load mpi/intel"  >> hpl-$core.sjob
  echo "cd $hplbinpathvar/$nodes/$scale/$core"  >> hpl-$core.sjob
  echo "export I_MPI_PMI_LIBRARY=/usr/lib64/libpmi.so" hpl-$core.sjob
  echo "mpirun -n $core ./xhpl"  >> hpl-$core.sjob
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

cd $hplbinpathvar
if [[ -d "scripts" ]]; then
  rm -rf scripts/$nodes
fi
if [[ -d "$nodes" ]]; then
  rm -rf $nodes
fi

if [[ "$nodes" == "single" ]]; then
  export cores='1 2 4 6 12 24 36 48'
for core in $cores; do
  create_hpl
  edit_hpldat $core
done
for core in $cores; do
 create_sjob 1
done
fi
