#!/usr/bin/env bash
# Default values
node="node01"
queue="short"
ppn="24"
name="ReservePBSNode"

# Handle SIGINT (Ctrl+C) to clean up the PBS script
trap "echo 'Cleaning up...'; rm -f reserve_$name.pbs; exit 0" INT

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -n|--node)  node="$2";  shift ;;
    -q|--queue) queue="$2"; shift ;;
    -p|--ppn)   ppn="$2";   shift ;;
    -N|--name)  name="$2";  shift ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

# Write a PBS script to run a job on the specified node
cat << EOF > reserve_$name.pbs
#!/usr/bin/env bash
#PBS -N $name
#PBS -l select=1:ncpus=$ppn:host=$node
#PBS -l walltime=00:30:00
#PBS -q $queue
#PBS -j oe
# Change to the directory from which the job was submitted
cd \$PBS_O_WORKDIR
# Run a simple command to keep the job active
sleep 30m
EOF
chmod +x reserve_$name.pbs

while true; do
  echo "Current cluster nodes status:"
  pbsnodes -aSj
  echo ""
  # Submit the job to the cluster
  job=$(qsub reserve_$name.pbs)
  echo "Submitted job $job"
  echo ""
  echo "Current job status for user $USER:"
  qstat -u $USER
  echo ""
  echo "Tracing job $job:"
  tracejob $job
  echo ""
  echo "Info for node $node:"
  pbsnodes $node
  echo ""
  echo "Sleeping for 30 minutes before checking again..."
  sleep 30m
  echo ""
  echo ""
done
