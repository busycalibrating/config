function jptnode --description "Forwards port $1 from node $2 into port $1 on the local machine and listens to it"
    echo "ssh -t -t mila -L $argv[1]:localhost:$argv[1] ssh david-a.dobre@$argv[2] -L $argv[1]:localhost:$argv[1]"
    ssh -t -t mila -L $argv[1]:localhost:$argv[1] ssh david-a.dobre@$argv[2] -L $argv[1]:localhost:$argv[1]
end
