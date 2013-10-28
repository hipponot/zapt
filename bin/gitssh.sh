#!/usr/bin/env sh
ssh -o "StrictHostKeyChecking no" -i $HOME/.ssh/id_rsa $1 $2
