#!/bin/bash#
#Check if filename provided

#Create recycle bin directory
if [ ! -d "$HOME/recyclebin" ]
then
        mkdir $HOME/recyclebin
fi

#Create hidden file .restore.info in $HOME
if [ ! -f  "$HOME/.restore.info" ]
then
        touch $HOME/.restore.info
fi


#Check if filename provided
if [ $# == 0 ]
then
        echo "No filename provided"
        exit 2
fi

interactive=false
verbose=false
remove=false
while getopts ivr option
do
        case $option in
                i) interactive=true ;;
                v) verbose=true ;;
                r) remove=true ;;
                \?) echo "$0: invalid option -- 'OPTARG'"
                        echo "Usage: sh $0 -i|-v int1 int2"
                        exit 1
        esac
done
shift $((OPTIND -1))
echo $*

function del_file(){
        #Checking if file exists, otherwise exit
        if [ ! -e "$1" ]
        then
                echo "File does not exist"
                exit 1
        #Checking if name provided is directory, if so exit
        elif [ -d "$1" ]
        then
                echo "Directory name provided"
                exit 3
        #Checks if this is a file, if not exit
        elif [ ! -f "$1" ]
        then
                echo "Not a file"
                exit 4
        fi

        #Checks if the file being deleted is the recycle script, if it is then abort
        if [[ "$1" == "./recycle" || "$1" == "recycle" || "$1" == $PWD/recycle ]]
        then
                echo "Attempting to delete recycle - operation aborted"
                exit 5
        fi

        stored_filename=$(ls -i $1)
        inode=$(echo "$stored_filename" | cut -d " " -f1 )
        filename=$(echo "$stored_filename" | cut -d " " -f2 | rev | cut -d"/" -f1 | rev)
        pathname=$(realpath "$1")
        #been_removed is flagged to check if file has been removed
        been_removed=false
        #Checking if -i option has been used
        if [ $interactive == true ]
        then
                echo "Are you sure you want to remove $filename?"
                read answer
                if [[ "$answer" == [Yy]* ]]
                then
                        echo "${filename}_${inode}/:$pathname" >> $HOME/.restore.info
                        mv $1 "$HOME/recyclebin/${filename}_${inode}"
                        been_removed=true
                fi
        else
                echo "${filename}_${inode}/:$pathname" >> $HOME/.restore.info
                mv $arg "$HOME/recyclebin/${filename}_${inode}"
                been_removed=true
        fi
        #Checking if -v option has been used
        if [ $verbose == true ]
        then
                if [ $been_removed == true ]
                then
                        echo "File: $filename has been removed"
                else
                        echo "File: $filename has not been removed"
                fi
        fi
}

#Function to recursively delete directory
function del_recursive(){
        #Listing files with fullpath in directory
        files=$(ls -d "$1/"*)
        for i in $files
        do
                if [ -f $i ]
                then
                        del_file $i
                elif [ -d $i ]
                then
                        del_recursive $i
                        #Deleting the directories and subdirectories named
                        rm -r $i
                fi
        done
}

#Checking if -r option has been used
if [ $remove == true ];
then
        #For unlimited number of arguments
        for arg in "$@"
        do
                #Will use del_recursive function if -r option is used, by assuming arguments are directories in the current working directory
                del_recursive $(readlink -f $arg)
        done
else
        for arg in $@
        do
                #Search for wild card character in string
                if grep -q "\\*" <<< $arg
                then
                        #This variable will list all filenames associated with a wildcard
                        file_name=$(ls $arg)
                        for i in file_name
                        do
                                #Checking if argument is not a directory and is a file
                                if [[ ! -d $i && -f $i ]]
                                then
                                        #If it is a file, it will use del_file function to delete the file
                                        del_file $i
                                fi
                        done
                else
                        #If there is no wildcard in the argument, the file will be deleted after going through the del_file function
                        del_file $arg
                fi
        done
fi
