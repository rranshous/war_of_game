POP = $1
GENS = $2
RUN_NAME = $3

$container_name

$cid=$(docker run --rm -m 64g -d --name $container_name rranshous/wog_ga $POP $GENS)

