#!/bin/bash
mkdir dataS_lua
mkdir dataS_lua/missions
mkdir dataS_lua/scripts
mkdir dataS_lua/scripts/ai
mkdir dataS_lua/scripts/ai/animals
mkdir dataS_lua/scripts/ai/animals/actions
mkdir dataS_lua/scripts/ai/animals/animation
mkdir dataS_lua/scripts/ai/animals/perception
mkdir dataS_lua/scripts/ai/animals/states
mkdir dataS_lua/scripts/ai/animals/states/test
mkdir dataS_lua/scripts/ai/animals/steeringBehaviors
mkdir dataS_lua/scripts/ai/animals/world
mkdir dataS_lua/scripts/ai/common
mkdir dataS_lua/scripts/ai/common/stateMachine
mkdir dataS_lua/scripts/ai/common/jobQueue
mkdir dataS_lua/scripts/gui
mkdir dataS_lua/scripts/gui/elements
mkdir dataS_lua/scripts/network
mkdir dataS_lua/scripts/objects
mkdir dataS_lua/scripts/shared
mkdir dataS_lua/scripts/sounds
mkdir dataS_lua/scripts/triggers
mkdir dataS_lua/scripts/player
mkdir dataS_lua/scripts/environment
mkdir dataS_lua/scripts/vehicles
mkdir dataS_lua/scripts/vehicles/specializations

for i in $(find dataS -name '*.luc')
do
	echo "original file =" ${i}
    file_start=${i/dataS/dataS_lua} 
    file_end=${file_start/%.*/.lua}
    echo "end file =" ${file_end}
    java -jar unluac.jar ${i} > ${file_end}
    echo "------------------"
done
    
   