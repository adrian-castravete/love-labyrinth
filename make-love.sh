#!/bin/bash

zip -9r labyrinth.`date +%Y%m%d%H%M`.love . -x*.swp -xage-project/* -xconcept/* -xolder-unused/* -x.git* -x*.love
