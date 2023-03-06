#!/bin/bash

#If there is no argument provided, this will echo "no filename provided"
if [ $# == 0 ]
then
        echo "No filename provided"
        exit 1
#If the filename provided is not a file, then it will echo "file supplied does not exist"
elif [ ! -f "$HOME/recyclebin/$1" ]
then
        echo "File supplied does not exist"
        exit 2
fi

stored_filename=$(ls $HOME/recyclebin/$1)
filename=$(echo "$stored_filename" | cut -d "_" -f1)
inode=$(echo "$stored_filename" | cut -d "_" -f2)
path_name=""

#Gets rid of newline character at the end
while read -r line
do
        #If you can find the filename in the line
        if grep -q "$1" <<< "$line"
        then
                path_name=$(echo "$line" | cut -d ":" -f2)
                break
        fi
done < $HOME/.restore.info

#Checking to see whether filename provided already exists in return directory
if [ -f $path_name ]
then
        echo "Do you want to overwrite? y/n"
        read answer
        if [[ "$answer"  == [Yy]* ]]
        then
                mv "$HOME/recyclebin/$1" "$path_name"
        fi
else
        mv "$HOME/recyclebin/$1" "$path_name"
fi

#Create temp file to store values of .restore.info whilst deleting
touch temp
while read -r line
do
        #If you cannot find the filename in the line, append the line to temp
        if !(grep -q "$1" <<< "$line")
        then
                echo $line >> temp
        fi
done < $HOME/.restore.info
#Deleting .restore.info file because it needs to be updated
rm $HOME/.restore.info
#Moved all new data to a new .restore.info file
mv "temp" $HOME/.restore.info
